import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricLoginType { face, fingerprint, generic }

class BiometricAvailability {
  const BiometricAvailability({
    required this.supported,
    required this.canAuthenticate,
    required this.types,
  });

  final bool supported;
  final bool canAuthenticate;
  final List<BiometricType> types;

  bool get isAvailable => supported && canAuthenticate;
}

class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<BiometricAvailability> checkAvailability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return const BiometricAvailability(
          supported: false,
          canAuthenticate: false,
          types: [],
        );
      }

      final canCheck = await _auth.canCheckBiometrics;
      final types = canCheck ? await _auth.getAvailableBiometrics() : <BiometricType>[];
      final canAuthenticate = types.isNotEmpty || supported;

      return BiometricAvailability(
        supported: supported,
        canAuthenticate: canAuthenticate,
        types: types,
      );
    } catch (e) {
      debugPrint('Biometric availability error: $e');
      return const BiometricAvailability(
        supported: false,
        canAuthenticate: false,
        types: [],
      );
    }
  }

  Future<bool> isAvailable() async {
    return (await checkAvailability()).isAvailable;
  }

  Future<List<BiometricType>> getAvailableTypes() async {
    return (await checkAvailability()).types;
  }

  Future<BiometricLoginType> getLoginType() async {
    final types = await getAvailableTypes();
    if (types.contains(BiometricType.face) ||
        types.contains(BiometricType.iris) ||
        types.contains(BiometricType.strong)) {
      return BiometricLoginType.face;
    }
    if (types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.weak)) {
      return BiometricLoginType.fingerprint;
    }
    return BiometricLoginType.generic;
  }

  String labelFor(BiometricLoginType type) {
    switch (type) {
      case BiometricLoginType.face:
        return 'Face ID';
      case BiometricLoginType.fingerprint:
        return 'Sidik Jari';
      case BiometricLoginType.generic:
        return 'Biometrik';
    }
  }

  Future<bool> authenticate({
    String reason = 'Masuk ke CreativePOS',
    bool biometricOnly = true,
  }) async {
    final availability = await checkAvailability();
    if (!availability.isAvailable) {
      debugPrint('Biometric not available on this device');
      return false;
    }

    try {
      await _auth.stopAuthentication();
    } catch (_) {}

    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (ok) return true;

      if (biometricOnly) {
        return authenticate(reason: reason, biometricOnly: false);
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.code} ${e.message}');
      if (biometricOnly &&
          (e.code == 'NotAvailable' ||
              e.code == 'notAvailable' ||
              e.code == 'noBiometricHardware' ||
              e.code == 'NotEnrolled')) {
        return authenticate(reason: reason, biometricOnly: false);
      }
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}