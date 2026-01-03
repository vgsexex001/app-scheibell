import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  loggingOut,  // Estado intermediário durante logout
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

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

  /// Verifica se há um token salvo e tenta validar
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Tenta carregar token salvo
      final savedToken = await _apiService.loadSavedToken();

      if (savedToken == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _token = null;
        notifyListeners();
        return;
      }

      // Valida o token com o backend
      final response = await _apiService.validateToken();

      if (response['valid'] == true && response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
        _token = savedToken;
        _status = AuthStatus.authenticated;
      } else {
        await _apiService.removeToken();
        _status = AuthStatus.unauthenticated;
        _user = null;
        _token = null;
      }
    } catch (e) {
      // Token inválido ou expirado
      await _apiService.removeToken();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
    }

    notifyListeners();
  }

  /// Login do usuário
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      // Extrai dados da resposta
      _token = response['accessToken'];
      _user = UserModel.fromJson(response['user']);

      // Salva token para persistência
      if (_token != null) {
        await _apiService.saveToken(_token!);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _status = AuthStatus.error;

      // Usa o mapeamento centralizado de erros
      final apiError = _apiService.mapDioError(e);

      // Mensagem específica para login
      if (apiError.statusCode == 401) {
        _errorMessage = 'Email ou senha incorretos';
      } else {
        _errorMessage = apiError.message;
      }

      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado. Tente novamente.';
      debugPrint('🔴 Unexpected Login Error: $e');
      notifyListeners();
      return false;
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

  /// Registro de novo usuário
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.patient,
    String? clinicId,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        role: role.name.toUpperCase(),
        clinicId: clinicId,
      );

      // Extrai dados da resposta
      _token = response['accessToken'];
      _user = UserModel.fromJson(response['user']);

      // Salva token para persistência
      if (_token != null) {
        await _apiService.saveToken(_token!);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _status = AuthStatus.error;

      // Usa o mapeamento centralizado de erros
      final apiError = _apiService.mapDioError(e);

      // Mensagem específica para registro
      if (apiError.statusCode == 409) {
        _errorMessage = 'Este email já está em uso';
      } else {
        _errorMessage = apiError.message;
      }

      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado. Tente novamente.';
      debugPrint('🔴 Unexpected Register Error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Limpa mensagem de erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Atualiza os dados do perfil do usuário
  Future<void> refreshProfile() async {
    try {
      final response = await _apiService.getProfile();
      _user = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      // Silently fail - user data will remain unchanged
    }
  }

  /// Para testes - define usuário diretamente
  void setUserForTesting(UserModel user) {
    _user = user;
    _status = AuthStatus.authenticated;
    _token = 'test_token';
    notifyListeners();
  }
}
