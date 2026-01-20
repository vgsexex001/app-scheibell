import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro para tokens de autenticação
/// Usa Keychain no iOS e EncryptedSharedPreferences no Android
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  late final FlutterSecureStorage _storage;

  // Chaves de armazenamento
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresAtKey = 'token_expires_at';
  static const String _userIdKey = 'user_id';
  static const String _patientIdKey = 'patient_id';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  SecureStorageService._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // ==================== Access Token ====================

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  // ==================== Refresh Token ====================

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // ==================== Token Expiration ====================

  Future<void> saveTokenExpiresAt(DateTime expiresAt) async {
    await _storage.write(
      key: _tokenExpiresAtKey,
      value: expiresAt.toIso8601String(),
    );
  }

  Future<DateTime?> getTokenExpiresAt() async {
    final value = await _storage.read(key: _tokenExpiresAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> deleteTokenExpiresAt() async {
    await _storage.delete(key: _tokenExpiresAtKey);
  }

  // ==================== User ID ====================

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // ==================== Patient ID ====================

  Future<void> savePatientId(String patientId) async {
    await _storage.write(key: _patientIdKey, value: patientId);
  }

  Future<String?> getPatientId() async {
    return await _storage.read(key: _patientIdKey);
  }

  // ==================== Utilidades ====================

  /// Verifica se o token está expirado (com margem de 1 minuto)
  Future<bool> isTokenExpired() async {
    final expiresAt = await getTokenExpiresAt();
    if (expiresAt == null) return true;

    // Considera expirado 1 minuto antes para dar margem
    final bufferTime = expiresAt.subtract(const Duration(minutes: 1));
    return DateTime.now().isAfter(bufferTime);
  }

  /// Verifica se há tokens salvos
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Limpa todos os dados de autenticação
  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      deleteTokenExpiresAt(),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _patientIdKey),
    ]);
  }

  /// Salva par de tokens completo
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    String? userId,
    String? patientId,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveTokenExpiresAt(expiresAt),
      if (userId != null) saveUserId(userId),
      if (patientId != null) savePatientId(patientId),
    ]);
  }

  /// Migra token do SharedPreferences antigo para SecureStorage
  /// Chamado uma vez durante o bootstrap do app
  Future<void> migrateFromSharedPreferences(String? oldToken) async {
    if (oldToken != null && oldToken.isNotEmpty) {
      final existingToken = await getAccessToken();
      if (existingToken == null || existingToken.isEmpty) {
        // Migra o token antigo
        await saveAccessToken(oldToken);
        // Nota: O refresh token não existia antes, será gerado no próximo login
      }
    }
  }

  // ==================== Onboarding ====================

  /// Verifica se o onboarding foi completado para o usuário atual
  Future<bool> isOnboardingCompleted() async {
    final userId = await getUserId();
    if (userId == null) {
      // Se não há usuário logado, verifica flag global (fallback)
      final value = await _storage.read(key: _onboardingCompletedKey);
      return value == 'true';
    }
    // Verifica flag específico do usuário
    final userKey = '${_onboardingCompletedKey}_$userId';
    final value = await _storage.read(key: userKey);
    return value == 'true';
  }

  /// Marca o onboarding como completado para o usuário atual
  Future<void> setOnboardingCompleted() async {
    final userId = await getUserId();
    if (userId != null) {
      // Salva flag específico do usuário
      final userKey = '${_onboardingCompletedKey}_$userId';
      await _storage.write(key: userKey, value: 'true');
    }
    // Também salva flag global como fallback
    await _storage.write(key: _onboardingCompletedKey, value: 'true');
  }

  /// Reseta o estado do onboarding (para testes)
  Future<void> resetOnboarding() async {
    final userId = await getUserId();
    if (userId != null) {
      final userKey = '${_onboardingCompletedKey}_$userId';
      await _storage.delete(key: userKey);
    }
    await _storage.delete(key: _onboardingCompletedKey);
  }
}
