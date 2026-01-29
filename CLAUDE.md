# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BBR Scanner** is a production-ready Flutter mobile application for ticket validation at boarding and disembarking control points. The app features offline-first architecture with automatic synchronization, QR code scanning with business rule validation, and secure JWT token management.

## Common Commands

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with hot reload enabled (default)
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format all Dart files
dart format .

# Fix auto-fixable lint issues
dart fix --apply
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build iOS (requires macOS)
flutter build ios

# Build App Bundle for Google Play
flutter build appbundle
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Show outdated dependencies
flutter pub outdated
```

### Demo & Testing
```bash
# Generate demo QR codes
dart tools/generate_demo_qr.dart

# Run validation tests
flutter test test/validation_service_test.dart
```

## Project Structure & Architecture

The app follows **Clean Architecture** with clear separation of concerns:

```
lib/
├── core/                           # Infrastructure layer
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants
│   │   └── enums.dart             # ScanType, TicketStatus, ScanVerdict, etc.
│   ├── services/
│   │   ├── auth_service.dart      # Authentication (login, logout, token refresh)
│   │   ├── sync_service.dart      # Offline sync with retry policy
│   │   ├── validation_service.dart # Business rules validation
│   │   └── qr_decoder_service.dart # QR code decoding & JWT verification
│   └── storage/
│       ├── database_service.dart   # SQLite database management
│       └── secure_storage_service.dart # Keychain/Keystore wrapper
├── data/                           # Data layer
│   ├── models/
│   │   ├── user_model.dart        # JSON-serializable models
│   │   ├── ticket_model.dart
│   │   └── scan_event_model.dart
│   └── repositories/
│       ├── user_repository.dart    # User CRUD operations
│       ├── ticket_repository.dart  # Ticket CRUD operations
│       └── scan_repository.dart    # Scan event CRUD + sync queries
├── domain/                         # Domain layer
│   └── entities/
│       ├── user.dart              # Pure domain entities
│       ├── ticket.dart
│       ├── scan_event.dart
│       ├── device.dart
│       └── app_config.dart
├── presentation/                   # Presentation layer
│   ├── providers/
│   │   └── app_providers.dart     # Riverpod providers & state notifiers
│   ├── auth/
│   │   └── login_screen.dart      # Authentication UI
│   ├── scanner/
│   │   ├── scan_point_selection_screen.dart
│   │   ├── scanner_screen.dart    # QR scanner with mobile_scanner
│   │   └── scan_result_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── main.dart                       # App entry point

test/
└── validation_service_test.dart    # Business rules unit tests

tools/
└── generate_demo_qr.dart          # Demo QR code generator
```

## Architecture Patterns

### State Management: Riverpod

All state is managed through Riverpod providers:

- **Services**: `authServiceProvider`, `syncServiceProvider`, `validationServiceProvider`
- **Repositories**: `scanRepositoryProvider`, `ticketRepositoryProvider`, `userRepositoryProvider`
- **State Notifiers**: `currentUserProvider`, `appConfigProvider`, `selectedScanPointProvider`, `darkModeProvider`
- **Streams**: `unsyncedScansCountProvider` (for real-time sync status)

### Database: SQLite

Three main tables:
- `user`: Single user session (id, name, email, role)
- `tickets`: Ticket cache (id, code, status, expiresAt, meta)
- `scan_events`: Scan history (id, ticketId, scanType, timestamp, verdict, syncedAt)

### Offline-First Sync

1. All scans saved to SQLite immediately with `offline=true`
2. Auto-sync every 30 seconds via `SyncService`
3. Retry policy: 1s → 3s → 10s → 30s → 5min (exponential backoff)
4. Bulk sync API (`POST /scans/bulk`) with fallback to individual sync
5. Server verdict is authoritative in case of conflicts

## Business Rules (Critical)

### Boarding (BOARD)
- `NEW` ticket → ✅ Accept → `BOARDED`
- `BOARDED` → ❌ Reject (duplicate)
- `DISEMBARKED` → ❌ Reject (duplicate)
- `EXPIRED` (outside tolerance) → ❌ Reject
- `BLOCKED` → ❌ Reject

### Disembarking (DISEMBARK)
- `BOARDED` → ✅ Accept → `DISEMBARKED`
- `NEW` (not boarded yet) → ❌ Reject (order_error)
- `DISEMBARKED` → ❌ Reject (duplicate)
- `EXPIRED` → ❌ Reject
- `BLOCKED` → ❌ Reject

**Expiration Tolerance**: 10 minutes (configurable in AppConfig)

## Key Technologies

- **State Management**: Riverpod 2.6.1 (StateNotifier, FutureProvider, StreamProvider)
- **Database**: sqflite 2.3.3 + path
- **Secure Storage**: flutter_secure_storage 9.2.2 (Android Keystore / iOS Keychain)
- **QR Scanner**: mobile_scanner 5.2.3 (ML Kit / AVFoundation)
- **HTTP**: Dio 5.7.0 with interceptors
- **JWT**: dart_jsonwebtoken 2.14.1 (RS256 signature verification)
- **Connectivity**: connectivity_plus 6.1.1
- **Haptic Feedback**: vibration 2.0.0

## Environment Configuration

The app uses a `.env` file for configuration:

```env
ENV_BASE_URL=https://api.bbr-demo.com/api/v1
ENV_BUILD_MODE=demo  # demo, dev, staging, production
ENV_PUBLIC_KEY_PEM=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
```

**Demo Mode**: When `ENV_BUILD_MODE=demo`:
- Any email/password works for login
- Sync is simulated locally (no real API calls)
- QR codes without valid signature are accepted

## Development Workflow

### Adding a New Screen

1. Create screen file in `lib/presentation/<feature>/`
2. Use `ConsumerStatefulWidget` or `ConsumerWidget`
3. Watch providers with `ref.watch()`, read with `ref.read()`
4. Navigate with `Navigator.push()` or `Navigator.pushReplacement()`

### Adding Business Logic

1. Create service in `lib/core/services/`
2. Create provider in `lib/presentation/providers/app_providers.dart`
3. Inject via constructor and wire up in provider
4. Write unit tests in `test/`

### Database Changes

1. Update `_onCreate()` in `database_service.dart`
2. Increment `databaseVersion` constant
3. Implement migration in `_onUpgrade()` if needed

## Testing

### Unit Tests
- Location: `test/`
- Run: `flutter test`
- Focus: Business rules in `ValidationService`

### Manual Testing with Demo QR Codes
1. Generate: `dart tools/generate_demo_qr.dart`
2. Check `demo_qr_codes/MANIFEST.md` for scenarios
3. Convert `.txt` files to QR images with online generator
4. Scan with app in demo mode

## Common Patterns

### Reading from Database
```dart
final scanRepo = ref.read(scanRepositoryProvider);
final scans = await scanRepo.getScans(limit: 50);
```

### Updating State
```dart
ref.read(selectedScanPointProvider.notifier).setScanPoint(ScanType.board);
```

### Navigation with Data
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ScanResultScreen(ticket: ticket, scanEvent: event),
  ),
);
```

### Showing Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Synchronized'), backgroundColor: Colors.green),
);
```

## Security Considerations

- JWT tokens stored in secure storage (never in SharedPreferences)
- QR signature verification with RS256
- HTTPS enforced for all API calls
- 1-second debounce between scans to prevent rapid duplicate scans
- No sensitive data in logs (use logger levels appropriately)

## Troubleshooting

### "Target of URI doesn't exist" errors
The generated `.g.dart` files are placeholders. Run `flutter pub get` to resolve.

### Scanner not detecting QR codes
- Ensure camera permissions granted
- Test with printed QR (not screen display)
- Check lighting conditions
- Verify QR format matches expected payload structure

### Sync failures
- Check network connectivity
- Verify `ENV_BASE_URL` in `.env`
- In demo mode, sync is simulated (always succeeds)
- Check logs for retry attempts

## API Contract (Reference)

### Authentication
- `POST /auth/login` → `{accessToken, refreshToken, user}`
- `POST /auth/refresh` → `{accessToken}`

### Scans
- `POST /scans` → Single scan submission
- `POST /scans/bulk` → Batch sync (preferred)
- `GET /tickets/{id}/status` → Ticket status check

### QR Payload Format
```json
{
  "tkt": "ticket-id",
  "typ": "BBR",
  "iat": 1234567890,
  "exp": 1234567890,
  "v": "1"
}
```

Signed as JWT (RS256) or JSON+HMAC signature.
