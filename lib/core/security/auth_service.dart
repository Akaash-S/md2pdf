import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _pinKey = 'app_pin_hash';
  static const _attemptsKey = 'failed_attempts';
  static const _lockoutKey = 'lockout_until';
  static const int maxAttempts = 5;
  static const int lockoutMinutes = 5;

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access MD2PDF',
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinKey, value: hash);
    await _resetAttempts();
  }

  Future<bool> verifyPin(String pin) async {
    if (await _isLockedOut()) return false;

    final storedHash = await _secureStorage.read(key: _pinKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = inputHash == storedHash;

    if (isValid) {
      await _resetAttempts();
    } else {
      await _incrementAttempts();
    }

    return isValid;
  }

  Future<bool> _isLockedOut() async {
    final lockoutStr = await _secureStorage.read(key: _lockoutKey);
    if (lockoutStr == null) return false;
    final lockoutUntil = DateTime.parse(lockoutStr);
    return DateTime.now().isBefore(lockoutUntil);
  }

  Future<Duration?> getLockoutRemaining() async {
    final lockoutStr = await _secureStorage.read(key: _lockoutKey);
    if (lockoutStr == null) return null;
    final lockoutUntil = DateTime.parse(lockoutStr);
    final remaining = lockoutUntil.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<int> getFailedAttempts() async {
    final att = await _secureStorage.read(key: _attemptsKey);
    return int.tryParse(att ?? '0') ?? 0;
  }

  Future<void> _incrementAttempts() async {
    final current = await getFailedAttempts();
    final next = current + 1;
    await _secureStorage.write(key: _attemptsKey, value: next.toString());

    if (next >= maxAttempts) {
      final lockoutUntil =
          DateTime.now().add(const Duration(minutes: lockoutMinutes));
      await _secureStorage.write(
          key: _lockoutKey, value: lockoutUntil.toIso8601String());
      await _secureStorage.write(key: _attemptsKey, value: '0');
    }
  }

  Future<void> _resetAttempts() async {
    await _secureStorage.delete(key: _attemptsKey);
    await _secureStorage.delete(key: _lockoutKey);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}md_pdf_salt_2024');
    return sha256.convert(bytes).toString();
  }
}
