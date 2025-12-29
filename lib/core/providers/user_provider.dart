import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUser => _currentUser != null;

  UserRole? get role => _currentUser?.role;
  String? get userId => _currentUser?.id;
  String? get clinicId => _currentUser?.clinicId;

  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual profile update with backend
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
        updatedAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar perfil: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual user data refresh from backend
      await Future.delayed(const Duration(milliseconds: 300));

      // For now, just update the timestamp
      _currentUser = _currentUser!.copyWith(
        updatedAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
