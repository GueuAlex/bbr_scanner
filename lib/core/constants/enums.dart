/// Type de scan (point de contrôle)
enum ScanType {
  board('BOARD', 'Embarquement'),
  disembark('DISEMBARK', 'Débarquement');

  final String value;
  final String label;

  const ScanType(this.value, this.label);

  static ScanType fromString(String value) {
    return ScanType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ScanType.board,
    );
  }
}

/// Statut d'un ticket
enum TicketStatus {
  newTicket('NEW', 'Nouveau'),
  boarded('BOARDED', 'Embarqué'),
  disembarked('DISEMBARKED', 'Débarqué'),
  expired('EXPIRED', 'Expiré'),
  blocked('BLOCKED', 'Bloqué');

  final String value;
  final String label;

  const TicketStatus(this.value, this.label);

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TicketStatus.newTicket,
    );
  }
}

/// Verdict d'un scan
enum ScanVerdict {
  ok('OK', 'Valide', true),
  rejected('REJECTED', 'Rejeté', false),
  duplicate('DUPLICATE', 'Déjà scanné', false),
  orderError('ORDER_ERROR', 'Ordre invalide', false),
  expired('EXPIRED', 'Expiré', false),
  signatureInvalid('SIGNATURE_INVALID', 'Signature invalide', false),
  unknown('UNKNOWN', 'Erreur inconnue', false);

  final String value;
  final String label;
  final bool isSuccess;

  const ScanVerdict(this.value, this.label, this.isSuccess);

  static ScanVerdict fromString(String value) {
    return ScanVerdict.values.firstWhere(
      (verdict) => verdict.value == value,
      orElse: () => ScanVerdict.unknown,
    );
  }
}

/// Mode de build
enum BuildMode {
  dev('dev'),
  staging('staging'),
  demo('demo'),
  production('production');

  final String value;

  const BuildMode(this.value);

  static BuildMode fromString(String value) {
    return BuildMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => BuildMode.demo,
    );
  }
}

/// Statut de connexion réseau
enum NetworkStatus {
  online,
  offline,
  unknown,
}
