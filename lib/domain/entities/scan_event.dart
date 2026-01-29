import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Entité Événement de Scan
class ScanEvent extends Equatable {
  final String id;
  final String ticketId;
  final ScanType scanType;
  final DateTime timestamp;
  final String? geohash;
  final String deviceId;
  final String agentId;
  final bool offline;
  final ScanVerdict verdict;
  final String? reason;
  final DateTime? syncedAt;

  const ScanEvent({
    required this.id,
    required this.ticketId,
    required this.scanType,
    required this.timestamp,
    this.geohash,
    required this.deviceId,
    required this.agentId,
    required this.offline,
    required this.verdict,
    this.reason,
    this.syncedAt,
  });

  /// Vérifie si l'événement est synchronisé
  bool get isSynced => syncedAt != null;

  /// Retourne une description lisible du verdict
  String get verdictDescription {
    if (reason != null && reason!.isNotEmpty) {
      return '${verdict.label}: $reason';
    }
    return verdict.label;
  }

  ScanEvent copyWith({
    String? id,
    String? ticketId,
    ScanType? scanType,
    DateTime? timestamp,
    String? geohash,
    String? deviceId,
    String? agentId,
    bool? offline,
    ScanVerdict? verdict,
    String? reason,
    DateTime? syncedAt,
  }) {
    return ScanEvent(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      scanType: scanType ?? this.scanType,
      timestamp: timestamp ?? this.timestamp,
      geohash: geohash ?? this.geohash,
      deviceId: deviceId ?? this.deviceId,
      agentId: agentId ?? this.agentId,
      offline: offline ?? this.offline,
      verdict: verdict ?? this.verdict,
      reason: reason ?? this.reason,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticketId,
        scanType,
        timestamp,
        geohash,
        deviceId,
        agentId,
        offline,
        verdict,
        reason,
        syncedAt,
      ];

  @override
  String toString() {
    return 'ScanEvent(id: $id, ticketId: $ticketId, scanType: ${scanType.value}, '
        'verdict: ${verdict.value}, offline: $offline, synced: $isSynced)';
  }
}
