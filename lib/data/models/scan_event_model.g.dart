// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanEventModelAdapter extends TypeAdapter<ScanEventModel> {
  @override
  final int typeId = 2;

  @override
  ScanEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanEventModel(
      id: fields[0] as String,
      ticketId: fields[1] as String,
      scanType: ScanType.fromString(fields[2] as String),
      timestamp: fields[3] as DateTime,
      geohash: fields[4] as String?,
      deviceId: fields[5] as String,
      agentId: fields[6] as String,
      offline: fields[7] as bool,
      verdict: ScanVerdict.fromString(fields[8] as String),
      reason: fields[9] as String?,
      syncedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanEventModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ticketId)
      ..writeByte(2)
      ..write(obj.scanType.value)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.geohash)
      ..writeByte(5)
      ..write(obj.deviceId)
      ..writeByte(6)
      ..write(obj.agentId)
      ..writeByte(7)
      ..write(obj.offline)
      ..writeByte(8)
      ..write(obj.verdict.value)
      ..writeByte(9)
      ..write(obj.reason)
      ..writeByte(10)
      ..write(obj.syncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************
