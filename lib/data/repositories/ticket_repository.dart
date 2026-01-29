import 'package:logger/logger.dart';
import '../../core/storage/hive_service.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/ticket.dart';
import '../models/ticket_model.dart';

/// Repository pour la gestion des tickets avec Hive
class TicketRepository {
  final HiveService _hiveService;
  final _logger = Logger();

  TicketRepository(this._hiveService);

  /// Sauvegarde ou met à jour un ticket
  Future<void> saveTicket(Ticket ticket) async {
    try {
      final box = _hiveService.getTicketsBox();
      final model = TicketModel.fromEntity(ticket);

      await box.put(ticket.id, model);

      _logger.i('Ticket saved: ${ticket.id}');
    } catch (e, stack) {
      _logger.e('Error saving ticket: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère un ticket par ID
  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      final box = _hiveService.getTicketsBox();
      final model = box.get(ticketId);

      if (model == null) {
        _logger.d('Ticket not found: $ticketId');
        return null;
      }

      return model.toEntity();
    } catch (e, stack) {
      _logger.e('Error getting ticket: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Récupère un ticket par code
  Future<Ticket?> getTicketByCode(String code) async {
    try {
      final box = _hiveService.getTicketsBox();

      // Parcourir tous les tickets pour trouver celui avec le bon code
      for (var ticket in box.values) {
        if (ticket.code == code) {
          return ticket.toEntity();
        }
      }

      _logger.d('Ticket not found by code: $code');
      return null;
    } catch (e, stack) {
      _logger.e('Error getting ticket by code: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Met à jour le statut d'un ticket
  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus) async {
    try {
      final box = _hiveService.getTicketsBox();
      final model = box.get(ticketId);

      if (model != null) {
        final updatedTicket = model.copyWith(status: newStatus);
        await box.put(ticketId, updatedTicket as TicketModel);

        _logger.i('Ticket status updated: $ticketId → ${newStatus.value}');
      }
    } catch (e, stack) {
      _logger.e('Error updating ticket status: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Récupère tous les tickets
  Future<List<Ticket>> getAllTickets({int? limit}) async {
    try {
      final box = _hiveService.getTicketsBox();
      final tickets = box.values.map((model) => model.toEntity()).toList();

      _logger.d('Retrieved ${tickets.length} tickets');

      if (limit != null && tickets.length > limit) {
        return tickets.sublist(0, limit);
      }

      return tickets;
    } catch (e, stack) {
      _logger.e('Error getting all tickets: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Supprime tous les tickets
  Future<void> deleteAllTickets() async {
    try {
      final box = _hiveService.getTicketsBox();
      await box.clear();
      _logger.w('All tickets deleted');
    } catch (e, stack) {
      _logger.e('Error deleting all tickets: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
