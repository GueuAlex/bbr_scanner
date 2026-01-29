import 'package:logger/logger.dart';
import '../../core/storage/database_service.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Repository pour la gestion de l'utilisateur
class UserRepository {
  final DatabaseService _databaseService;
  final _logger = Logger();

  UserRepository(this._databaseService);

  /// Sauvegarde l'utilisateur (un seul utilisateur par session)
  Future<void> saveUser(User user) async {
    try {
      final db = await _databaseService.database;
      final model = UserModel.fromEntity(user);

      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'user',
        {
          ...model.toJson(),
          'lastLoginAt': now,
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.i('User saved: ${user.id}');
    } catch (e, stack) {
      _logger.e('Error saving user: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère l'utilisateur actuel
  Future<User?> getUser() async {
    try {
      final db = await _databaseService.database;

      final maps = await db.query('user', limit: 1);

      if (maps.isEmpty) {
        _logger.d('No user found in database');
        return null;
      }

      return UserModel.fromJson(maps.first).toEntity();
    } catch (e, stack) {
      _logger.e('Error getting user: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Met à jour le timestamp de dernière connexion
  Future<void> updateLastLogin() async {
    try {
      final db = await _databaseService.database;

      await db.update(
        'user',
        {'lastLoginAt': DateTime.now().millisecondsSinceEpoch},
      );

      _logger.d('User last login updated');
    } catch (e, stack) {
      _logger.e('Error updating last login: $e', error: e, stackTrace: stack);
    }
  }

  /// Supprime l'utilisateur
  Future<void> deleteUser() async {
    try {
      final db = await _databaseService.database;
      await db.delete('user');
      _logger.i('User deleted');
    } catch (e, stack) {
      _logger.e('Error deleting user: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
