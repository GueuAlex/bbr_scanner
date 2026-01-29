#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Script pour générer des QR codes de test (format JSON simple)
/// Usage: dart tools/generate_demo_qr.dart

void main() async {
  print('=== Générateur de QR Codes de Test BBR ===\n');

  final outputDir = Directory('demo_qr_codes');
  if (!outputDir.existsSync()) {
    outputDir.createSync();
  }

  final tickets = [
    // 1. Nouveau ticket valide
    {
      'id': 'new-valid',
      'name': 'Ticket Valide Nouveau',
      'status': 'NEW',
      'expiresAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'description': 'Peut être embarqué',
    },

    // 2. Ticket déjà embarqué
    {
      'id': 'already-boarded',
      'name': 'Ticket Déjà Embarqué',
      'status': 'BOARDED',
      'expiresAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'description': 'Sera refusé à l\'embarquement (duplicate)',
    },

    // 3. Ticket déjà débarqué
    {
      'id': 'already-disembarked',
      'name': 'Ticket Déjà Débarqué',
      'status': 'DISEMBARKED',
      'expiresAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'description': 'Sera refusé partout (duplicate)',
    },

    // 4. Ticket expiré
    {
      'id': 'expired',
      'name': 'Ticket Expiré',
      'status': 'NEW',
      'expiresAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'description': 'Sera refusé (expiré)',
    },

    // 5. Ticket bloqué
    {
      'id': 'blocked',
      'name': 'Ticket Bloqué',
      'status': 'BLOCKED',
      'expiresAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'description': 'Sera refusé (bloqué)',
    },

    // 6-10. Tickets valides pour tests multiples
    for (var i = 1; i <= 5; i++)
      {
        'id': 'test-valid-$i',
        'name': 'Ticket Test $i',
        'status': 'NEW',
        'expiresAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'description': 'Ticket valide pour tests',
      },
  ];

  final manifestFile = File('${outputDir.path}/MANIFEST.md');
  final manifest = StringBuffer();
  manifest.writeln('# QR Codes de Test BBR\n');
  manifest.writeln('Généré le: ${DateTime.now()}\n');
  manifest.writeln('## Liste des tickets\n');

  for (var i = 0; i < tickets.length; i++) {
    final ticket = tickets[i];
    final ticketId = ticket['id'] as String;

    // Créer le payload QR (format JSON simple pour la démo)
    final qrPayload = {
      'tkt': ticketId,
      'typ': 'BBR',
      'iat': (DateTime.now().millisecondsSinceEpoch / 1000).round(),
      'exp': (DateTime.parse(ticket['expiresAt'] as String).millisecondsSinceEpoch / 1000).round(),
      'v': '1',
    };

    final qrJson = json.encode(qrPayload);
    final qrFile = File('${outputDir.path}/$ticketId.txt');
    await qrFile.writeAsString(qrJson);

    // Créer un fichier d'infos
    final infoFile = File('${outputDir.path}/$ticketId.json');
    await infoFile.writeAsString(
      JsonEncoder.withIndent('  ').convert({
        ...ticket,
        'qr_payload': qrPayload,
        'qr_content': qrJson,
        'file': '$ticketId.txt',
      }),
    );

    manifest.writeln('### ${i + 1}. ${ticket['name']}');
    manifest.writeln('- **ID**: `$ticketId`');
    manifest.writeln('- **Statut**: ${ticket['status']}');
    manifest.writeln('- **Expiration**: ${ticket['expiresAt']}');
    manifest.writeln('- **Description**: ${ticket['description']}');
    manifest.writeln('- **Fichier QR**: `$ticketId.txt`');
    manifest.writeln('- **Détails**: `$ticketId.json`\n');

    print('✓ Généré: $ticketId');
  }

  manifest.writeln('## Utilisation\n');
  manifest.writeln('1. Scannez les fichiers `.txt` avec un générateur de QR code en ligne');
  manifest.writeln('2. Ou utilisez le contenu directement dans l\'application en mode démo');
  manifest.writeln('3. Les fichiers `.json` contiennent toutes les informations du ticket\n');

  manifest.writeln('## Scénarios de Test\n');
  manifest.writeln('### Test Embarquement');
  manifest.writeln('1. Scanner `new-valid` → ✅ Accepté (NEW → BOARDED)');
  manifest.writeln('2. Scanner `new-valid` à nouveau → ❌ Refusé (duplicate)');
  manifest.writeln('3. Scanner `already-boarded` → ❌ Refusé (duplicate)');
  manifest.writeln('4. Scanner `expired` → ❌ Refusé (expiré)');
  manifest.writeln('5. Scanner `blocked` → ❌ Refusé (bloqué)\n');

  manifest.writeln('### Test Débarquement');
  manifest.writeln('1. Scanner `new-valid` sans l\'embarquer d\'abord → ❌ Refusé (order error)');
  manifest.writeln('2. Embarquer `test-valid-1` puis scanner au débarquement → ✅ Accepté (BOARDED → DISEMBARKED)');
  manifest.writeln('3. Scanner `test-valid-1` à nouveau au débarquement → ❌ Refusé (duplicate)');
  manifest.writeln('4. Scanner `already-disembarked` → ❌ Refusé (duplicate)\n');

  await manifestFile.writeAsString(manifest.toString());

  print('\n✅ ${tickets.length} QR codes générés dans le dossier: ${outputDir.path}/');
  print('📄 Consultez MANIFEST.md pour les détails et scénarios de test');
  print('\n💡 Astuce: Utilisez https://www.qr-code-generator.com/ pour convertir');
  print('   les contenus .txt en images QR à scanner avec l\'application');
}
