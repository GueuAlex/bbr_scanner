# BBR Scanner - Documentation Complète

Application mobile Flutter de contrôle et validation de tickets pour le système BBR (Bateau Baie Riveraine) aux points d'embarquement et de débarquement.

---

## 📑 Table des matières

1. [Vue d'ensemble](#-vue-densemble)
2. [Architecture](#-architecture-détaillée)
3. [Fonctionnement du Scan](#-fonctionnement-du-scan)
4. [Statuts et Transitions](#-statuts-et-transitions-des-tickets)
5. [Format des QR Codes](#-format-des-qr-codes)
6. [Synchronisation Offline](#-synchronisation-offline-first)
7. [Installation](#-installation)
8. [Utilisation](#-utilisation)
9. [Tests](#-tests)
10. [Sécurité](#-sécurité)
11. [Troubleshooting](#-troubleshooting)

---

## 📱 Vue d'ensemble

### Description du projet

BBR Scanner est une application mobile **offline-first** de scan et validation de QR codes pour le contrôle d'accès aux bateaux de transport. L'application permet aux agents de contrôle de valider les tickets aux deux points critiques du voyage:

- **Point d'embarquement** (BOARD): Validation lors de la montée des passagers
- **Point de débarquement** (DISEMBARK): Validation lors de la descente des passagers

### Problématique résolue

L'application résout les problèmes suivants:

- ✅ **Validation hors-ligne**: Fonctionne sans connexion internet
- ✅ **Prévention des fraudes**: Empêche les scans multiples et les tickets invalides
- ✅ **Traçabilité**: Enregistre tous les scans avec horodatage et localisation
- ✅ **Synchronisation fiable**: Retry automatique avec stratégie exponential backoff
- ✅ **Rapidité**: Temps de scan < 1 seconde avec debounce anti-spam
- ✅ **Audit**: Logs complets de toutes les opérations

### Fonctionnalités principales

| Fonctionnalité          | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| 🔐 **Authentification** | JWT avec refresh tokens stockés en Keychain/Keystore |
| 📸 **Scan QR**          | Détection temps réel avec ML Kit / AVFoundation      |
| ✅ **Validation**       | Règles métier complexes avec machine à états         |
| 💾 **Stockage local**   | Hive NoSQL pour performance optimale                 |
| 🔄 **Sync offline**     | File d'attente avec retry exponentiel                |
| 🎯 **Dual mode**        | Embarquement et Débarquement avec règles spécifiques |
| 🌙 **Mode sombre**      | Interface Material Design 3 moderne                  |

---

## 🏗️ Architecture détaillée

### Clean Architecture

L'application suit une architecture en couches strictement séparées pour faciliter la maintenance, les tests et l'évolution:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (UI, Screens, Widgets, Riverpod State Management)         │
├─────────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                             │
│        (Business Entities, Use Cases, Interfaces)           │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│      (Repositories, Models, Data Sources, Mappers)          │
├─────────────────────────────────────────────────────────────┤
│                   INFRASTRUCTURE LAYER                       │
│    (Services, Storage, Network, Device APIs, External)      │
└─────────────────────────────────────────────────────────────┘
```

### Structure des dossiers

```
lib/
├── core/                           # Infrastructure & Services
│   ├── constants/
│   │   ├── app_constants.dart     # Constantes globales (URLs, timeouts)
│   │   └── enums.dart            # Enums (ScanType, TicketStatus, ScanVerdict)
│   ├── services/
│   │   ├── auth_service.dart     # Authentification JWT
│   │   ├── sync_service.dart     # Synchronisation offline
│   │   ├── validation_service.dart # Règles métier de validation
│   │   └── qr_decoder_service.dart # Décodage et vérification QR
│   └── storage/
│       ├── hive_service.dart     # Gestion base Hive
│       └── secure_storage_service.dart # Keychain/Keystore wrapper
│
├── data/                           # Couche de données
│   ├── models/
│   │   ├── user_model.dart       # Modèle utilisateur (avec @HiveType)
│   │   ├── ticket_model.dart     # Modèle ticket (avec @HiveType)
│   │   └── scan_event_model.dart # Modèle événement scan (avec @HiveType)
│   └── repositories/
│       ├── user_repository.dart   # CRUD utilisateur
│       ├── ticket_repository.dart # CRUD tickets
│       └── scan_repository.dart   # CRUD scans + queries sync
│
├── domain/                         # Couche métier
│   └── entities/
│       ├── user.dart             # Entité utilisateur pure
│       ├── ticket.dart           # Entité ticket pure
│       ├── scan_event.dart       # Entité événement scan pure
│       ├── device.dart           # Entité device
│       └── app_config.dart       # Configuration app
│
└── presentation/                   # Couche présentation
    ├── providers/
    │   └── app_providers.dart    # Tous les providers Riverpod centralisés
    ├── auth/
    │   └── login_screen.dart     # Écran de connexion
    ├── scanner/
    │   ├── scan_point_selection_screen.dart # Sélection Embarquement/Débarquement
    │   ├── scanner_screen.dart   # Écran de scan QR avec caméra
    │   └── scan_result_screen.dart # Résultat du scan
    └── settings/
        └── settings_screen.dart  # Paramètres app
```

### Technologies utilisées

| Couche               | Technologie            | Version | Usage                                |
| -------------------- | ---------------------- | ------- | ------------------------------------ |
| **Framework**        | Flutter                | 3.10.1+ | Framework mobile cross-platform      |
| **Language**         | Dart                   | 3.10.1+ | Langage de programmation             |
| **State Management** | Riverpod               | 2.6.1   | Gestion d'état réactive              |
| **Database**         | Hive                   | 2.2.3   | Base NoSQL locale performante        |
| **Secure Storage**   | flutter_secure_storage | 9.2.2   | Keychain/Keystore natif              |
| **QR Scanner**       | mobile_scanner         | 5.2.3   | Scan QR avec ML Kit / AVFoundation   |
| **HTTP Client**      | Dio                    | 5.7.0   | Client HTTP avec interceptors        |
| **JWT**              | dart_jsonwebtoken      | 2.14.1  | Décodage et vérification JWT (RS256) |
| **Environment**      | flutter_dotenv         | 5.1.0   | Variables d'environnement            |
| **Logging**          | logger                 | 2.0.2   | Logs structurés et colorés           |
| **Connectivity**     | connectivity_plus      | 6.1.1   | Détection connexion réseau           |
| **Feedback**         | vibration              | 2.0.0   | Vibration haptique                   |

---

## 🔄 Fonctionnement du Scan

### Flux complet du processus de scan

```
┌──────────────┐
│  Agent ouvre │
│     l'app    │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  Authentification│
│   (JWT tokens)   │
└──────┬───────────┘
       │
       ▼
┌──────────────────────┐
│ Sélection du point:  │
│ • BOARD (Embarquement│
│ • DISEMBARK (Débar.) │
└──────┬───────────────┘
       │
       ▼
┌────────────────────────┐
│  Scanner QR activé     │
│  Caméra en temps réel  │
└──────┬─────────────────┘
       │ QR détecté
       ▼
┌────────────────────────────┐
│  1. Décodage QR            │
│     • JWT → vérifie RS256  │
│     • JSON → vérifie format│
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  2. Récupération ticket    │
│     • Cherche en local     │
│     • Créé si nouveau      │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  3. Validation métier      │
│     • Vérifie statut       │
│     • Vérifie expiration   │
│     • Applique règles      │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  4. Enregistrement         │
│     • Crée ScanEvent       │
│     • Sauvegarde en Hive   │
│     • Met à jour statut    │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  5. Feedback utilisateur   │
│     • Vibration            │
│     • Animation verte/rouge│
│     • Écran résultat       │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  6. Synchronisation auto   │
│     • File d'attente       │
│     • Retry exponentiel    │
└────────────────────────────┘
```

### Détail des étapes

#### Étape 1: Décodage du QR Code

```dart
// lib/core/services/qr_decoder_service.dart

Future<QrPayload?> decode(String rawQrData) async {
  // 1. Tentative décodage JWT (format principal)
  final jwtPayload = await _tryDecodeJwt(rawQrData);
  if (jwtPayload != null) return jwtPayload;

  // 2. Tentative décodage JSON+signature
  final jsonPayload = await _tryDecodeJsonSignature(rawQrData);
  if (jsonPayload != null) return jsonPayload;

  // 3. Fallback: JSON simple (mode demo)
  final simplePayload = _tryDecodeSimpleJson(rawQrData);
  return simplePayload;
}
```

**Formats acceptés**:

1. **JWT signé RS256** (production)
2. **JSON avec signature HMAC** (staging)
3. **JSON simple** (demo/test)

#### Étape 2: Récupération/Création du Ticket

```dart
// lib/presentation/scanner/scanner_screen.dart

// Récupérer le ticket existant
var ticket = await ticketRepo.getTicketById(payload.ticketId);

// Si nouveau, créer avec statut NEW
if (ticket == null) {
  ticket = Ticket(
    id: payload.ticketId,
    code: payload.ticketId,
    status: TicketStatus.newTicket,
    expiresAt: payload.expiresAt,
  );
  await ticketRepo.saveTicket(ticket);
}
```

#### Étape 3: Validation Métier

```dart
// lib/core/services/validation_service.dart

ValidationResult validateScan({
  required Ticket ticket,
  required ScanType scanType,
  required AppConfig config,
}) {
  // 1. Vérifier expiration (avec tolérance)
  if (_isExpired(ticket, config)) {
    return ValidationResult.reject(ScanVerdict.expired, 'Ticket expiré');
  }

  // 2. Vérifier statut BLOCKED
  if (ticket.status == TicketStatus.blocked) {
    return ValidationResult.reject(ScanVerdict.blocked, 'Ticket bloqué');
  }

  // 3. Appliquer règles selon type de scan
  if (scanType == ScanType.board) {
    return _validateBoarding(ticket);
  } else {
    return _validateDisembarking(ticket);
  }
}
```

#### Étape 4: Enregistrement du Scan Event

```dart
final scanEvent = ScanEvent(
  id: const Uuid().v4(),
  ticketId: ticket.id,
  scanType: widget.scanType,
  timestamp: DateTime.now(),
  deviceId: 'device-${user?.id ?? "unknown"}',
  agentId: user?.id ?? 'unknown',
  offline: true,  // Marqué offline pour sync ultérieure
  verdict: validationResult.verdict,
  reason: validationResult.reason,
);

await scanRepo.saveScanEvent(scanEvent);
```

#### Étape 5: Mise à jour du Statut Ticket

```dart
if (validationResult.isValid && validationResult.newStatus != null) {
  await ticketRepo.updateTicketStatus(
    ticket.id,
    validationResult.newStatus!,
  );
  ticket = ticket.copyWith(status: validationResult.newStatus);
}
```

#### Étape 6: Feedback Visuel

- **Son**: Vibration (100ms pour succès, pattern pour erreur)
- **Animation**: Flash vert (accepté) ou rouge (refusé)
- **Écran**: Navigation vers `ScanResultScreen` avec détails

---

## 📊 Statuts et Transitions des Tickets

### Machine à États

```
                    ┌──────────┐
                    │   NEW    │  ← Ticket créé
                    └────┬─────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
     BOARD scan                    DISEMBARK scan
      (valide)                        (INVALIDE)
          │                             │
          ▼                             ▼
    ┌──────────┐                  [REJETÉ]
    │ BOARDED  │                 order_error
    └────┬─────┘
         │
         │ DISEMBARK scan
         │    (valide)
         ▼
  ┌──────────────┐
  │ DISEMBARKED  │  ← État final
  └──────────────┘
```

### Énumération des Statuts

```dart
enum TicketStatus {
  newTicket,    // 'NEW' - Ticket créé, jamais scanné
  boarded,      // 'BOARDED' - Passager embarqué
  disembarked,  // 'DISEMBARKED' - Passager débarqué
  expired,      // 'EXPIRED' - Ticket expiré
  blocked,      // 'BLOCKED' - Ticket bloqué (fraude/problème)
}
```

### Règles de Transition - Embarquement (BOARD)

| Statut Actuel | Action     | Résultat       | Nouveau Statut | Verdict     | Raison          |
| ------------- | ---------- | -------------- | -------------- | ----------- | --------------- |
| `NEW`         | Scan BOARD | ✅ **ACCEPTÉ** | `BOARDED`      | `valid`     | -               |
| `BOARDED`     | Scan BOARD | ❌ **REFUSÉ**  | -              | `duplicate` | "Déjà embarqué" |
| `DISEMBARKED` | Scan BOARD | ❌ **REFUSÉ**  | -              | `duplicate` | "Déjà débarqué" |
| `EXPIRED`     | Scan BOARD | ❌ **REFUSÉ**  | -              | `expired`   | "Ticket expiré" |
| `BLOCKED`     | Scan BOARD | ❌ **REFUSÉ**  | -              | `blocked`   | "Ticket bloqué" |

**Code d'implémentation**:

```dart
// lib/core/services/validation_service.dart

ValidationResult _validateBoarding(Ticket ticket) {
  switch (ticket.status) {
    case TicketStatus.newTicket:
      // ✅ Cas valide: nouveau ticket → embarquement autorisé
      return ValidationResult.accept(
        verdict: ScanVerdict.valid,
        newStatus: TicketStatus.boarded,
      );

    case TicketStatus.boarded:
    case TicketStatus.disembarked:
      // ❌ Déjà scanné
      return ValidationResult.reject(
        ScanVerdict.duplicate,
        'Ticket déjà utilisé',
      );

    case TicketStatus.blocked:
      return ValidationResult.reject(
        ScanVerdict.blocked,
        'Ticket bloqué',
      );

    default:
      return ValidationResult.reject(
        ScanVerdict.invalid,
        'Statut invalide',
      );
  }
}
```

### Règles de Transition - Débarquement (DISEMBARK)

| Statut Actuel | Action         | Résultat       | Nouveau Statut | Verdict       | Raison                |
| ------------- | -------------- | -------------- | -------------- | ------------- | --------------------- |
| `NEW`         | Scan DISEMBARK | ❌ **REFUSÉ**  | -              | `order_error` | "Pas encore embarqué" |
| `BOARDED`     | Scan DISEMBARK | ✅ **ACCEPTÉ** | `DISEMBARKED`  | `valid`       | -                     |
| `DISEMBARKED` | Scan DISEMBARK | ❌ **REFUSÉ**  | -              | `duplicate`   | "Déjà débarqué"       |
| `EXPIRED`     | Scan DISEMBARK | ❌ **REFUSÉ**  | -              | `expired`     | "Ticket expiré"       |
| `BLOCKED`     | Scan DISEMBARK | ❌ **REFUSÉ**  | -              | `blocked`     | "Ticket bloqué"       |

**Code d'implémentation**:

```dart
ValidationResult _validateDisembarking(Ticket ticket) {
  switch (ticket.status) {
    case TicketStatus.boarded:
      // ✅ Cas valide: embarqué → débarquement autorisé
      return ValidationResult.accept(
        verdict: ScanVerdict.valid,
        newStatus: TicketStatus.disembarked,
      );

    case TicketStatus.newTicket:
      // ❌ Erreur d'ordre: doit d'abord embarquer
      return ValidationResult.reject(
        ScanVerdict.orderError,
        'Le passager doit d\'abord embarquer',
      );

    case TicketStatus.disembarked:
      // ❌ Déjà débarqué
      return ValidationResult.reject(
        ScanVerdict.duplicate,
        'Déjà débarqué',
      );

    case TicketStatus.blocked:
      return ValidationResult.reject(
        ScanVerdict.blocked,
        'Ticket bloqué',
      );

    default:
      return ValidationResult.reject(
        ScanVerdict.invalid,
        'Statut invalide',
      );
  }
}
```

### Gestion de l'Expiration

**Tolérance configurable**: L'application accepte une tolérance de 10 minutes après l'heure d'expiration pour tenir compte des retards et des décalages horaires.

```dart
// lib/core/services/validation_service.dart

bool _isExpired(Ticket ticket, AppConfig config) {
  if (ticket.expiresAt == null) return false; // Pas d'expiration définie

  final now = DateTime.now();
  final expiresAt = ticket.expiresAt!;
  final toleranceMinutes = config.expirationToleranceMinutes; // 10 par défaut

  final expiresAtWithTolerance = expiresAt.add(
    Duration(minutes: toleranceMinutes),
  );

  return now.isAfter(expiresAtWithTolerance);
}
```

**Comportement**:

- Si `expiresAt` est `null`: ✅ Pas d'expiration, toujours valide
- Si `now <= expiresAt + 10min`: ✅ Valide (dans la tolérance)
- Si `now > expiresAt + 10min`: ❌ Expiré → Verdict `expired`

**Exemple**:

```
Ticket expiré à: 14h00
Scan à 14h05: ✅ ACCEPTÉ (tolérance +10min)
Scan à 14h09: ✅ ACCEPTÉ (tolérance +10min)
Scan à 14h11: ❌ REFUSÉ (dépassement tolérance)
```

### Énumération des Verdicts

```dart
enum ScanVerdict {
  valid,        // ✅ Scan valide, autorisé
  duplicate,    // ❌ Déjà scanné (BOARDED ou DISEMBARKED)
  expired,      // ❌ Ticket expiré
  blocked,      // ❌ Ticket bloqué
  orderError,   // ❌ Mauvais ordre (DISEMBARK sans BOARD)
  invalid,      // ❌ Autre erreur (format invalide, etc.)
}
```

---

## 🎫 Format des QR Codes

L'application accepte **trois formats** de QR codes pour offrir flexibilité et compatibilité avec différents environnements (production, staging, demo).

### Format 1: JWT Signé RS256 (Production)

**Description**: Format principal pour la production. Le QR code contient un JWT signé avec une clé privée RSA, vérifié par l'application avec la clé publique.

**Structure**:

```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0a3QiOiJUSUNLRVQtMTIzNDUiLCJ0eXAiOiJCQlIiLCJpYXQiOjE3MDYwMDAwMDAsImV4cCI6MTcwNjA4NjQwMCwidiI6IjEifQ.signature...
```

**Payload décodé**:

```json
{
  "tkt": "TICKET-12345", // ✅ OBLIGATOIRE - ID unique du ticket
  "typ": "BBR", // Type de ticket (optionnel, défaut: "BBR")
  "iat": 1706000000, // Timestamp émission (Unix seconds)
  "exp": 1706086400, // Timestamp expiration (Unix seconds)
  "v": "1" // Version du format (optionnel, défaut: "1")
}
```

**Algorithme**: RS256 (RSA Signature with SHA-256)

**Clé publique**: Stockée dans `.env` au format PEM

```env
ENV_PUBLIC_KEY_PEM=-----BEGIN PUBLIC KEY-----\nMIIBIjANBgk...\n-----END PUBLIC KEY-----
```

**Vérification**:

```dart
// lib/core/services/qr_decoder_service.dart

Future<QrPayload?> _tryDecodeJwt(String data) async {
  try {
    final jwt = JWT.verify(
      data,
      RSAPublicKey(_publicKeyPem),
      checkExpiresIn: false, // On gère l'expiration manuellement
      checkNotBefore: false,
    );

    return QrPayload(
      ticketId: jwt.payload['tkt'] as String,
      type: jwt.payload['typ'] as String? ?? 'BBR',
      issuedAt: _parseTimestamp(jwt.payload['iat']),
      expiresAt: _parseTimestamp(jwt.payload['exp']),
      version: jwt.payload['v'] as String? ?? '1',
    );
  } catch (e) {
    _logger.w('JWT decode failed: $e');
    return null;
  }
}
```

**Génération côté serveur** (exemple Node.js):

```javascript
const jwt = require("jsonwebtoken");
const fs = require("fs");

const privateKey = fs.readFileSync("private.pem");

const payload = {
  tkt: "TICKET-12345",
  typ: "BBR",
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 86400, // +24h
  v: "1",
};

const token = jwt.sign(payload, privateKey, { algorithm: "RS256" });
console.log(token); // → Contenu du QR code
```

### Format 2: JSON avec Signature HMAC (Staging)

**Description**: Format intermédiaire pour staging/test. JSON avec signature HMAC-SHA256 séparée.

**Structure**:

```json
{
  "payload": {
    "tkt": "TICKET-67890",
    "typ": "BBR",
    "iat": 1706000000,
    "exp": 1706086400,
    "v": "1"
  },
  "signature": "a3f5e8d9c2b1..."
}
```

**Vérification**:

```dart
Future<QrPayload?> _tryDecodeJsonSignature(String data) async {
  try {
    final json = jsonDecode(data) as Map<String, dynamic>;
    final payload = json['payload'] as Map<String, dynamic>;
    final signature = json['signature'] as String;

    // Vérifier signature HMAC
    final computedSignature = _computeHmac(jsonEncode(payload));
    if (computedSignature != signature) {
      _logger.w('Invalid HMAC signature');
      return null;
    }

    return QrPayload(
      ticketId: payload['tkt'] as String,
      type: payload['typ'] as String? ?? 'BBR',
      issuedAt: _parseTimestamp(payload['iat']),
      expiresAt: _parseTimestamp(payload['exp']),
      version: payload['v'] as String? ?? '1',
    );
  } catch (e) {
    return null;
  }
}
```

### Format 3: JSON Simple (Demo/Test)

**Description**: Format minimal sans signature pour les tests et le mode demo. **Non sécurisé**, utilisé uniquement en développement.

**Structure**:

```json
{
  "tkt": "TEST-001",
  "typ": "BBR",
  "v": "1"
}
```

**Champs minimaux**:

- `tkt`: Obligatoire - ID du ticket
- Tous les autres champs sont optionnels

**Exemples de QR codes de test**:

```json
// Ticket simple valide
{"tkt":"TEST-001","typ":"BBR","v":"1"}

// Ticket avec expiration
{"tkt":"TEST-002","typ":"BBR","exp":1706086400,"v":"1"}

// Ticket avec métadonnées
{"tkt":"TEST-003","typ":"BBR","ctx":"voyage-123","v":"1"}
```

**⚠️ Attention**: Ce format n'est accepté que si `ENV_BUILD_MODE=demo` dans le `.env`. En production, il sera rejeté.

### Classe QrPayload

```dart
// lib/core/services/qr_decoder_service.dart

class QrPayload {
  final String ticketId;          // ID unique du ticket (obligatoire)
  final String type;               // Type de ticket (défaut: 'BBR')
  final DateTime? issuedAt;        // Date d'émission
  final DateTime? expiresAt;       // Date d'expiration
  final String? context;           // Contexte additionnel (voyage, trajet, etc.)
  final String version;            // Version du format (défaut: '1')

  const QrPayload({
    required this.ticketId,
    this.type = 'BBR',
    this.issuedAt,
    this.expiresAt,
    this.context,
    this.version = '1',
  });
}
```

### Génération de QR Codes de Test

Utilisez l'outil fourni pour générer des QR codes de démo:

```bash
dart tools/generate_demo_qr.dart
```

Cela génère des fichiers `.txt` dans `demo_qr_codes/` avec différents scénarios:

- ✅ Ticket nouveau (NEW)
- ✅ Ticket valide
- ❌ Ticket expiré
- ❌ Ticket bloqué
- ❌ Scénarios d'erreur (duplicate, order_error)

Convertissez les `.txt` en QR codes avec un générateur en ligne comme [QR Code Generator](https://www.qr-code-generator.com/).

---

## 🔄 Synchronisation Offline-First

L'architecture de synchronisation garantit que **100% des scans sont enregistrés**, même sans connexion réseau, et synchronisés automatiquement dès que possible.

### Architecture Offline-First

```
┌─────────────────────────────────────────────────┐
│              SCANNER SCREEN                      │
│  (Scan QR → Validation → Enregistrement)        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │   HIVE DATABASE    │
        │  scan_events table │
        │  offline=true      │ ← Tous les scans marqués offline
        └────────┬───────────┘
                 │
                 ▼
        ┌────────────────────┐
        │   SYNC SERVICE     │
        │  Auto-sync 30s     │
        └────────┬───────────┘
                 │
         ┌───────┴────────┐
         │  Réseau OK?    │
         └───┬────────┬───┘
             │        │
         NON │        │ OUI
             │        │
             ▼        ▼
      [Retry Queue]  [POST /scans/bulk]
      Exponentiel         │
      Backoff             ▼
                   ┌──────────────┐
                   │ API Response │
                   └──────┬───────┘
                          │
                   ┌──────┴────────┐
                   │ Marquer synced│
                   │ syncedAt=now  │
                   └───────────────┘
```

### SyncService - Synchronisation Automatique

**Fichier**: `lib/core/services/sync_service.dart`

**Fonctionnalités**:

1. ✅ Auto-sync toutes les 30 secondes
2. ✅ Retry exponentiel en cas d'échec (1s → 3s → 10s → 30s → 5min)
3. ✅ Synchronisation bulk (batch de 50 scans max)
4. ✅ Fallback individuel si bulk échoue
5. ✅ Détection de connexion réseau
6. ✅ Annulation propre lors de logout

```dart
class SyncService {
  final ScanRepository _scanRepo;
  final Dio _httpClient;
  Timer? _autoSyncTimer;
  int _retryCount = 0;

  // Délais de retry exponentiels (millisecondes)
  static const _retryDelays = [1000, 3000, 10000, 30000, 300000];

  /// Démarre la synchronisation automatique toutes les 30 secondes
  void startAutoSync() {
    _logger.i('Starting auto-sync...');
    _autoSyncTimer?.cancel();

    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => syncPendingScans(),
    );

    // Sync immédiat au démarrage
    syncPendingScans();
  }

  /// Stoppe la synchronisation automatique
  void stopAutoSync() {
    _logger.i('Stopping auto-sync');
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Synchronise tous les scans non synchronisés
  Future<void> syncPendingScans() async {
    try {
      // Récupérer tous les scans offline
      final unsyncedScans = await _scanRepo.getUnsyncedScans(limit: 50);

      if (unsyncedScans.isEmpty) {
        _logger.d('No pending scans to sync');
        return;
      }

      _logger.i('Syncing ${unsyncedScans.length} pending scans...');

      // Tentative sync bulk (préféré)
      final bulkSuccess = await _syncBulk(unsyncedScans);

      if (!bulkSuccess) {
        // Fallback: sync individuel
        await _syncIndividual(unsyncedScans);
      }

      // Reset retry count on success
      _retryCount = 0;

    } catch (e, stack) {
      _logger.e('Sync failed: $e', error: e, stackTrace: stack);
      _scheduleRetry();
    }
  }

  /// Synchronisation bulk (batch)
  Future<bool> _syncBulk(List<ScanEvent> scans) async {
    try {
      final response = await _httpClient.post(
        '/scans/bulk',
        data: {
          'scans': scans.map((s) => ScanEventModel.fromEntity(s).toJson()).toList(),
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;

        // Marquer comme synchronisés
        for (var i = 0; i < results.length; i++) {
          final serverData = results[i];
          await _scanRepo.markAsSynced(
            scans[i].id,
            serverVerdict: _parseVerdict(serverData['verdict']),
          );
        }

        _logger.i('✅ Bulk sync successful: ${scans.length} scans');
        return true;
      }

      return false;
    } catch (e) {
      _logger.w('Bulk sync failed, will try individual: $e');
      return false;
    }
  }

  /// Synchronisation individuelle (fallback)
  Future<void> _syncIndividual(List<ScanEvent> scans) async {
    int successCount = 0;

    for (final scan in scans) {
      try {
        final response = await _httpClient.post(
          '/scans',
          data: ScanEventModel.fromEntity(scan).toJson(),
        );

        if (response.statusCode == 201) {
          await _scanRepo.markAsSynced(
            scan.id,
            serverVerdict: _parseVerdict(response.data['verdict']),
          );
          successCount++;
        }
      } catch (e) {
        _logger.w('Failed to sync scan ${scan.id}: $e');
      }
    }

    _logger.i('✅ Individual sync: $successCount/${scans.length} successful');
  }

  /// Planifie un nouveau retry avec backoff exponentiel
  void _scheduleRetry() {
    if (_retryCount >= _retryDelays.length) {
      _retryCount = _retryDelays.length - 1; // Cap au dernier délai
    }

    final delay = Duration(milliseconds: _retryDelays[_retryCount]);
    _retryCount++;

    _logger.i('⏰ Scheduling retry in ${delay.inSeconds}s (attempt $_retryCount)');

    Future.delayed(delay, syncPendingScans);
  }
}
```

### Stratégie de Retry Exponentielle

| Tentative | Délai       | Cas d'usage             |
| --------- | ----------- | ----------------------- |
| 1         | 1 seconde   | Perte réseau temporaire |
| 2         | 3 secondes  | Instabilité réseau      |
| 3         | 10 secondes | Coupure réseau courte   |
| 4         | 30 secondes | Coupure réseau moyenne  |
| 5+        | 5 minutes   | Pas de réseau prolongé  |

**Avantages**:

- ⚡ Rapidité si réseau revient vite (1s)
- 🔋 Économie batterie si pas de réseau (5min max)
- 🔄 Pas de boucle infinie (cap à 5min)

### Résolution de Conflits

**Principe**: Le serveur est **toujours autoritaire** (source of truth).

**Scénario de conflit**:

1. Agent scanne un ticket → validé localement comme `valid`
2. Pendant que le scan est offline, le serveur bloque ce ticket
3. Lors de la sync, le serveur répond `blocked`
4. L'application met à jour le verdict local avec celui du serveur

```dart
Future<void> markAsSynced(String scanId, {ScanVerdict? serverVerdict}) async {
  final box = _hiveService.getScansBox();
  final scan = box.get(scanId);

  if (scan == null) return;

  final synced = scan.copyWith(
    offline: false,
    syncedAt: DateTime.now(),
    verdict: serverVerdict ?? scan.verdict, // ⚠️ Serveur prioritaire!
  );

  await box.put(scanId, synced);
}
```

**Cas pratiques**:

- Ticket expiré après le scan local → serveur corrige en `expired`
- Ticket bloqué manuellement → serveur corrige en `blocked`
- Double scan simultané sur 2 devices → un seul accepté par serveur

### Provider Riverpod pour Statut Sync

```dart
// lib/presentation/providers/app_providers.dart

/// Compte en temps réel des scans non synchronisés
final unsyncedScansCountProvider = StreamProvider<int>((ref) {
  final scanRepo = ref.watch(scanRepositoryProvider);

  return Stream.periodic(const Duration(seconds: 5), (_) async {
    final unsynced = await scanRepo.getUnsyncedScans();
    return unsynced.length;
  }).asyncMap((fn) => fn());
});
```

**Usage dans l'UI**:

```dart
// Afficher badge avec nombre de scans en attente
final unsyncedCount = ref.watch(unsyncedScansCountProvider);

unsyncedCount.when(
  data: (count) => Badge(
    label: Text('$count'),
    child: Icon(Icons.cloud_upload),
  ),
  loading: () => CircularProgressIndicator(),
  error: (_, __) => Icon(Icons.cloud_off),
);
```

---

## 📦 Installation

### Prérequis

- **Flutter SDK**: >= 3.10.1
- **Dart SDK**: >= 3.10.1
- **Android Studio** / **Xcode**: Pour émulateurs
- **Git**: Pour cloner le repository

### Étape 1: Cloner le Repository

```bash
git clone https://github.com/votre-org/bbr_scanner.git
cd bbr_scanner
```

### Étape 2: Installer les Dépendances

```bash
flutter pub get
```

### Étape 3: Configurer l'Environnement

Créer un fichier `.env` à la racine du projet:

```env
# API Configuration
ENV_BASE_URL=https://api.bbr-demo.com/api/v1

# Build Mode (demo | dev | staging | production)
ENV_BUILD_MODE=demo

# Clé publique RSA pour vérification JWT (format PEM sur une ligne)
ENV_PUBLIC_KEY_PEM=-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----
```

**⚠️ Important**: Remplacez `ENV_PUBLIC_KEY_PEM` par votre véritable clé publique RSA.

### Étape 4: Générer les Fichiers Hive

Les adaptateurs Hive sont pré-générés, mais si vous modifiez les models, régénérez avec:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Étape 5: Lancer l'Application

#### Sur Émulateur Android

```bash
flutter run
```

#### Sur Émulateur iOS (macOS uniquement)

```bash
open -a Simulator  # Ouvrir le simulateur
flutter run
```

#### Sur Device Physique

```bash
flutter devices  # Lister les devices connectés
flutter run -d <device-id>
```

### Étape 6: Build de Production

#### Android APK

```bash
flutter build apk --release
```

📦 Fichier généré: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (Google Play)

```bash
flutter build appbundle --release
```

📦 Fichier généré: `build/app/outputs/bundle/release/app-release.aab`

#### iOS (macOS + compte Apple Developer)

```bash
flutter build ios --release
```

### Configuration Spécifique Android

#### Permissions dans `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Caméra pour scanner QR -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Internet pour sync -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Détection réseau -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Vibration pour feedback -->
    <uses-permission android:name="android.permission.VIBRATE" />
</manifest>
```

#### Signature APK

Pour signer l'APK de production, créez `android/key.properties`:

```properties
storePassword=<votre-mot-de-passe>
keyPassword=<votre-mot-de-passe>
keyAlias=bbr-scanner
storeFile=<chemin-vers-votre-keystore.jks>
```

### Configuration Spécifique iOS

#### Permissions dans `ios/Runner/Info.plist`

```xml
<dict>
    <!-- Description caméra -->
    <key>NSCameraUsageDescription</key>
    <string>L'application a besoin d'accéder à la caméra pour scanner les QR codes des tickets.</string>
</dict>
```

---

## 🚀 Utilisation

### Premier Lancement

1. **Connexion**: Entrez vos identifiants d'agent
   - Email: Votre email d'agent
   - Mot de passe: Votre mot de passe

2. **Sélection du Point de Contrôle**:
   - **EMBARQUEMENT**: Pour scanner à l'entrée du bateau
   - **DÉBARQUEMENT**: Pour scanner à la sortie du bateau

3. **Scanner**: Pointez la caméra vers le QR code du ticket
   - ✅ Flash vert + vibration → Ticket accepté
   - ❌ Flash rouge + vibration → Ticket refusé

### Mode Démo (Sans Serveur)

Pour tester l'application sans serveur backend:

1. Configurez `.env` avec `ENV_BUILD_MODE=demo`
2. Connexion: **N'importe quel email/mot de passe fonctionne**
3. Générez des QR codes de test:

```bash
dart tools/generate_demo_qr.dart
```

4. Scannez les QR codes générés dans `demo_qr_codes/`

### Workflow Typique Agent

```
1. Ouverture app → Auto-login (token sauvegardé)
2. Sélection EMBARQUEMENT
3. Scan tickets passagers (N scans)
4. Changement vers DÉBARQUEMENT
5. Scan tickets passagers (N scans)
6. Fermeture app → Auto-sync en arrière-plan
```

### Accès aux Statistiques

- **Écran d'accueil**: Nombre total de scans effectués
- **Badge de sync**: Nombre de scans en attente de synchronisation
- **Paramètres**: Détails utilisateur, mode sombre, version

### Gestion de l'Authentification

**Tokens JWT**:

- `accessToken`: Valide 15 minutes, utilisé pour toutes les API
- `refreshToken`: Valide 7 jours, utilisé pour renouveler l'access token

**Refresh automatique**:

```dart
// lib/core/services/auth_service.dart

// L'interceptor Dio renouvelle automatiquement le token si 401
_dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      final newToken = await refreshAccessToken();
      // Retry la requête avec le nouveau token
    }
  },
));
```

---

## 🧪 Tests

### Tests Unitaires

#### Lancer tous les tests

```bash
flutter test
```

#### Lancer un test spécifique

```bash
flutter test test/validation_service_test.dart
```

#### Tests avec coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Tests Disponibles

#### 1. ValidationService Tests

**Fichier**: `test/validation_service_test.dart`

**Couverture**:

- ✅ Règles d'embarquement (BOARD)
- ✅ Règles de débarquement (DISEMBARK)
- ✅ Gestion expiration avec tolérance
- ✅ Transitions de statuts
- ✅ Cas limites (edge cases)

**Exemple de test**:

```dart
test('BOARD: NEW ticket should be accepted and marked as BOARDED', () {
  final ticket = Ticket(
    id: 'TEST-001',
    code: 'TEST-001',
    status: TicketStatus.newTicket,
  );

  final result = validationService.validateScan(
    ticket: ticket,
    scanType: ScanType.board,
    config: appConfig,
  );

  expect(result.isValid, true);
  expect(result.verdict, ScanVerdict.valid);
  expect(result.newStatus, TicketStatus.boarded);
});
```

### Tests Manuels avec QR Codes

#### Générer des QR Codes de Test

```bash
dart tools/generate_demo_qr.dart
```

Cela génère des fichiers `.txt` dans `demo_qr_codes/` :

- ✅ `01_valid_new_ticket.txt` → Ticket NEW valide
- ✅ `02_valid_boarded_ticket.txt` → Ticket BOARDED valide
- ❌ `03_expired_ticket.txt` → Ticket expiré
- ❌ `04_duplicate_board.txt` → Test duplicate
- ❌ `05_order_error.txt` → Test erreur d'ordre

#### Convertir en QR Images

Utilisez un générateur en ligne:

1. Allez sur [QR Code Generator](https://www.qr-code-generator.com/)
2. Copiez le contenu du fichier `.txt`
3. Générez le QR code
4. Scannez avec l'app

### Tests d'Intégration (Recommandé)

Pour tester le flow complet:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

**⚠️ Note**: Les tests d'intégration nécessitent un device/émulateur démarré.

---

## 🔒 Sécurité

### Stockage Sécurisé des Tokens

**Keychain (iOS) / Keystore (Android)**:

```dart
// lib/core/storage/secure_storage_service.dart

class SecureStorageService {
  final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }
}
```

**⚠️ Jamais de tokens en SharedPreferences** (non sécurisé)

### Vérification Signature QR

**RS256 (Asymétrique)**:

- Serveur signe avec clé privée RSA (2048 bits minimum)
- App vérifie avec clé publique (dans `.env`)
- Impossible de forger un QR sans la clé privée

```dart
final jwt = JWT.verify(
  qrData,
  RSAPublicKey(publicKeyPem),
  checkExpiresIn: false,
);
```

### HTTPS Obligatoire

Toutes les requêtes API utilisent HTTPS:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.bbr-demo.com/api/v1', // ✅ HTTPS
));
```

**⚠️ Désactiver HTTP en production** dans `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="false">
```

### Anti-Spam: Debounce de Scan

Empêche les scans rapides multiples:

```dart
DateTime? _lastScanTime;
static const _scanDebounce = Duration(seconds: 1);

void _onQrDetected(String data) {
  final now = DateTime.now();

  if (_lastScanTime != null &&
      now.difference(_lastScanTime!) < _scanDebounce) {
    return; // ❌ Ignore scan trop rapide
  }

  _lastScanTime = now;
  _processScan(data); // ✅ Traite le scan
}
```

### Logs sans Données Sensibles

```dart
// ❌ MAUVAIS
_logger.i('Access token: $accessToken');

// ✅ BON
_logger.i('Access token saved successfully');
```

### Obfuscation du Code (Production)

Build avec obfuscation pour Android/iOS:

```bash
flutter build apk --obfuscate --split-debug-info=build/debug-info
flutter build ios --obfuscate --split-debug-info=build/debug-info
```

---

## 🛠️ Troubleshooting

### Problème: L'app ne démarre pas

**Symptômes**: Écran blanc ou crash au lancement

**Solutions**:

1. Vérifier `.env` existe et est bien formaté
2. Vérifier Flutter SDK version:

```bash
flutter doctor -v
```

3. Nettoyer et rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

### Problème: Scanner QR ne détecte rien

**Symptômes**: Caméra affichée mais pas de scan

**Solutions**:

1. Vérifier permissions caméra accordées (Settings → App → Permissions)
2. Tester avec QR imprimé (pas écran)
3. Vérifier luminosité suffisante
4. Sur Android: vérifier `mobile_scanner` compatible (API 21+)
5. Logs:

```bash
flutter logs | grep -i camera
```

### Problème: Scans ne se synchronisent pas

**Symptômes**: Badge "scans en attente" ne diminue pas

**Solutions**:

1. Vérifier connexion réseau:

```dart
final connectivityResult = await Connectivity().checkConnectivity();
print(connectivityResult); // wifi, mobile, none
```

2. Vérifier URL API dans `.env`:

```env
ENV_BASE_URL=https://api.bbr-demo.com/api/v1  # ✅ Correct
# ENV_BASE_URL=http://localhost:3000          # ❌ Faux en prod
```

3. Vérifier logs du SyncService:

```bash
flutter logs | grep -i sync
```

4. Forcer sync manuelle:

```dart
ref.read(syncServiceProvider).syncPendingScans();
```

### Problème: JWT invalide

**Symptômes**: Erreur "JWT verification failed"

**Solutions**:

1. Vérifier clé publique dans `.env` correcte:

```bash
# La clé doit matcher la clé privée serveur
ENV_PUBLIC_KEY_PEM=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
```

2. Vérifier format JWT (3 parties séparées par `.`):

```
header.payload.signature
```

3. Décoder JWT pour debug: [jwt.io](https://jwt.io/)
4. Mode demo: Mettre `ENV_BUILD_MODE=demo` pour accepter JSON simple

### Problème: Hive BoxNotFound

**Symptômes**: Error "Box not found: tickets"

**Solutions**:

1. Vérifier initialisation Hive dans `main.dart`:

```dart
await HiveService().init(); // ✅ Doit être appelé avant runApp
```

2. Supprimer Hive boxes corrompues:

```bash
# Android
adb shell run-as com.bbr.scanner rm -rf /data/data/com.bbr.scanner/app_flutter/hive

# iOS
xcrun simctl get_app_container booted com.bbr.scanner data
# Supprimer manuellement le dossier hive
```

3. Rebuild:

```bash
flutter clean && flutter run
```

### Problème: Type Cast Error

**Symptômes**: "type 'Ticket' is not a subtype of type 'TicketModel'"

**Solutions**:

1. Vérifier que les models ont `@override copyWith` retournant le bon type:

```dart
// ❌ MAUVAIS (retourne Ticket)
Ticket copyWith({...}) => Ticket(...);

// ✅ BON (retourne TicketModel)
@override
TicketModel copyWith({...}) => TicketModel(...);
```

2. Rebuild les adapters Hive:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Logs Détaillés

Activer logs détaillés pour debug:

```dart
// lib/main.dart

final logger = Logger(
  level: Level.verbose, // ✅ Tous les logs (dev)
  // level: Level.info,  // Production
);
```

### Ressources Utiles

- **Documentation Flutter**: [flutter.dev](https://flutter.dev/docs)
- **Riverpod Docs**: [riverpod.dev](https://riverpod.dev)
- **Hive Docs**: [docs.hivedb.dev](https://docs.hivedb.dev)
- **mobile_scanner**: [pub.dev/packages/mobile_scanner](https://pub.dev/packages/mobile_scanner)

---

## 📄 Licence

Copyright © 2024 BBR Scanner. Tous droits réservés.

---

## 👥 Contributeurs

- **Développeur Principal**: [Votre Nom]
- **Architecture**: Clean Architecture + Riverpod
- **Design**: Material Design 3

---

## 📞 Support

Pour toute question ou problème:

- 📧 Email: support@bbr-scanner.com
- 🐛 Issues: [GitHub Issues](https://github.com/votre-org/bbr_scanner/issues)
- 📚 Wiki: [Documentation complète](https://github.com/votre-org/bbr_scanner/wiki)
