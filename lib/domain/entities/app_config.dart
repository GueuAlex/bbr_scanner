import 'package:equatable/equatable.dart';

/// Entité Configuration de l'Application
class AppConfig extends Equatable {
  final int scanWindowToleranceSec;
  final bool requireGeo;
  final Map<String, dynamic>? retryPolicy;
  final Map<String, bool>? featureFlags;
  final String? version;

  const AppConfig({
    required this.scanWindowToleranceSec,
    required this.requireGeo,
    this.retryPolicy,
    this.featureFlags,
    this.version,
  });

  /// Configuration par défaut
  factory AppConfig.defaultConfig() {
    return const AppConfig(
      scanWindowToleranceSec: 600, // 10 minutes
      requireGeo: false,
      retryPolicy: {
        'maxAttempts': 5,
        'delays': [1000, 3000, 10000, 30000, 300000],
      },
      featureFlags: {
        'enableManualEntry': true,
        'enableGeolocation': false,
        'enableDebugLogs': false,
        'enableSandboxMode': true,
      },
      version: '1.0.0',
    );
  }

  /// Vérifie si une feature flag est active
  bool isFeatureEnabled(String featureName) {
    if (featureFlags == null) return false;
    return featureFlags![featureName] ?? false;
  }

  AppConfig copyWith({
    int? scanWindowToleranceSec,
    bool? requireGeo,
    Map<String, dynamic>? retryPolicy,
    Map<String, bool>? featureFlags,
    String? version,
  }) {
    return AppConfig(
      scanWindowToleranceSec: scanWindowToleranceSec ?? this.scanWindowToleranceSec,
      requireGeo: requireGeo ?? this.requireGeo,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      featureFlags: featureFlags ?? this.featureFlags,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        scanWindowToleranceSec,
        requireGeo,
        retryPolicy,
        featureFlags,
        version,
      ];
}
