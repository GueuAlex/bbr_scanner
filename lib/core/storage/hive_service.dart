import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../../data/models/user_model.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/scan_event_model.dart';
import '../constants/app_constants.dart';

/// Service de gestion Hive (NoSQL local)
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  final _logger = Logger();

  // Noms des boxes
  static const String userBox = 'user_box';
  static const String ticketsBox = 'tickets_box';
  static const String scansBox = 'scans_box';
  static const String configBox = 'config_box';

  bool _isInitialized = false;

  /// Initialise Hive et enregistre les adapters
  Future<void> init() async {
    if (_isInitialized) {
      _logger.d('Hive already initialized');
      return;
    }

    try {
      _logger.i('Initializing Hive...');

      // Initialiser Hive avec Flutter
      await Hive.initFlutter();

      // Enregistrer les TypeAdapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TicketModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ScanEventModelAdapter());
      }

      // Ouvrir les boxes
      await Hive.openBox<UserModel>(userBox);
      await Hive.openBox<TicketModel>(ticketsBox);
      await Hive.openBox<ScanEventModel>(scansBox);
      await Hive.openBox(configBox);

      _isInitialized = true;
      _logger.i('Hive initialized successfully');
    } catch (e, stack) {
      _logger.e('Error initializing Hive: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère la box user
  Box<UserModel> getUserBox() {
    if (!_isInitialized) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return Hive.box<UserModel>(userBox);
  }

  /// Récupère la box tickets
  Box<TicketModel> getTicketsBox() {
    if (!_isInitialized) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return Hive.box<TicketModel>(ticketsBox);
  }

  /// Récupère la box scans
  Box<ScanEventModel> getScansBox() {
    if (!_isInitialized) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return Hive.box<ScanEventModel>(scansBox);
  }

  /// Récupère la box config
  Box getConfigBox() {
    if (!_isInitialized) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return Hive.box(configBox);
  }

  /// Nettoie les anciens scans (> retention days)
  Future<int> cleanOldScans() async {
    try {
      final box = getScansBox();
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: AppConstants.historyRetentionDays));

      int count = 0;
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final scan = box.get(key);
        if (scan != null &&
            scan.timestamp.isBefore(cutoffDate) &&
            scan.syncedAt != null) {
          keysToDelete.add(key);
          count++;
        }
      }

      await box.deleteAll(keysToDelete);

      _logger.i('Cleaned $count old scan events');
      return count;
    } catch (e, stack) {
      _logger.e('Error cleaning old scans: $e', error: e, stackTrace: stack);
      return 0;
    }
  }

  /// Supprime toutes les données
  Future<void> clearAll() async {
    try {
      await getUserBox().clear();
      await getTicketsBox().clear();
      await getScansBox().clear();
      await getConfigBox().clear();
      _logger.w('All Hive boxes cleared');
    } catch (e, stack) {
      _logger.e('Error clearing Hive: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Ferme toutes les boxes
  Future<void> close() async {
    try {
      await Hive.close();
      _isInitialized = false;
      _logger.i('Hive closed');
    } catch (e, stack) {
      _logger.e('Error closing Hive: $e', error: e, stackTrace: stack);
    }
  }

  /// Supprime complètement Hive (pour debug)
  Future<void> deleteFromDisk() async {
    try {
      await close();
      await Hive.deleteFromDisk();
      _logger.w('Hive deleted from disk');
    } catch (e, stack) {
      _logger.e('Error deleting Hive: $e', error: e, stackTrace: stack);
    }
  }
}
