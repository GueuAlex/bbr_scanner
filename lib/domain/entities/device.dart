import 'package:equatable/equatable.dart';

/// Entité Device (Appareil)
class Device extends Equatable {
  final String id;
  final String model;
  final String os;
  final String appVersion;
  final DateTime? lastSync;

  const Device({
    required this.id,
    required this.model,
    required this.os,
    required this.appVersion,
    this.lastSync,
  });

  Device copyWith({
    String? id,
    String? model,
    String? os,
    String? appVersion,
    DateTime? lastSync,
  }) {
    return Device(
      id: id ?? this.id,
      model: model ?? this.model,
      os: os ?? this.os,
      appVersion: appVersion ?? this.appVersion,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  List<Object?> get props => [id, model, os, appVersion, lastSync];
}
