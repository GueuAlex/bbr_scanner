import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../auth/login_screen.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Écran des paramètres
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final darkMode = ref.watch(darkModeProvider);
    final unsyncedCount = ref.watch(unsyncedScansCountProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // Section Utilisateur
          _SectionHeader(title: 'Compte'),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(user?.name ?? 'Agent'),
            subtitle: Text(user?.email ?? ''),
            trailing: Chip(
              label: Text(user?.role ?? 'AGENT'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          const Divider(),

          // Section Synchronisation
          _SectionHeader(title: 'Synchronisation'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Scans non synchronisés'),
            subtitle: unsyncedCount.when(
              data: (count) => Text('$count scan(s) en attente'),
              loading: () => const Text('Chargement...'),
              error: (_, __) => const Text('Erreur'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.sync_outlined),
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
          ),
          const Divider(),

          // Section Apparence
          _SectionHeader(title: 'Apparence'),
          SwitchListTile(
            secondary: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Mode sombre'),
            subtitle: const Text('Activer le thème sombre'),
            value: darkMode,
            onChanged: (value) {
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),
          const Divider(),

          // Section Configuration
          _SectionHeader(title: 'Configuration'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Tolérance expiration'),
            subtitle: Text('${config.scanWindowToleranceSec ~/ 60} minutes'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined),
            title: const Text('Géolocalisation'),
            subtitle: const Text('Enregistrer la position des scans'),
            value: config.requireGeo,
            onChanged: (value) {
              ref.read(appConfigProvider.notifier).updateRequireGeo(value);
            },
          ),
          const Divider(),

          // Section À Propos
          _SectionHeader(title: 'À propos'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Mode Build'),
            subtitle: Text(dotenv.env['ENV_BUILD_MODE'] ?? 'demo'),
          ),
          const Divider(),

          // Section Actions
          _SectionHeader(title: 'Actions'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des scans'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Naviguer vers l'historique
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historique (À venir)')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Nettoyer les données'),
            subtitle: const Text('Supprimer les scans synchronisés'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCleanDataDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Arrêter la synchronisation
      final syncService = ref.read(syncServiceProvider);
      syncService.stopAutoSync();

      // Déconnexion
      final authService = ref.read(authServiceProvider);
      await authService.logout();

      // Naviguer vers l'écran de connexion
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _showCleanDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les données'),
        content: const Text(
          'Cette action supprimera tous les scans déjà synchronisés. '
          'Les scans non synchronisés seront conservés.\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final databaseService = ref.read(databaseServiceProvider);
      final count = await databaseService.cleanOldScans();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count scan(s) supprimé(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Widget d'en-tête de section
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
