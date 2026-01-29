import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/validation_service.dart';
import '../../core/services/qr_decoder_service.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/app_config.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/app_constants.dart';

// === Services ===

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// === Repositories ===

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return ScanRepository(database);
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return TicketRepository(database);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return UserRepository(database);
});

// === Business Logic Services ===

final authServiceProvider = Provider<AuthService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthService(secureStorage, userRepository);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final scanRepository = ref.watch(scanRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return SyncService(scanRepository, secureStorage);
});

final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService();
});

final qrDecoderServiceProvider = Provider<QrDecoderService>((ref) {
  return QrDecoderService();
});

// === State Management ===

/// État de l'utilisateur connecté
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((
  ref,
) {
  final userRepository = ref.watch(userRepositoryProvider);
  return CurrentUserNotifier(userRepository);
});

class CurrentUserNotifier extends StateNotifier<User?> {
  final UserRepository _userRepository;

  CurrentUserNotifier(this._userRepository) : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = await _userRepository.getUser();
  }

  Future<void> setUser(User user) async {
    await _userRepository.saveUser(user);
    state = user;
  }

  Future<void> clearUser() async {
    await _userRepository.deleteUser();
    state = null;
  }

  Future<void> refresh() async {
    state = await _userRepository.getUser();
  }
}

/// Configuration de l'application
final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((
  ref,
) {
  return AppConfigNotifier();
});

class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(AppConfig.defaultConfig());

  void updateConfig(AppConfig config) {
    state = config;
  }

  void updateScanWindowTolerance(int seconds) {
    state = state.copyWith(scanWindowToleranceSec: seconds);
  }

  void updateRequireGeo(bool require) {
    state = state.copyWith(requireGeo: require);
  }

  void toggleFeatureFlag(String featureName, bool enabled) {
    final updatedFlags = Map<String, bool>.from(state.featureFlags ?? {});
    updatedFlags[featureName] = enabled;
    state = state.copyWith(featureFlags: updatedFlags);
  }
}

/// Point de scan sélectionné (Embarquement/Débarquement)
final selectedScanPointProvider =
    StateNotifierProvider<SelectedScanPointNotifier, ScanType>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SelectedScanPointNotifier(prefs);
    });

class SelectedScanPointNotifier extends StateNotifier<ScanType> {
  final AsyncValue<SharedPreferences> _prefsAsync;

  SelectedScanPointNotifier(this._prefsAsync) : super(ScanType.board) {
    _loadSavedScanPoint();
  }

  Future<void> _loadSavedScanPoint() async {
    _prefsAsync.whenData((prefs) {
      final saved = prefs.getString(AppConstants.keySelectedScanPoint);
      if (saved != null) {
        state = ScanType.fromString(saved);
      }
    });
  }

  Future<void> setScanPoint(ScanType scanType) async {
    state = scanType;
    await _prefsAsync.whenData((prefs) {
      prefs.setString(AppConstants.keySelectedScanPoint, scanType.value);
    });
  }
}

/// Mode sombre
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DarkModeNotifier(prefs);
});

class DarkModeNotifier extends StateNotifier<bool> {
  final AsyncValue<SharedPreferences> _prefsAsync;

  DarkModeNotifier(this._prefsAsync) : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    _prefsAsync.whenData((prefs) {
      state = prefs.getBool(AppConstants.keyDarkMode) ?? false;
    });
  }

  Future<void> toggle() async {
    state = !state;
    await _prefsAsync.whenData((prefs) {
      prefs.setBool(AppConstants.keyDarkMode, state);
    });
  }
}

/// État d'authentification
final authStateProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isAuthenticated();
});

/// Nombre de scans non synchronisés
final unsyncedScansCountProvider = StreamProvider<int>((ref) async* {
  final scanRepository = ref.watch(scanRepositoryProvider);

  // Émettre la valeur initiale
  final unsynced = await scanRepository.getUnsyncedScans();
  yield unsynced.length;

  // Puis réémettre toutes les 5 secondes
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    final unsynced = await scanRepository.getUnsyncedScans();
    yield unsynced.length;
  }
});
