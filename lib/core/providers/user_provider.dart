import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
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
      // Chama a API real para atualizar o perfil
      final response = await _apiService.updateProfile(
        name: name,
        phone: phone,
      );

      // Atualiza o modelo local com a resposta do backend
      _currentUser = _currentUser!.copyWith(
        name: response['name'] as String? ?? _currentUser!.name,
        phone: response['phone'] as String? ?? _currentUser!.phone,
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
      // Busca dados atualizados do perfil via API
      final response = await _apiService.getProfile();

      // Atualiza o modelo local com os dados do backend
      _currentUser = _currentUser!.copyWith(
        name: response['name'] as String? ?? _currentUser!.name,
        email: response['email'] as String? ?? _currentUser!.email,
        phone: response['patient']?['phone'] as String? ?? _currentUser!.phone,
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
