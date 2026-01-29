import 'package:logger/logger.dart';
import '../../core/storage/hive_service.dart';
import '../../domain/entities/scan_event.dart';
import '../models/scan_event_model.dart';

/// Repository pour la gestion des événements de scan avec Hive
class ScanRepository {
  final HiveService _hiveService;
  final _logger = Logger();

  ScanRepository(this._hiveService);

  /// Sauvegarde un événement de scan
  Future<void> saveScanEvent(ScanEvent event) async {
    try {
      final box = _hiveService.getScansBox();
      final model = ScanEventModel.fromEntity(event);

      await box.put(event.id, model);

      _logger.i('Scan event saved: ${event.id}');
    } catch (e, stack) {
      _logger.e('Error saving scan event: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère tous les scans non synchronisés
  Future<List<ScanEvent>> getUnsyncedScans() async {
    try {
      final box = _hiveService.getScansBox();

      final unsynced = box.values
          .where((scan) => scan.syncedAt == null)
          .map((model) => model.toEntity())
          .toList();

      // Trier par timestamp ASC
      unsynced.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _logger.d('Found ${unsynced.length} unsynced scans');

      return unsynced;
    } catch (e, stack) {
      _logger.e('Error getting unsynced scans: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Marque un scan comme synchronisé
  Future<void> markAsSynced(String scanId) async {
    try {
      final box = _hiveService.getScansBox();
      final model = box.get(scanId);

      if (model != null) {
        final synced = model.copyWith(syncedAt: DateTime.now());
        await box.put(scanId, synced);

        _logger.d('Scan marked as synced: $scanId');
      }
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
      final box = _hiveService.getScansBox();
      var scans = box.values.map((model) => model.toEntity()).toList();

      // Filtrer par ticketId si fourni
      if (ticketId != null) {
        scans = scans.where((scan) => scan.ticketId == ticketId).toList();
      }

      // Trier par timestamp DESC
      scans.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _logger.d('Retrieved ${scans.length} scans (limit: $limit, offset: $offset)');

      // Pagination
      final start = offset;
      final end = (offset + limit).clamp(0, scans.length);

      if (start >= scans.length) {
        return [];
      }

      return scans.sublist(start, end);
    } catch (e, stack) {
      _logger.e('Error getting scans: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Compte le nombre total de scans
  Future<int> countScans({String? ticketId}) async {
    try {
      final box = _hiveService.getScansBox();

      if (ticketId != null) {
        return box.values.where((scan) => scan.ticketId == ticketId).length;
      }

      return box.length;
    } catch (e, stack) {
      _logger.e('Error counting scans: $e', error: e, stackTrace: stack);
      return 0;
    }
  }

  /// Récupère le dernier scan pour un ticket donné
  Future<ScanEvent?> getLastScanForTicket(String ticketId) async {
    try {
      final box = _hiveService.getScansBox();

      final ticketScans = box.values
          .where((scan) => scan.ticketId == ticketId)
          .map((model) => model.toEntity())
          .toList();

      if (ticketScans.isEmpty) return null;

      // Trier par timestamp DESC et prendre le premier
      ticketScans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return ticketScans.first;
    } catch (e, stack) {
      _logger.e('Error getting last scan for ticket: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Supprime tous les scans
  Future<void> deleteAllScans() async {
    try {
      final box = _hiveService.getScansBox();
      await box.clear();
      _logger.w('All scans deleted');
    } catch (e, stack) {
      _logger.e('Error deleting all scans: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
