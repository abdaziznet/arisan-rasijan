enum AppBiometricType {
  fingerprint,
  face,
  iris,
  other,
  none;

  String get displayName {
    switch (this) {
      case AppBiometricType.fingerprint:
        return 'Sidik Jari';
      case AppBiometricType.face:
        return 'Face ID';
      case AppBiometricType.iris:
        return 'Iris Scanner';
      case AppBiometricType.other:
      case AppBiometricType.none:
        return 'Biometrik';
    }
  }

  String get actionPrompt {
    switch (this) {
      case AppBiometricType.face:
        return 'Pindai Wajah Anda';
      case AppBiometricType.fingerprint:
        return 'Sentuh Sensor Sidik Jari';
      default:
        return 'Pindai Biometrik';
    }
  }
}
