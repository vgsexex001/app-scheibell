import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/secure_storage_service.dart';
import '../config/api_config.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  loggingOut,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  final SecureStorageService _secureStorage = SecureStorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _token;

  // Flag para evitar múltiplos logouts simultâneos (mutex)
  bool _isLoggingOut = false;

  // Chave global do Navigator para navegação centralizada
  static GlobalKey<NavigatorState>? navigatorKey;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isLoggingOut => _isLoggingOut;

  UserRole? get userRole => _user?.role;
  bool get isPatient => _user?.isPatient ?? false;
  bool get isClinicAdmin => _user?.isClinicAdmin ?? false;
  bool get isClinicStaff => _user?.isClinicStaff ?? false;
  bool get isThirdParty => _user?.isThirdParty ?? false;
  bool get isClinicMember => _user?.isClinicMember ?? false;

  /// Verifica se Supabase está disponível
  bool get _isSupabaseAvailable {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se há uma sessão ativa no Supabase
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      if (!_isSupabaseAvailable) {
        debugPrint('[AUTH] Supabase não disponível');
        _status = AuthStatus.unauthenticated;
        _user = null;
        _token = null;
        notifyListeners();
        return;
      }

      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;

      if (session != null && user != null) {
        debugPrint('[AUTH] Sessão Supabase encontrada: ${user.email}');

        _token = session.accessToken;

        // Salva o token para uso pelo ApiService
        await _apiService.saveToken(_token!);

        // Salva o userId no SecureStorage para identificar onboarding por usuário
        await _secureStorage.saveUserId(user.id);

        // Busca o role diretamente da tabela users pelo email
        await _fetchUserFromDatabase(user.id, user.email ?? '');

        _status = AuthStatus.authenticated;

        // Conectar WebSocket após validação bem-sucedida
        final wsBaseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
        _wsService.connect(wsBaseUrl, _token!);
        debugPrint('[AUTH] WebSocket conectado após validação');
      } else {
        debugPrint('[AUTH] Nenhuma sessão Supabase encontrada');
        await _apiService.removeToken();
        _status = AuthStatus.unauthenticated;
        _user = null;
        _token = null;
      }
    } catch (e) {
      debugPrint('[AUTH] Erro ao verificar sessão: $e');
      await _apiService.removeToken();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
    }

    notifyListeners();
  }

  /// Login do usuário via Supabase Auth
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final emailPreview = email.substring(0, min(3, email.length));
    debugPrint('[AUTH] login() iniciando para email: $emailPreview***');

    if (!_isSupabaseAvailable) {
      _status = AuthStatus.error;
      _errorMessage = 'Serviço de autenticação indisponível';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      debugPrint('[AUTH] Tentando login via Supabase Auth...');
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null || response.user == null) {
        _status = AuthStatus.error;
        _errorMessage = 'Email ou senha incorretos';
        notifyListeners();
        return false;
      }

      debugPrint('[AUTH] Login Supabase bem-sucedido!');
      debugPrint('[AUTH] Supabase user: ${response.user!.email}');

      // Usa o token JWT do Supabase
      _token = response.session!.accessToken;

      // Salva o token para uso pelo ApiService
      await _apiService.saveToken(_token!);

      // Salva o userId no SecureStorage para identificar onboarding por usuário
      await _secureStorage.saveUserId(response.user!.id);

      // Busca o role diretamente da tabela users pelo email
      await _fetchUserFromDatabase(response.user!.id, response.user!.email ?? email);

      _status = AuthStatus.authenticated;
      debugPrint('[AUTH] Login concluído - role: ${_user?.role}');

      // Conectar WebSocket após login bem-sucedido
      final wsBaseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
      _wsService.connect(wsBaseUrl, _token!);
      debugPrint('[AUTH] WebSocket conectado para: $wsBaseUrl');

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Supabase AuthException: ${e.message}');
      _status = AuthStatus.error;

      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('credentials')) {
        _errorMessage = 'Email ou senha incorretos';
      } else if (e.message.toLowerCase().contains('not confirmed')) {
        _errorMessage = 'Email não verificado. Verifique sua caixa de entrada.';
      } else {
        _errorMessage = 'Erro ao fazer login. Tente novamente.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AUTH] Erro inesperado no login: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Registro de novo usuário via Supabase Auth
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.patient,
    String? clinicId,
  }) async {
    if (!_isSupabaseAvailable) {
      _status = AuthStatus.error;
      _errorMessage = 'Serviço de autenticação indisponível';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      debugPrint('[AUTH] Tentando registro via Supabase Auth...');
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name.toUpperCase(),
          if (clinicId != null) 'clinicId': clinicId,
        },
      );

      if (response.user == null) {
        _status = AuthStatus.error;
        _errorMessage = 'Erro ao criar conta. Tente novamente.';
        notifyListeners();
        return false;
      }

      debugPrint('[AUTH] Registro Supabase bem-sucedido!');
      debugPrint('[AUTH] Supabase user: ${response.user!.email}');

      // Se o email precisa de confirmação, não autenticamos ainda
      if (response.session == null) {
        debugPrint('[AUTH] Email precisa de confirmação');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true; // Retorna true porque o registro foi bem-sucedido
      }

      // Se tiver sessão, já está autenticado
      final metadata = response.user!.userMetadata ?? {};

      _user = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        name: metadata['name'] as String? ?? name,
        role: _parseRole(metadata['role'] as String? ?? 'PATIENT'),
        clinicId: metadata['clinicId'] as String?,
        clinicName: metadata['clinicName'] as String?,
      );

      _token = response.session!.accessToken;
      await _apiService.saveToken(_token!);

      _status = AuthStatus.authenticated;
      debugPrint('[AUTH] Registro e login concluídos - role: ${_user?.role}');

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Supabase AuthException: ${e.message}');
      _status = AuthStatus.error;

      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        _errorMessage = 'Este email já está cadastrado';
      } else if (e.message.toLowerCase().contains('invalid email')) {
        _errorMessage = 'Email inválido';
      } else if (e.message.toLowerCase().contains('weak password') ||
                 e.message.toLowerCase().contains('password')) {
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres';
      } else {
        _errorMessage = 'Erro ao criar conta. Tente novamente.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AUTH] Erro inesperado no registro: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Login com Google via Supabase Auth
  Future<bool> signInWithGoogle() async {
    if (!_isSupabaseAvailable) {
      _status = AuthStatus.error;
      _errorMessage = 'Serviço de autenticação indisponível';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      // Inicia o fluxo OAuth com Google
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.appscheibell://login-callback',
      );

      if (!response) {
        _status = AuthStatus.error;
        _errorMessage = 'Não foi possível iniciar login com Google';
        notifyListeners();
        return false;
      }

      // O fluxo OAuth redireciona para o navegador
      // O callback será tratado pelo listener de auth state
      debugPrint('[AUTH] Google OAuth iniciado - aguardando callback');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Erro no login com Google: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao fazer login com Google. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Configura listener para mudanças de autenticação (usado para OAuth callbacks)
  void setupAuthListener() {
    if (!_isSupabaseAvailable) return;

    final supabase = Supabase.instance.client;

    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('[AUTH] Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        _handleOAuthCallback(session);
      }
    });
  }

  /// Processa callback de OAuth (Google, Magic Link, etc.)
  Future<void> _handleOAuthCallback(Session session) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('[AUTH] OAuth callback sem usuário');
        return;
      }

      debugPrint('[AUTH] OAuth callback - user: ${user.email}');

      _token = session.accessToken;
      await _apiService.saveToken(_token!);

      // Salva o userId no SecureStorage para identificar onboarding por usuário
      await _secureStorage.saveUserId(user.id);

      // Extrair metadados do Magic Link (se houver)
      final metadata = user.userMetadata ?? {};
      final name = metadata['name'] as String?;
      final clinicId = metadata['clinicId'] as String?;

      // Se veio de Magic Link, sincroniza com o backend para criar/vincular usuário
      // Isso é importante para pacientes pré-cadastrados pela clínica
      try {
        debugPrint('[AUTH] Sincronizando usuário Magic Link com backend...');
        final syncResult = await _apiService.syncMagicLink(
          authId: user.id,
          email: user.email ?? '',
          name: name,
          clinicId: clinicId,
        );
        debugPrint('[AUTH] Sincronização Magic Link: $syncResult');
      } catch (e) {
        // Se falhar a sincronização, ainda tenta buscar o usuário normalmente
        debugPrint('[AUTH] Erro ao sincronizar Magic Link (tentando fallback): $e');
      }

      // Busca o role diretamente da tabela users pelo email
      await _fetchUserFromDatabase(user.id, user.email ?? '');

      _status = AuthStatus.authenticated;
      debugPrint('[AUTH] OAuth/MagicLink login concluído - role: ${_user?.role}');

      notifyListeners();

      // Navega para gate que vai verificar onboarding e redirecionar corretamente
      if (navigatorKey?.currentState != null && _user != null) {
        navigatorKey!.currentState!.pushNamedAndRemoveUntil(
          '/gate',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[AUTH] Erro ao processar OAuth/MagicLink callback: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao completar login. Tente novamente.';
      notifyListeners();
    }
  }

  /// Busca dados do usuário diretamente da tabela users pelo authId (Supabase Auth ID)
  Future<void> _fetchUserFromDatabase(String authId, String email) async {
    try {
      final supabase = Supabase.instance.client;

      // Busca o usuário na tabela users pelo authId (vinculado ao auth.users do Supabase)
      // Query simplificada sem joins para evitar erros
      var response = await supabase
          .from('users')
          .select('id, name, email, role, clinicId')
          .eq('authId', authId)
          .maybeSingle();

      // Se não encontrou pelo authId, tenta pelo email (fallback para migração)
      if (response == null) {
        debugPrint('[AUTH] Usuário não encontrado por authId, tentando por email...');
        response = await supabase
            .from('users')
            .select('id, name, email, role, clinicId')
            .eq('email', email)
            .maybeSingle();

        // Se encontrou pelo email, atualiza o authId para vincular
        if (response != null) {
          debugPrint('[AUTH] Usuário encontrado por email, vinculando authId...');
          try {
            await supabase
                .from('users')
                .update({'authId': authId})
                .eq('id', response['id']);
          } catch (e) {
            debugPrint('[AUTH] Erro ao vincular authId (ignorado): $e');
          }
        }
      }

      if (response != null) {
        debugPrint('[AUTH] Usuário encontrado na tabela users: $response');

        final role = response['role'] as String? ?? 'PATIENT';
        final clinicId = response['clinicId'] as String?;

        // Busca nome da clínica separadamente (query opcional)
        String? clinicName;
        if (clinicId != null) {
          try {
            final clinicResponse = await supabase
                .from('clinics')
                .select('name')
                .eq('id', clinicId)
                .maybeSingle();
            clinicName = clinicResponse?['name'] as String?;
          } catch (e) {
            debugPrint('[AUTH] Erro ao buscar clínica (ignorado): $e');
          }
        }

        // Busca patientId separadamente (query opcional)
        String? patientId;
        try {
          final patientResponse = await supabase
              .from('patients')
              .select('id')
              .eq('userId', response['id'])
              .maybeSingle();
          patientId = patientResponse?['id'] as String?;
        } catch (e) {
          debugPrint('[AUTH] Erro ao buscar patient (ignorado): $e');
        }

        _user = UserModel(
          id: authId,
          email: response['email'] as String? ?? email,
          name: response['name'] as String? ?? email.split('@').first,
          role: _parseRole(role),
          clinicId: clinicId,
          clinicName: clinicName,
        );

        // Salvar patientId no SecureStorage se disponível
        if (patientId != null && patientId.isNotEmpty) {
          await _secureStorage.savePatientId(patientId);
          debugPrint('[AUTH] PatientId salvo: $patientId');
        }

        debugPrint('[AUTH] Role da tabela users: $role -> ${_user?.role}');
      } else {
        // Usuário não encontrado na tabela - usa fallback
        debugPrint('[AUTH] Usuário não encontrado na tabela users (nem por authId nem por email)');
        _user = UserModel(
          id: authId,
          email: email,
          name: email.split('@').first,
          role: UserRole.patient,
          clinicId: null,
          clinicName: null,
        );
      }
    } catch (e) {
      debugPrint('[AUTH] Erro ao buscar usuário na tabela users: $e');
      // Fallback: cria usuário básico como paciente
      _user = UserModel(
        id: authId,
        email: email,
        name: email.split('@').first,
        role: UserRole.patient,
        clinicId: null,
        clinicName: null,
      );
    }
  }

  /// Converte string de role para enum
  UserRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'CLINIC_ADMIN':
        return UserRole.clinicAdmin;
      case 'CLINIC_STAFF':
        return UserRole.clinicStaff;
      case 'THIRD_PARTY':
        return UserRole.thirdParty;
      case 'PATIENT':
      default:
        return UserRole.patient;
    }
  }

  /// Logout do usuário - idempotente e com navegação centralizada
  Future<void> logout() async {
    // Mutex: se já está deslogando, ignora chamadas duplicadas
    if (_isLoggingOut) {
      debugPrint('[AUTH] logout() ignorado - já em progresso');
      return;
    }

    _isLoggingOut = true;
    _status = AuthStatus.loggingOut;
    notifyListeners();

    debugPrint('[AUTH] logout() iniciado');

    try {
      // Desconectar WebSocket antes de remover token
      _wsService.disconnect();
      debugPrint('[AUTH] WebSocket desconectado');

      // Logout do Supabase
      if (_isSupabaseAvailable) {
        try {
          await Supabase.instance.client.auth.signOut();
          debugPrint('[AUTH] Supabase logout concluído');
        } catch (e) {
          debugPrint('[AUTH] Supabase logout erro (ignorado): $e');
        }
      }

      await _apiService.removeToken();
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      debugPrint('[AUTH] logout() concluído - status: unauthenticated');
    } catch (e) {
      debugPrint('[AUTH] logout() erro: $e');
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated; // Mesmo com erro, desloga
    } finally {
      _isLoggingOut = false;
      notifyListeners();

      // Navegação centralizada - única fonte de verdade
      _navigateToLogin();
    }
  }

  /// Navegação centralizada para login após logout
  void _navigateToLogin() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
      debugPrint('[AUTH] Navegou para login');
    } else {
      debugPrint('[AUTH] navigatorKey não configurado - navegação manual necessária');
    }
  }

  /// Limpa mensagem de erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Atualiza os dados do perfil do usuário
  Future<void> refreshProfile() async {
    if (!_isSupabaseAvailable) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Busca o role diretamente da tabela users pelo email
        await _fetchUserFromDatabase(user.id, user.email ?? '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AUTH] Erro ao atualizar perfil: $e');
    }
  }

  /// Para testes - define usuário diretamente
  void setUserForTesting(UserModel user) {
    _user = user;
    _status = AuthStatus.authenticated;
    _token = 'test_token';
    notifyListeners();
  }

  /// Conecta paciente usando código de pareamento (usa backend)
  /// Este método ainda usa o backend pois é uma funcionalidade específica do app
  Future<bool> connectWithCode(String code) async {
    _errorMessage = null;

    try {
      final response = await _apiService.connectWithCode(code);

      if (response['success'] == true) {
        // Recarrega o perfil para atualizar os dados do paciente
        await refreshProfile();
        return true;
      }

      _errorMessage = 'Falha ao conectar com o código informado';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao conectar. Tente novamente.';
      debugPrint('[AUTH] Erro ao conectar com código: $e');
      notifyListeners();
      return false;
    }
  }

  /// Verifica se o token está expirado
  Future<bool> isTokenExpired() async {
    if (!_isSupabaseAvailable) return true;

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      return session == null;
    } catch (e) {
      return true;
    }
  }
}
