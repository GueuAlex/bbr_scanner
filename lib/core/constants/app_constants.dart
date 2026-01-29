/// Constantes globales de l'application BBR Scanner
class AppConstants {
  // Informations Application
  static const String appName = 'BBR Scanner';
  static const String appVersion = '1.0.0';
  static const String bundleId = 'com.bbr.scan';

  // Timeouts & Retry
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration scanDebounce = Duration(seconds: 1);
  static const int maxRetryAttempts = 5;
  static const List<int> retryDelaysMs = [1000, 3000, 10000, 30000, 300000]; // 1s, 3s, 10s, 30s, 5min

  // Validation
  static const int scanWindowToleranceSec = 600; // 10 minutes
  static const int historyRetentionDays = 30;

  // Database
  static const String databaseName = 'bbr_scanner.db';
  static const int databaseVersion = 1;

  // Secure Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';

  // SharedPreferences Keys
  static const String keySelectedScanPoint = 'selected_scan_point';
  static const String keyDarkMode = 'dark_mode';
  static const String keyRequireGeo = 'require_geo';
  static const String keyLastSyncTimestamp = 'last_sync_timestamp';
  static const String keyDeviceId = 'device_id';

  // Performance
  static const Duration scanResultMinDuration = Duration(milliseconds: 300);
  static const Duration coldStartTarget = Duration(seconds: 2);

  // UI
  static const double scannerAspectRatio = 1.0;
  static const int historyPageSize = 50;
}
