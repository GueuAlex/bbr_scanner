import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user.dart';
import '../../data/models/user_model.dart';

/// Résultat d'authentification
class AuthResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) {
    return AuthResult(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, errorMessage: message);
  }
}

/// Service d'authentification
class AuthService {
  final SecureStorageService _secureStorage;
  final UserRepository _userRepository;
  final Dio _dio;
  final _logger = Logger();

  AuthService(this._secureStorage, this._userRepository)
    : _dio = Dio(
        BaseOptions(
          baseUrl:
              dotenv.env['ENV_BASE_URL'] ?? 'https://api.bbr-demo.com/api/v1',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  /// Connexion avec email et mot de passe
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting login for: $email');

      // Mode demo: vérifier si on est en mode sandbox
      final buildMode = dotenv.env['ENV_BUILD_MODE'] ?? 'demo';
      if (buildMode == 'demo') {
        return _demoLogin(email, password);
      }

      // Login réel via API
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        final user = UserModel.fromJson(userData).toEntity();

        // Sauvegarder les tokens
        await _secureStorage.saveAccessToken(accessToken);
        await _secureStorage.saveRefreshToken(refreshToken);
        await _secureStorage.saveUserId(user.id);
        await _secureStorage.saveUserEmail(user.email);

        // Sauvegarder l'utilisateur en base locale
        await _userRepository.saveUser(user);

        _logger.i('Login successful for user: ${user.id}');

        return AuthResult.success(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );
      } else {
        _logger.w('Login failed with status: ${response.statusCode}');
        return AuthResult.failure('Échec de connexion');
      }
    } on DioException catch (e) {
      _logger.e('Login DioException: ${e.message}');
      return _handleDioError(e);
    } catch (e, stack) {
      _logger.e('Login error: $e', error: e, stackTrace: stack);
      return AuthResult.failure('Erreur de connexion: $e');
    }
  }

  /// Login en mode demo (sandbox)
  Future<AuthResult> _demoLogin(String email, String password) async {
    _logger.w('Demo mode: simulating login');

    // Accepter n'importe quel email/mot de passe pour la démo
    await Future.delayed(const Duration(milliseconds: 500));

    final user = User(
      id: 'demo-agent-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Agent Demo',
      email: email,
      role: 'AGENT',
    );

    final demoAccessToken =
        'demo_access_token_${DateTime.now().millisecondsSinceEpoch}';
    const demoRefreshToken = 'demo_refresh_token';

    // Sauvegarder les tokens demo
    await _secureStorage.saveAccessToken(demoAccessToken);
    await _secureStorage.saveRefreshToken(demoRefreshToken);
    await _secureStorage.saveUserId(user.id);
    await _secureStorage.saveUserEmail(user.email);

    // Sauvegarder l'utilisateur en base locale
    await _userRepository.saveUser(user);

    _logger.i('Demo login successful');

    return AuthResult.success(
      accessToken: demoAccessToken,
      refreshToken: demoRefreshToken,
      user: user,
    );
  }

  /// Rafraîchit le token d'accès
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        _logger.w('No refresh token available');
        return null;
      }

      _logger.i('Refreshing access token');

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;

        await _secureStorage.saveAccessToken(newAccessToken);

        _logger.i('Access token refreshed');
        return newAccessToken;
      }

      return null;
    } on DioException catch (e) {
      _logger.e('Token refresh failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Error refreshing token: $e');
      return null;
    }
  }

  /// Vérifie si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAccessToken();
    final user = await _userRepository.getUser();
    return token != null && user != null;
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      _logger.i('Logging out');

      await _secureStorage.deleteTokens();
      await _userRepository.deleteUser();

      _logger.i('Logout successful');
    } catch (e, stack) {
      _logger.e('Error during logout: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Gestion des erreurs Dio
  AuthResult _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 401:
          return AuthResult.failure('Email ou mot de passe incorrect');
        case 403:
          return AuthResult.failure('Accès refusé');
        case 429:
          return AuthResult.failure(
            'Trop de tentatives. Veuillez réessayer plus tard',
          );
        default:
          return AuthResult.failure('Erreur serveur ($statusCode)');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthResult.failure('Timeout de connexion');
    }

    if (error.type == DioExceptionType.connectionError) {
      return AuthResult.failure('Erreur de connexion. Vérifiez votre réseau');
    }

    return AuthResult.failure('Erreur de connexion');
  }
}
