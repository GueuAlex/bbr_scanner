# BBR Scanner

Application mobile Flutter de contrôle des tickets pour le système BBR (Bateau de transport).

## 📱 Vue d'ensemble

BBR Scanner est une application mobile de scan de QR codes pour la validation de tickets aux points d'embarquement et de débarquement. L'application fonctionne en mode hors-ligne avec synchronisation automatique.

### Fonctionnalités principales

- ✅ **Authentification sécurisée** avec stockage chiffré des tokens
- 📸 **Scanner QR code** haute performance avec validation en temps réel
- 🔄 **Mode hors-ligne** avec file d'attente et synchronisation automatique
- 🎯 **Deux points de contrôle**: Embarquement et Débarquement
- 📊 **Validation métier** avec règles anti-fraude
- 🔐 **Vérification des signatures** JWT pour les QR codes
- 🌙 **Mode sombre** et interface Material Design 3
- 📱 **Support Android et iOS**

## 🏗️ Architecture

L'application suit une architecture **Clean Architecture** avec séparation claire des couches:

```
lib/
├── core/                    # Couche infrastructure
│   ├── constants/          # Constantes et énumérations
│   ├── services/           # Services métier (Validation, QR, Auth, Sync)
│   └── storage/            # Base de données et stockage sécurisé
├── data/                    # Couche données
│   ├── models/             # Modèles JSON serializable
│   └── repositories/       # Repositories (Tickets, Scans, User)
├── domain/                  # Couche domaine
│   └── entities/           # Entités métier
└── presentation/            # Couche présentation
    ├── auth/               # Écrans d'authentification
    ├── scanner/            # Écrans de scan
    ├── settings/           # Écrans de paramètres
    └── providers/          # Providers Riverpod
```

### Technologies utilisées

- **Framework**: Flutter 3.10.1+
- **State Management**: Riverpod 2.6.1
- **Base de données**: SQLite (sqflite)
- **Sécurité**: flutter_secure_storage (Android Keystore / iOS Keychain)
- **Scanner QR**: mobile_scanner 5.2.3
- **HTTP**: Dio 5.7.0
- **JWT**: dart_jsonwebtoken 2.14.1

## 🚀 Installation

### Prérequis

- Flutter SDK 3.10.1 ou supérieur
- Dart SDK 3.10.1 ou supérieur
- Android Studio / Xcode (pour build Android/iOS)
- Un éditeur (VS Code, Android Studio, etc.)

### Setup du projet

```bash
# Cloner le repository
git clone <repository-url>
cd bbr_scanner

# Installer les dépendances
flutter pub get

# Vérifier l'installation
flutter doctor

# Configurer les variables d'environnement
# Éditer le fichier .env à la racine du projet
```

### Configuration de l'environnement (.env)

Le fichier `.env` contient les variables de configuration:

```env
# API Backend
ENV_BASE_URL=https://api.bbr-demo.com/api/v1

# JWT
ENV_JWT_ISSUER=bbr-system
ENV_JWT_AUDIENCE=bbr-scanner

# Clé publique pour vérification signature QR (format PEM)
ENV_PUBLIC_KEY_PEM=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----

# Mode de build
ENV_BUILD_MODE=demo  # dev, staging, demo, production
```

**Note**: En mode `demo`, l'authentification et la synchronisation sont simulées localement.

## 🎮 Utilisation

### Lancer l'application

```bash
# Mode debug (hot reload activé)
flutter run

# Mode release
flutter run --release

# Sur un device spécifique
flutter devices
flutter run -d <device-id>
```

### Compte de démo

En mode `demo`, vous pouvez utiliser n'importe quel email/mot de passe pour vous connecter.

Exemples:
- Email: `agent@bbr.com`
- Mot de passe: `demo123`

### Générer des QR codes de test

```bash
# Générer 10 QR codes de test
dart tools/generate_demo_qr.dart

# Les QR codes sont générés dans demo_qr_codes/
# Consultez demo_qr_codes/MANIFEST.md pour les détails
```

Les QR codes de test incluent:
1. **Ticket valide** - peut être embarqué
2. **Ticket déjà embarqué** - sera refusé (duplicate)
3. **Ticket déjà débarqué** - sera refusé (duplicate)
4. **Ticket expiré** - sera refusé (expiré)
5. **Ticket bloqué** - sera refusé (bloqué)
6-10. **Tickets de test** - pour scénarios multiples

### Workflow typique

1. **Connexion** avec email/mot de passe
2. **Sélection du point** de contrôle (Embarquement ou Débarquement)
3. **Scanner le QR code** du ticket
4. **Validation** automatique selon les règles métier
5. **Affichage du résultat** (Valide ✅ ou Invalide ❌)
6. **Synchronisation** automatique en arrière-plan

## 📋 Règles métier

### Règles d'Embarquement (BOARD)

| Statut ticket | Résultat | Nouveau statut |
|--------------|----------|----------------|
| `NEW` (nouveau) | ✅ **Accepté** | `BOARDED` |
| `BOARDED` (déjà embarqué) | ❌ Refusé (duplicate) | - |
| `DISEMBARKED` (déjà débarqué) | ❌ Refusé (duplicate) | - |
| `EXPIRED` (expiré) | ❌ Refusé (expiré) | - |
| `BLOCKED` (bloqué) | ❌ Refusé (bloqué) | - |

### Règles de Débarquement (DISEMBARK)

| Statut ticket | Résultat | Nouveau statut |
|--------------|----------|----------------|
| `NEW` (pas encore embarqué) | ❌ Refusé (order error) | - |
| `BOARDED` (embarqué) | ✅ **Accepté** | `DISEMBARKED` |
| `DISEMBARKED` (déjà débarqué) | ❌ Refusé (duplicate) | - |
| `EXPIRED` (expiré) | ❌ Refusé (expiré) | - |
| `BLOCKED` (bloqué) | ❌ Refusé (bloqué) | - |

### Tolérance d'expiration

Par défaut, une **tolérance de 10 minutes** est appliquée après l'expiration du ticket. Configurable dans les paramètres.

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Lancer un test spécifique
flutter test test/validation_service_test.dart

# Tests avec couverture
flutter test --coverage
```

### Tests disponibles

- ✅ Tests unitaires des règles de validation (`validation_service_test.dart`)
- Tests des scénarios d'embarquement
- Tests des scénarios de débarquement
- Tests de tolérance d'expiration

## 🔧 Build

### Android

```bash
# Build APK (debug)
flutter build apk

# Build APK (release)
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release
```

Le fichier APK se trouve dans `build/app/outputs/flutter-apk/`.

### iOS

```bash
# Build iOS (nécessite macOS)
flutter build ios --release

# Ou via Xcode
open ios/Runner.xcworkspace
```

## 📊 Synchronisation hors-ligne

### Comment ça fonctionne

1. **Scans en local**: Tous les scans sont enregistrés en SQLite immédiatement
2. **File d'attente**: Les scans non synchronisés sont marqués avec `offline=true`
3. **Sync automatique**: Toutes les 30 secondes, tentative de synchronisation
4. **Retry policy**: Retry exponentiel (1s, 3s, 10s, 30s, 5min)
5. **Résolution conflits**: Le verdict du serveur fait autorité

### Indicateurs

- **Badge de synchronisation**: Affiche le nombre de scans en attente
- **Bouton force sync**: Synchronisation immédiate manuelle
- **Logs**: Toutes les tentatives sont journalisées

## 🔐 Sécurité

- ✅ Tokens JWT stockés dans le Keychain/Keystore
- ✅ Vérification de signature des QR codes (RS256)
- ✅ HTTPS obligatoire pour les appels API
- ✅ Debounce de 1 seconde entre scans
- ✅ Logs sans données sensibles
- ⚠️ TODO: Certificate pinning (facultatif)
- ⚠️ TODO: Play Integrity / SafetyNet

## 📱 Permissions

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>L'application a besoin de la caméra pour scanner les QR codes</string>
```

## 🐛 Troubleshooting

### Problèmes courants

**1. Erreur: "Target of URI doesn't exist"**
```bash
flutter pub get
flutter clean
flutter pub get
```

**2. Erreur de build Android**
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

**3. SQLite database locked**
```bash
# Désinstaller l'app et réinstaller
flutter clean
flutter run
```

**4. Scanner ne détecte pas les QR codes**
- Vérifier les permissions caméra
- Tester avec un QR code imprimé (pas sur écran)
- Vérifier l'éclairage

## 📚 Ressources

- [Documentation Flutter](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Mobile Scanner Package](https://pub.dev/packages/mobile_scanner)
- [Sqflite Package](https://pub.dev/packages/sqflite)

## 🤝 Contribution

Ce projet est en développement actif. Pour contribuer:

1. Fork le repository
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📄 Licence

Propriétaire - Tous droits réservés © 2026 BBR

## 👥 Contact

Pour toute question ou support, contactez l'équipe de développement BBR.

---

**Version**: 1.0.0
**Dernière mise à jour**: Janvier 2026
**Status**: MVP - Démo fonctionnelle
