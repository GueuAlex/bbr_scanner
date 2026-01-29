import 'package:logger/logger.dart';
import '../../core/storage/database_service.dart';
import '../../domain/entities/scan_event.dart';
import '../models/scan_event_model.dart';

/// Repository pour la gestion des événements de scan
class ScanRepository {
  final DatabaseService _databaseService;
  final _logger = Logger();

  ScanRepository(this._databaseService);

  /// Sauvegarde un événement de scan
  Future<void> saveScanEvent(ScanEvent event) async {
    try {
      final db = await _databaseService.database;
      final model = ScanEventModel.fromEntity(event);

      await db.insert(
        'scan_events',
        {
          ...model.toMap(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.i('Scan event saved: ${event.id}');
    } catch (e, stack) {
      _logger.e('Error saving scan event: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère tous les scans non synchronisés
  Future<List<ScanEvent>> getUnsyncedScans() async {
    try {
      final db = await _databaseService.database;

      final maps = await db.query(
        'scan_events',
        where: 'syncedAt IS NULL',
        orderBy: 'timestamp ASC',
      );

      _logger.d('Found ${maps.length} unsynced scans');

      return maps.map((map) => ScanEventModel.fromMap(map).toEntity()).toList();
    } catch (e, stack) {
      _logger.e('Error getting unsynced scans: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Marque un scan comme synchronisé
  Future<void> markAsSynced(String scanId) async {
    try {
      final db = await _databaseService.database;

      await db.update(
        'scan_events',
        {'syncedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [scanId],
      );

      _logger.d('Scan marked as synced: $scanId');
    } catch (e, stack) {
      _logger.e('Error marking scan as synced: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère l'historique des scans (paginé)
  Future<List<ScanEvent>> getScans({
    int limit = 50,
    int offset = 0,
    String? ticketId,
  }) async {
    try {
      final db = await _databaseService.database;

      String? where;
      List<dynamic>? whereArgs;

      if (ticketId != null) {
        where = 'ticketId = ?';
        whereArgs = [ticketId];
      }

      final maps = await db.query(
        'scan_events',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      _logger.d('Retrieved ${maps.length} scans (limit: $limit, offset: $offset)');

      return maps.map((map) => ScanEventModel.fromMap(map).toEntity()).toList();
    } catch (e, stack) {
      _logger.e('Error getting scans: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Compte le nombre total de scans
  Future<int> countScans({String? ticketId}) async {
    try {
      final db = await _databaseService.database;

      String? where;
      List<dynamic>? whereArgs;

      if (ticketId != null) {
        where = 'ticketId = ?';
        whereArgs = [ticketId];
      }

      final result = await db.query(
        'scan_events',
        columns: ['COUNT(*) as count'],
        where: where,
        whereArgs: whereArgs,
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, stack) {
      _logger.e('Error counting scans: $e', error: e, stackTrace: stack);
      return 0;
    }
  }

  /// Récupère le dernier scan pour un ticket donné
  Future<ScanEvent?> getLastScanForTicket(String ticketId) async {
    try {
      final db = await _databaseService.database;

      final maps = await db.query(
        'scan_events',
        where: 'ticketId = ?',
        whereArgs: [ticketId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return ScanEventModel.fromMap(maps.first).toEntity();
    } catch (e, stack) {
      _logger.e('Error getting last scan for ticket: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Supprime tous les scans
  Future<void> deleteAllScans() async {
    try {
      final db = await _databaseService.database;
      await db.delete('scan_events');
      _logger.w('All scans deleted');
    } catch (e, stack) {
      _logger.e('Error deleting all scans: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
