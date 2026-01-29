// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TicketModelAdapter extends TypeAdapter<TicketModel> {
  @override
  final int typeId = 1;

  @override
  TicketModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TicketModel(
      id: fields[0] as String,
      code: fields[1] as String,
      status: TicketStatus.fromString(fields[2] as String),
      expiresAt: fields[3] as DateTime?,
      meta: fields[4] as Map<String, dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, TicketModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.status.value)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.meta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************
