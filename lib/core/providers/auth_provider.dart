import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _token;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;

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

      // Log detalhado para debug
      debugPrint('🔴 Login Error:');
      debugPrint('   Type: ${e.type}');
      debugPrint('   URL: ${e.requestOptions.uri}');
      debugPrint('   Message: ${e.message}');

      if (e.response?.statusCode == 401) {
        _errorMessage = 'Email ou senha incorretos';
      } else if (e.response?.statusCode == 400) {
        _errorMessage = 'Dados inválidos';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        _errorMessage = 'Tempo de conexão esgotado. Verifique sua internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        _errorMessage = 'Servidor indisponível. Verifique se o backend está rodando.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = 'Servidor demorou para responder. Tente novamente.';
      } else {
        _errorMessage = 'Erro ao fazer login. Tente novamente.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado: ${e.toString()}';
      debugPrint('🔴 Unexpected Login Error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Logout do usuário
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _apiService.removeToken();
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
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

      if (e.response?.statusCode == 409) {
        _errorMessage = 'Este email já está em uso';
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          _errorMessage = data['message'] is List
              ? (data['message'] as List).first
              : data['message'].toString();
        } else {
          _errorMessage = 'Dados inválidos';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        _errorMessage = 'Não foi possível conectar ao servidor';
      } else {
        _errorMessage = 'Erro ao criar conta. Tente novamente.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro inesperado: ${e.toString()}';
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
