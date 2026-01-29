import 'package:logger/logger.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/app_config.dart';

/// Résultat de validation
class ValidationResult {
  final bool isValid;
  final ScanVerdict verdict;
  final String? reason;
  final TicketStatus? newStatus;

  const ValidationResult({
    required this.isValid,
    required this.verdict,
    this.reason,
    this.newStatus,
  });

  factory ValidationResult.success(TicketStatus newStatus) {
    return ValidationResult(
      isValid: true,
      verdict: ScanVerdict.ok,
      newStatus: newStatus,
    );
  }

  factory ValidationResult.failure(ScanVerdict verdict, String reason) {
    return ValidationResult(
      isValid: false,
      verdict: verdict,
      reason: reason,
    );
  }
}

/// Service de validation des règles métier pour les scans
class ValidationService {
  final _logger = Logger();

  /// Valide un scan selon les règles métier
  ValidationResult validateScan({
    required Ticket ticket,
    required ScanType scanType,
    required AppConfig config,
  }) {
    _logger.d('Validating scan: ticketId=${ticket.id}, scanType=${scanType.value}, ticketStatus=${ticket.status.value}');

    // 1. Vérifier si le ticket est expiré
    if (!ticket.isWithinTolerance(config.scanWindowToleranceSec)) {
      return ValidationResult.failure(
        ScanVerdict.expired,
        'Ticket expiré depuis ${_formatExpiry(ticket.expiresAt)}',
      );
    }

    // 2. Vérifier si le ticket est bloqué
    if (ticket.status == TicketStatus.blocked) {
      return ValidationResult.failure(
        ScanVerdict.rejected,
        'Ticket bloqué',
      );
    }

    // 3. Appliquer les règles selon le type de scan
    return scanType == ScanType.board
        ? _validateBoarding(ticket)
        : _validateDisembarkation(ticket);
  }

  /// Règles d'embarquement
  ValidationResult _validateBoarding(Ticket ticket) {
    switch (ticket.status) {
      case TicketStatus.newTicket:
        // Cas normal: nouveau ticket → embarquement OK
        _logger.i('Boarding validated: new ticket → boarded');
        return ValidationResult.success(TicketStatus.boarded);

      case TicketStatus.boarded:
        // Déjà embarqué
        return ValidationResult.failure(
          ScanVerdict.duplicate,
          'Ticket déjà embarqué',
        );

      case TicketStatus.disembarked:
        // Déjà utilisé complètement
        return ValidationResult.failure(
          ScanVerdict.duplicate,
          'Ticket déjà utilisé (débarqué)',
        );

      case TicketStatus.expired:
        return ValidationResult.failure(
          ScanVerdict.expired,
          'Ticket expiré',
        );

      case TicketStatus.blocked:
        return ValidationResult.failure(
          ScanVerdict.rejected,
          'Ticket bloqué',
        );
    }
  }

  /// Règles de débarquement
  ValidationResult _validateDisembarkation(Ticket ticket) {
    switch (ticket.status) {
      case TicketStatus.newTicket:
        // Erreur: doit d'abord embarquer
        return ValidationResult.failure(
          ScanVerdict.orderError,
          'Le ticket doit d\'abord être embarqué',
        );

      case TicketStatus.boarded:
        // Cas normal: embarqué → débarquement OK
        _logger.i('Disembarkation validated: boarded → disembarked');
        return ValidationResult.success(TicketStatus.disembarked);

      case TicketStatus.disembarked:
        // Déjà débarqué
        return ValidationResult.failure(
          ScanVerdict.duplicate,
          'Ticket déjà débarqué',
        );

      case TicketStatus.expired:
        return ValidationResult.failure(
          ScanVerdict.expired,
          'Ticket expiré',
        );

      case TicketStatus.blocked:
        return ValidationResult.failure(
          ScanVerdict.rejected,
          'Ticket bloqué',
        );
    }
  }

  String _formatExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return 'date inconnue';
    final now = DateTime.now();
    final diff = now.difference(expiresAt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}j';
    }
  }
}
