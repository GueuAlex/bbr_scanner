import 'package:flutter_test/flutter_test.dart';
import 'package:bbr_scanner/core/services/validation_service.dart';
import 'package:bbr_scanner/core/constants/enums.dart';
import 'package:bbr_scanner/domain/entities/ticket.dart';
import 'package:bbr_scanner/domain/entities/app_config.dart';

void main() {
  late ValidationService validationService;
  late AppConfig config;

  setUp(() {
    validationService = ValidationService();
    config = AppConfig.defaultConfig();
  });

  group('Validation Embarquement (BOARD)', () {
    test('Nouveau ticket → Embarquement accepté', () {
      final ticket = Ticket(
        id: 'ticket-1',
        code: 'TEST001',
        status: TicketStatus.newTicket,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, true);
      expect(result.verdict, ScanVerdict.ok);
      expect(result.newStatus, TicketStatus.boarded);
    });

    test('Ticket déjà embarqué → Refusé (duplicate)', () {
      final ticket = Ticket(
        id: 'ticket-2',
        code: 'TEST002',
        status: TicketStatus.boarded,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.duplicate);
      expect(result.reason, contains('déjà embarqué'));
    });

    test('Ticket déjà débarqué → Refusé (duplicate)', () {
      final ticket = Ticket(
        id: 'ticket-3',
        code: 'TEST003',
        status: TicketStatus.disembarked,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.duplicate);
    });

    test('Ticket expiré → Refusé', () {
      final ticket = Ticket(
        id: 'ticket-4',
        code: 'TEST004',
        status: TicketStatus.newTicket,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.expired);
    });

    test('Ticket bloqué → Refusé', () {
      final ticket = Ticket(
        id: 'ticket-5',
        code: 'TEST005',
        status: TicketStatus.blocked,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.rejected);
    });
  });

  group('Validation Débarquement (DISEMBARK)', () {
    test('Ticket embarqué → Débarquement accepté', () {
      final ticket = Ticket(
        id: 'ticket-6',
        code: 'TEST006',
        status: TicketStatus.boarded,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.disembark,
        config: config,
      );

      expect(result.isValid, true);
      expect(result.verdict, ScanVerdict.ok);
      expect(result.newStatus, TicketStatus.disembarked);
    });

    test('Ticket non embarqué → Refusé (order error)', () {
      final ticket = Ticket(
        id: 'ticket-7',
        code: 'TEST007',
        status: TicketStatus.newTicket,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.disembark,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.orderError);
      expect(result.reason, contains('embarqué'));
    });

    test('Ticket déjà débarqué → Refusé (duplicate)', () {
      final ticket = Ticket(
        id: 'ticket-8',
        code: 'TEST008',
        status: TicketStatus.disembarked,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.disembark,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.duplicate);
      expect(result.reason, contains('déjà débarqué'));
    });
  });

  group('Tolérance d\'expiration', () {
    test('Ticket expiré dans la fenêtre de tolérance → Accepté', () {
      // Ticket expiré il y a 5 minutes, tolérance de 10 minutes
      final ticket = Ticket(
        id: 'ticket-9',
        code: 'TEST009',
        status: TicketStatus.newTicket,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, true);
      expect(result.verdict, ScanVerdict.ok);
    });

    test('Ticket expiré hors fenêtre de tolérance → Refusé', () {
      // Ticket expiré il y a 15 minutes, tolérance de 10 minutes
      final ticket = Ticket(
        id: 'ticket-10',
        code: 'TEST010',
        status: TicketStatus.newTicket,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      final result = validationService.validateScan(
        ticket: ticket,
        scanType: ScanType.board,
        config: config,
      );

      expect(result.isValid, false);
      expect(result.verdict, ScanVerdict.expired);
    });
  });
}
