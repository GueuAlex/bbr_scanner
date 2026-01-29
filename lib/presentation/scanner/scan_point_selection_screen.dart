import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../settings/settings_screen.dart';
import 'scanner_screen.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/app_constants.dart';

/// Écran de sélection du point de scan (Embarquement / Débarquement)
class ScanPointSelectionScreen extends ConsumerWidget {
  const ScanPointSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final selectedScanPoint = ref.watch(selectedScanPointProvider);
    final unsyncedCount = ref.watch(unsyncedScansCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point de Contrôle'),
        actions: [
          // Badge des scans non synchronisés
          IconButton(
            icon: Badge(
              label: unsyncedCount.when(
                data: (count) => Text(count > 0 ? '$count' : ''),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              isLabelVisible: unsyncedCount.maybeWhen(
                data: (count) => count > 0,
                orElse: () => false,
              ),
              child: const Icon(Icons.sync),
            ),
            tooltip: 'Synchronisation',
            onPressed: () async {
              final syncService = ref.read(syncServiceProvider);
              final result = await syncService.forceSyncNow();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.allSynced
                          ? '${result.syncedCount} scan(s) synchronisé(s)'
                          : '${result.syncedCount} synchronisés, ${result.failedCount} échoués',
                    ),
                    backgroundColor: result.allSynced ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
          ),
          // Paramètres
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations utilisateur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Agent',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified_user,
                        color: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                'Sélectionnez le point de contrôle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Options de scan
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Embarquement
                    _ScanPointCard(
                      scanType: ScanType.board,
                      icon: Icons.directions_boat_filled,
                      title: 'Embarquement',
                      description: 'Contrôle à la montée du bateau',
                      isSelected: selectedScanPoint == ScanType.board,
                      onTap: () {
                        ref.read(selectedScanPointProvider.notifier).setScanPoint(ScanType.board);
                        _navigateToScanner(context, ScanType.board);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Débarquement
                    _ScanPointCard(
                      scanType: ScanType.disembark,
                      icon: Icons.logout,
                      title: 'Débarquement',
                      description: 'Contrôle à la sortie',
                      isSelected: selectedScanPoint == ScanType.disembark,
                      onTap: () {
                        ref.read(selectedScanPointProvider.notifier).setScanPoint(ScanType.disembark);
                        _navigateToScanner(context, ScanType.disembark);
                      },
                    ),
                  ],
                ),
              ),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sélectionnez votre poste pour commencer le contrôle des tickets',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScanner(BuildContext context, ScanType scanType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(scanType: scanType),
      ),
    );
  }
}

/// Carte de sélection du point de scan
class _ScanPointCard extends StatelessWidget {
  final ScanType scanType;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScanPointCard({
    required this.scanType,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
