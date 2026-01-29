import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/scan_event.dart';

part 'scan_event_model.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class ScanEventModel extends ScanEvent {
  const ScanEventModel({
    required super.id,
    required super.ticketId,
    required super.scanType,
    required super.timestamp,
    super.geohash,
    required super.deviceId,
    required super.agentId,
    required super.offline,
    required super.verdict,
    super.reason,
    super.syncedAt,
  });

  factory ScanEventModel.fromJson(Map<String, dynamic> json) {
    return ScanEventModel(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      scanType: ScanType.fromString(json['scanType'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      geohash: json['geohash'] as String?,
      deviceId: json['deviceId'] as String,
      agentId: json['agentId'] as String,
      offline: json['offline'] as bool,
      verdict: ScanVerdict.fromString(json['verdict'] as String),
      reason: json['reason'] as String?,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'scanType': scanType.value,
      'timestamp': timestamp.toIso8601String(),
      'geohash': geohash,
      'deviceId': deviceId,
      'agentId': agentId,
      'offline': offline,
      'verdict': verdict.value,
      'reason': reason,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  factory ScanEventModel.fromEntity(ScanEvent event) {
    return ScanEventModel(
      id: event.id,
      ticketId: event.ticketId,
      scanType: event.scanType,
      timestamp: event.timestamp,
      geohash: event.geohash,
      deviceId: event.deviceId,
      agentId: event.agentId,
      offline: event.offline,
      verdict: event.verdict,
      reason: event.reason,
      syncedAt: event.syncedAt,
    );
  }

  ScanEvent toEntity() {
    return ScanEvent(
      id: id,
      ticketId: ticketId,
      scanType: scanType,
      timestamp: timestamp,
      geohash: geohash,
      deviceId: deviceId,
      agentId: agentId,
      offline: offline,
      verdict: verdict,
      reason: reason,
      syncedAt: syncedAt,
    );
  }

  /// Conversion depuis/vers Map pour SQLite
  factory ScanEventModel.fromMap(Map<String, dynamic> map) {
    return ScanEventModel(
      id: map['id'] as String,
      ticketId: map['ticketId'] as String,
      scanType: ScanType.fromString(map['scanType'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      geohash: map['geohash'] as String?,
      deviceId: map['deviceId'] as String,
      agentId: map['agentId'] as String,
      offline: (map['offline'] as int) == 1,
      verdict: ScanVerdict.fromString(map['verdict'] as String),
      reason: map['reason'] as String?,
      syncedAt: map['syncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['syncedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'scanType': scanType.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'geohash': geohash,
      'deviceId': deviceId,
      'agentId': agentId,
      'offline': offline ? 1 : 0,
      'verdict': verdict.value,
      'reason': reason,
      'syncedAt': syncedAt?.millisecondsSinceEpoch,
    };
  }
}
