import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/scan_event.dart';
import '../../core/constants/enums.dart';

/// Écran d'affichage du résultat d'un scan
class ScanResultScreen extends StatelessWidget {
  final Ticket ticket;
  final ScanEvent scanEvent;

  const ScanResultScreen({
    super.key,
    required this.ticket,
    required this.scanEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = scanEvent.verdict.isSuccess;

    return Scaffold(
      backgroundColor: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      appBar: AppBar(
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        title: Text(isSuccess ? 'Scan Valide' : 'Scan Refusé'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône principale
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Verdict
                Text(
                  scanEvent.verdict.label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Raison (si refusé)
                if (!isSuccess && scanEvent.reason != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            scanEvent.reason!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Informations du ticket
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations Ticket',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.confirmation_number,
                          label: 'ID Ticket',
                          value: ticket.id,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.qr_code,
                          label: 'Code',
                          value: ticket.code,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.info_outline,
                          label: 'Statut',
                          value: ticket.status.label,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Heure du scan',
                          value: DateFormat('dd/MM/yyyy HH:mm:ss').format(scanEvent.timestamp),
                        ),
                        if (ticket.expiresAt != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.event,
                            label: 'Expiration',
                            value: DateFormat('dd/MM/yyyy HH:mm').format(ticket.expiresAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Type de scan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scanEvent.scanType == ScanType.board
                            ? Icons.directions_boat_filled
                            : Icons.logout,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        scanEvent.scanType.label,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton retour
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Scanner suivant'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher une ligne d'information
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
