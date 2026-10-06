sealed class BiometricAuthResult {
  const BiometricAuthResult();
}

final class BiometricAuthSuccess extends BiometricAuthResult {
  const BiometricAuthSuccess();
}

final class BiometricAuthFailed extends BiometricAuthResult {
  const BiometricAuthFailed({
    required this.errorMessage,
    this.isUserCanceled = false,
    this.isLockedOut = false,
  });

  final String errorMessage;
  final bool isUserCanceled;
  final bool isLockedOut;
}

final class BiometricAuthNotAvailable extends BiometricAuthResult {
  const BiometricAuthNotAvailable(this.reason);
  final String reason;
}

sealed class BiometricState {
  const BiometricState();
}

final class BiometricInitial extends BiometricState {
  const BiometricInitial();
}

final class BiometricAuthenticating extends BiometricState {
  const BiometricAuthenticating();
}

final class BiometricAuthenticated extends BiometricState {
  const BiometricAuthenticated();
}

final class BiometricFailed extends BiometricState {
  const BiometricFailed({
    required this.errorMessage,
    required this.remainingAttempts,
    this.isUserCanceled = false,
  });

  final String errorMessage;
  final int remainingAttempts;
  final bool isUserCanceled;
}

final class BiometricLockedOut extends BiometricState {
  const BiometricLockedOut({required this.message});
  final String message;
}

final class BiometricUnavailable extends BiometricState {
  const BiometricUnavailable({required this.reason});
  final String reason;
}
