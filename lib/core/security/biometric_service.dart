// Biometric authentication service - fingerprint, face ID, iris
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._(this._auth);

  final LocalAuthentication _auth;

  static BiometricService create() => BiometricService._(LocalAuthentication());

  Future<void> initialize() async {
    await _auth.canCheckBiometrics;
  }

  Future<bool> get isDeviceSupported async => _auth.isDeviceSupported();

  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({
    String reason = 'Please authenticate to unlock OmniForge AI',
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: false,
          sensitiveTransaction: sensitiveTransaction,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> stopAuthentication() => _auth.stopAuthentication();
}
