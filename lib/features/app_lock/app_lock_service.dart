import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-local app lock configuration — PIN, pattern and biometric toggle
/// each work independently, mirroring the localStorage-backed AppLockGate.tsx
/// and the App Lock section of settings.tsx. Uses secure storage instead of
/// localStorage since Flutter has a real encrypted keystore available.
class AppLockService {
  AppLockService(this._storage);
  final FlutterSecureStorage _storage;

  static const _pinKey = 'mp_lock_pin';
  static const _patternKey = 'mp_lock_pattern';
  static const _bioKey = 'mp_lock_bio';

  Future<String?> getPin() => _storage.read(key: _pinKey);
  Future<void> setPin(String pin) => _storage.write(key: _pinKey, value: pin);
  Future<void> removePin() => _storage.delete(key: _pinKey);

  Future<String?> getPattern() => _storage.read(key: _patternKey);
  Future<void> setPattern(List<int> pattern) => _storage.write(key: _patternKey, value: pattern.join(','));
  Future<void> removePattern() => _storage.delete(key: _patternKey);

  Future<bool> getBiometricEnabled() async => (await _storage.read(key: _bioKey)) == '1';
  Future<void> setBiometricEnabled(bool enabled) => enabled ? _storage.write(key: _bioKey, value: '1') : _storage.delete(key: _bioKey);

  Future<bool> get isConfigured async {
    final pin = await getPin();
    final pattern = await getPattern();
    final bio = await getBiometricEnabled();
    return pin != null || pattern != null || bio;
  }
}

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(const FlutterSecureStorage());
});

/// Whether the app has been unlocked for this process lifetime. Mirrors the
/// sessionStorage("mp_unlocked") semantics — resets whenever the app cold-starts.
final appUnlockedProvider = StateProvider<bool>((ref) => false);

/// Recomputed each time the lock sheet in Settings mutates PIN/pattern/bio —
/// bump this to force AppLockGate to re-check whether a lock is configured.
final appLockRefreshProvider = StateProvider<int>((ref) => 0);

final appLockConfiguredProvider = FutureProvider.autoDispose<bool>((ref) async {
  ref.watch(appLockRefreshProvider);
  final service = ref.watch(appLockServiceProvider);
  return service.isConfigured;
});
