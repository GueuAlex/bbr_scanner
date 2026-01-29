import 'package:logger/logger.dart';
import '../../core/storage/database_service.dart';
import '../../domain/entities/ticket.dart';
import '../models/ticket_model.dart';

/// Repository pour la gestion des tickets
class TicketRepository {
  final DatabaseService _databaseService;
  final _logger = Logger();

  TicketRepository(this._databaseService);

  /// Sauvegarde ou met à jour un ticket
  Future<void> saveTicket(Ticket ticket) async {
    try {
      final db = await _databaseService.database;
      final model = TicketModel.fromEntity(ticket);

      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'tickets',
        {
          ...model.toMap(),
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.i('Ticket saved: ${ticket.id}');
    } catch (e, stack) {
      _logger.e('Error saving ticket: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère un ticket par ID
  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      final db = await _databaseService.database;

      final maps = await db.query(
        'tickets',
        where: 'id = ?',
        whereArgs: [ticketId],
        limit: 1,
      );

      if (maps.isEmpty) {
        _logger.d('Ticket not found: $ticketId');
        return null;
      }

      return TicketModel.fromMap(maps.first).toEntity();
    } catch (e, stack) {
      _logger.e('Error getting ticket: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Récupère un ticket par code
  Future<Ticket?> getTicketByCode(String code) async {
    try {
      final db = await _databaseService.database;

      final maps = await db.query(
        'tickets',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );

      if (maps.isEmpty) {
        _logger.d('Ticket not found by code: $code');
        return null;
      }

      return TicketModel.fromMap(maps.first).toEntity();
    } catch (e, stack) {
      _logger.e('Error getting ticket by code: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Met à jour le statut d'un ticket
  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus) async {
    try {
      final db = await _databaseService.database;

      await db.update(
        'tickets',
        {
          'status': newStatus.value,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [ticketId],
      );

      _logger.i('Ticket status updated: $ticketId → ${newStatus.value}');
    } catch (e, stack) {
      _logger.e('Error updating ticket status: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère tous les tickets
  Future<List<Ticket>> getAllTickets({int? limit}) async {
    try {
      final db = await _databaseService.database;

      final maps = await db.query(
        'tickets',
        orderBy: 'updatedAt DESC',
        limit: limit,
      );

      _logger.d('Retrieved ${maps.length} tickets');

      return maps.map((map) => TicketModel.fromMap(map).toEntity()).toList();
    } catch (e, stack) {
      _logger.e('Error getting all tickets: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Supprime tous les tickets
  Future<void> deleteAllTickets() async {
    try {
      final db = await _databaseService.database;
      await db.delete('tickets');
      _logger.w('All tickets deleted');
    } catch (e, stack) {
      _logger.e('Error deleting all tickets: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
