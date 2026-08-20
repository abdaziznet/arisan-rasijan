sealed class AuthScreenState {
  const AuthScreenState();
}

class AuthInitial extends AuthScreenState {
  const AuthInitial();
}

class AuthLoading extends AuthScreenState {
  const AuthLoading();
}

class AuthMagicLinkSent extends AuthScreenState {
  const AuthMagicLinkSent(this.email);
  final String email;
}

class AuthSuccess extends AuthScreenState {
  const AuthSuccess();
}

class AuthError extends AuthScreenState {
  const AuthError(this.message);
  final String message;
}
