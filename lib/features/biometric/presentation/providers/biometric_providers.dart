import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/biometric_preferences.dart';
import '../../data/biometric_service.dart';
import '../../domain/biometric_state.dart';
import '../../domain/biometric_type.dart';
import '../controllers/biometric_controller.dart';

final biometricServiceProvider = Provider<IBiometricService>((ref) {
  return BiometricService();
});

final biometricPreferencesProvider = Provider<BiometricPreferences>((ref) {
  return BiometricPreferences();
});

final biometricControllerProvider =
    NotifierProvider<BiometricController, BiometricState>(
  BiometricController.new,
);

final biometricCapabilityProvider = FutureProvider<bool>((ref) async {
  final controller = ref.read(biometricControllerProvider.notifier);
  return controller.isDeviceCapable();
});

final biometricPrimaryTypeProvider = FutureProvider<AppBiometricType>((ref) async {
  final controller = ref.read(biometricControllerProvider.notifier);
  return controller.getPrimaryType();
});

final isBiometricEnabledProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(biometricPreferencesProvider);
  return prefs.isBiometricEnabled();
});

final autoLockTimeoutMinutesProvider = FutureProvider<int>((ref) async {
  final prefs = ref.watch(biometricPreferencesProvider);
  return prefs.getAutoLockTimeoutMinutes();
});
