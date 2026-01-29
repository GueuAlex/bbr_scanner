import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/ticket.dart';

part 'ticket_model.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.code,
    required super.status,
    super.expiresAt,
    super.meta,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      code: json['code'] as String,
      status: TicketStatus.fromString(json['status'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'status': status.value,
      'expiresAt': expiresAt?.toIso8601String(),
      'meta': meta,
    };
  }

  factory TicketModel.fromEntity(Ticket ticket) {
    return TicketModel(
      id: ticket.id,
      code: ticket.code,
      status: ticket.status,
      expiresAt: ticket.expiresAt,
      meta: ticket.meta,
    );
  }

  Ticket toEntity() {
    return Ticket(
      id: id,
      code: code,
      status: status,
      expiresAt: expiresAt,
      meta: meta,
    );
  }

  /// Crée une copie avec les champs modifiés
  @override
  TicketModel copyWith({
    String? id,
    String? code,
    TicketStatus? status,
    DateTime? expiresAt,
    Map<String, dynamic>? meta,
  }) {
    return TicketModel(
      id: id ?? this.id,
      code: code ?? this.code,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      meta: meta ?? this.meta,
    );
  }

  /// Conversion depuis/vers Map pour SQLite
  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as String,
      code: map['code'] as String,
      status: TicketStatus.fromString(map['status'] as String),
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
      meta: map['meta'] != null
          ? Map<String, dynamic>.from(map['meta'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'status': status.value,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'meta': meta != null ? Map<String, dynamic>.from(meta!) : null,
    };
  }
}
