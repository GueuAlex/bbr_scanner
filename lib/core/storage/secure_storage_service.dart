import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

/// Service de stockage sécurisé pour les tokens et données sensibles
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final _logger = Logger();

  // === Tokens ===

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: AppConstants.keyAccessToken, value: token);
      _logger.d('Access token saved');
    } catch (e) {
      _logger.e('Error saving access token: $e');
      rethrow;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.keyAccessToken);
    } catch (e) {
      _logger.e('Error reading access token: $e');
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.keyRefreshToken, value: token);
      _logger.d('Refresh token saved');
    } catch (e) {
      _logger.e('Error saving refresh token: $e');
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.keyRefreshToken);
    } catch (e) {
      _logger.e('Error reading refresh token: $e');
      return null;
    }
  }

  // === User Info ===

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: AppConstants.keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.keyUserId);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: AppConstants.keyUserEmail, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: AppConstants.keyUserEmail);
  }

  // === Clear All ===

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _logger.i('All secure storage cleared');
    } catch (e) {
      _logger.e('Error clearing secure storage: $e');
      rethrow;
    }
  }

  Future<void> deleteTokens() async {
    try {
      await _storage.delete(key: AppConstants.keyAccessToken);
      await _storage.delete(key: AppConstants.keyRefreshToken);
      _logger.i('Tokens cleared');
    } catch (e) {
      _logger.e('Error clearing tokens: $e');
      rethrow;
    }
  }
}
