import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

/// Service de base de données SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _logger = Logger();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    _logger.i('Initializing database at: $path');

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables (version $version)');

    // Table tickets
    await db.execute('''
      CREATE TABLE tickets (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        status TEXT NOT NULL,
        expiresAt INTEGER,
        meta TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Table scan_events
    await db.execute('''
      CREATE TABLE scan_events (
        id TEXT PRIMARY KEY,
        ticketId TEXT NOT NULL,
        scanType TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        geohash TEXT,
        deviceId TEXT NOT NULL,
        agentId TEXT NOT NULL,
        offline INTEGER NOT NULL,
        verdict TEXT NOT NULL,
        reason TEXT,
        syncedAt INTEGER,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Table user (un seul enregistrement)
    await db.execute('''
      CREATE TABLE user (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        lastLoginAt INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Index pour performance
    await db.execute('CREATE INDEX idx_scan_events_synced ON scan_events(syncedAt)');
    await db.execute('CREATE INDEX idx_scan_events_timestamp ON scan_events(timestamp DESC)');
    await db.execute('CREATE INDEX idx_tickets_status ON tickets(status)');

    _logger.i('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');
    // TODO: Gérer les migrations futures
  }

  /// Nettoie les anciens scans (> 30 jours)
  Future<int> cleanOldScans() async {
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: AppConstants.historyRetentionDays))
        .millisecondsSinceEpoch;

    final count = await db.delete(
      'scan_events',
      where: 'timestamp < ? AND syncedAt IS NOT NULL',
      whereArgs: [cutoffDate],
    );

    _logger.i('Cleaned $count old scan events');
    return count;
  }

  /// Ferme la base de données
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.i('Database closed');
    }
  }

  /// Supprime toutes les données (pour reset complet)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    await close();
    await databaseFactory.deleteDatabase(path);
    _logger.w('Database deleted');
  }
}
