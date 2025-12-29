import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
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

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // TODO: Implement actual auth check with backend/local storage
      // For now, simulate checking stored credentials
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulating no stored auth - user needs to login
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual login with backend
      await Future.delayed(const Duration(seconds: 1));

      // Simulated response - replace with actual API call
      // For demo, determine role based on email pattern
      UserRole role = UserRole.patient;
      if (email.contains('admin')) {
        role = UserRole.clinicAdmin;
      } else if (email.contains('staff')) {
        role = UserRole.clinicStaff;
      } else if (email.contains('terceiro') || email.contains('third')) {
        role = UserRole.thirdParty;
      }

      _user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Staff',
        email: email,
        role: role,
        clinicId: role != UserRole.patient ? 'clinic_1' : null,
        createdAt: DateTime.now(),
      );
      _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao fazer login: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // TODO: Implement actual logout with backend/clear local storage
      await Future.delayed(const Duration(milliseconds: 300));

      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

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
      // TODO: Implement actual registration with backend
      await Future.delayed(const Duration(seconds: 1));

      _user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: role,
        clinicId: clinicId,
        createdAt: DateTime.now(),
      );
      _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao criar conta: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // For testing purposes - set user directly
  void setUserForTesting(UserModel user) {
    _user = user;
    _status = AuthStatus.authenticated;
    _token = 'test_token';
    notifyListeners();
  }
}
