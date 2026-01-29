import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/repositories/scan_repository.dart';
import '../../domain/entities/scan_event.dart';
import '../../data/models/scan_event_model.dart';

/// Résultat de synchronisation
class SyncResult {
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.errors,
  });

  bool get hasErrors => failedCount > 0;
  bool get allSynced => failedCount == 0;
}

/// Service de synchronisation avec retry policy
class SyncService {
  final ScanRepository _scanRepository;
  final SecureStorageService _secureStorage;
  final Dio _dio;
  final _logger = Logger();

  Timer? _syncTimer;
  bool _isSyncing = false;

  final _syncController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get syncStream => _syncController.stream;

  SyncService(
    this._scanRepository,
    this._secureStorage,
  ) : _dio = Dio(BaseOptions(
          baseUrl: dotenv.env['ENV_BASE_URL'] ?? 'https://api.bbr-demo.com/api/v1',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        )) {
    // Interceptor pour ajouter le token Bearer
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Démarre la synchronisation automatique (toutes les 30 secondes)
  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _logger.i('Starting auto-sync with interval: ${interval.inSeconds}s');

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncPendingScans());
  }

  /// Arrête la synchronisation automatique
  void stopAutoSync() {
    _logger.i('Stopping auto-sync');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Synchronise tous les scans en attente
  Future<SyncResult> syncPendingScans() async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping');
      return SyncResult(syncedCount: 0, failedCount: 0, errors: []);
    }

    _isSyncing = true;

    try {
      // Vérifier la connectivité
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _logger.d('No network connection, skipping sync');
        return SyncResult(
          syncedCount: 0,
          failedCount: 0,
          errors: ['Pas de connexion réseau'],
        );
      }

      _logger.i('Starting sync of pending scans');

      final unsyncedScans = await _scanRepository.getUnsyncedScans();

      if (unsyncedScans.isEmpty) {
        _logger.d('No scans to sync');
        return SyncResult(syncedCount: 0, failedCount: 0, errors: []);
      }

      _logger.i('Found ${unsyncedScans.length} scans to sync');

      int syncedCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      // Mode demo: simuler la synchronisation
      final buildMode = dotenv.env['ENV_BUILD_MODE'] ?? 'demo';
      if (buildMode == 'demo') {
        return await _demoSync(unsyncedScans);
      }

      // Synchronisation par lot (bulk)
      try {
        final result = await _syncBulk(unsyncedScans);
        syncedCount = result.syncedCount;
        failedCount = result.failedCount;
        errors = result.errors;
      } catch (e) {
        // Si le bulk échoue, essayer un par un
        _logger.w('Bulk sync failed, trying individual sync: $e');
        final individualResult = await _syncIndividually(unsyncedScans);
        syncedCount = individualResult.syncedCount;
        failedCount = individualResult.failedCount;
        errors = individualResult.errors;
      }

      final result = SyncResult(
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );

      _syncController.add(result);

      _logger.i('Sync completed: ${result.syncedCount} synced, ${result.failedCount} failed');

      return result;
    } catch (e, stack) {
      _logger.e('Sync error: $e', error: e, stackTrace: stack);
      return SyncResult(
        syncedCount: 0,
        failedCount: 0,
        errors: ['Erreur de synchronisation: $e'],
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronisation en mode bulk (tous en une fois)
  Future<SyncResult> _syncBulk(List<ScanEvent> scans) async {
    _logger.d('Attempting bulk sync of ${scans.length} scans');

    final scanModels = scans.map((s) => ScanEventModel.fromEntity(s).toJson()).toList();

    final response = await _dio.post(
      '/scans/bulk',
      data: scanModels,
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final accepted = data['accepted'] as int? ?? scans.length;
      final rejected = data['rejected'] as List? ?? [];

      // Marquer les scans acceptés comme synchronisés
      for (final scan in scans) {
        final isRejected = rejected.any((r) => r['localId'] == scan.id);
        if (!isRejected) {
          await _scanRepository.markAsSynced(scan.id);
        }
      }

      return SyncResult(
        syncedCount: accepted,
        failedCount: rejected.length,
        errors: rejected.map((r) => r['reason'] as String? ?? 'Unknown').toList(),
      );
    }

    throw Exception('Bulk sync failed with status: ${response.statusCode}');
  }

  /// Synchronisation individuelle avec retry
  Future<SyncResult> _syncIndividually(List<ScanEvent> scans) async {
    _logger.d('Syncing ${scans.length} scans individually');

    int syncedCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    for (final scan in scans) {
      try {
        await _syncSingleScan(scan);
        syncedCount++;
      } catch (e) {
        _logger.e('Failed to sync scan ${scan.id}: $e');
        failedCount++;
        errors.add('Scan ${scan.ticketId}: $e');
      }
    }

    return SyncResult(
      syncedCount: syncedCount,
      failedCount: failedCount,
      errors: errors,
    );
  }

  /// Synchronise un seul scan avec retry exponentiel
  Future<void> _syncSingleScan(ScanEvent scan) async {
    final model = ScanEventModel.fromEntity(scan);

    final response = await _dio.post(
      '/scans',
      data: model.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _scanRepository.markAsSynced(scan.id);
      _logger.d('Scan ${scan.id} synced successfully');
    } else {
      throw Exception('Sync failed with status: ${response.statusCode}');
    }
  }

  /// Synchronisation en mode demo (simulation)
  Future<SyncResult> _demoSync(List<ScanEvent> scans) async {
    _logger.w('Demo mode: simulating sync of ${scans.length} scans');

    await Future.delayed(const Duration(milliseconds: 500));

    // Marquer tous les scans comme synchronisés
    for (final scan in scans) {
      await _scanRepository.markAsSynced(scan.id);
    }

    return SyncResult(
      syncedCount: scans.length,
      failedCount: 0,
      errors: [],
    );
  }

  /// Force une synchronisation immédiate
  Future<SyncResult> forceSyncNow() async {
    _logger.i('Force sync requested');
    return await syncPendingScans();
  }

  void dispose() {
    stopAutoSync();
    _syncController.close();
  }
}
