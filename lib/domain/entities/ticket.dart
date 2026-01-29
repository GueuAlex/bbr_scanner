import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Entité Ticket
class Ticket extends Equatable {
  final String id;
  final String code;
  final TicketStatus status;
  final DateTime? expiresAt;
  final Map<String, dynamic>? meta;

  const Ticket({
    required this.id,
    required this.code,
    required this.status,
    this.expiresAt,
    this.meta,
  });

  /// Vérifie si le ticket est expiré
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Vérifie si le ticket est dans la fenêtre de tolérance
  bool isWithinTolerance(int toleranceSec) {
    if (expiresAt == null) return true;
    final now = DateTime.now();
    final toleranceEnd = expiresAt!.add(Duration(seconds: toleranceSec));
    return now.isBefore(toleranceEnd);
  }

  Ticket copyWith({
    String? id,
    String? code,
    TicketStatus? status,
    DateTime? expiresAt,
    Map<String, dynamic>? meta,
  }) {
    return Ticket(
      id: id ?? this.id,
      code: code ?? this.code,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      meta: meta ?? this.meta,
    );
  }

  @override
  List<Object?> get props => [id, code, status, expiresAt, meta];

  @override
  String toString() => 'Ticket(id: $id, code: $code, status: ${status.value}, expiresAt: $expiresAt)';
}
