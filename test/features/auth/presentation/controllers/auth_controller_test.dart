import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/domain/auth_state.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController.signInWithGoogle', () {
    test('sets AuthSuccess on successful Google login', () async {
      final mockResponse = MockAuthResponse();
      when(() => mockRepo.signInWithGoogle())
          .thenAnswer((_) async => mockResponse);

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      expect(
        container.read(authControllerProvider),
        isA<AuthSuccess>(),
      );
      verify(() => mockRepo.signInWithGoogle()).called(1);
    });

    test('sets AuthInitial when user cancels Google login', () async {
      when(() => mockRepo.signInWithGoogle())
          .thenThrow(const AuthException('Login Google dibatalkan'));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      expect(
        container.read(authControllerProvider),
        isA<AuthInitial>(),
      );
      verify(() => mockRepo.signInWithGoogle()).called(1);
    });

    test('sets AuthError on general error', () async {
      when(() => mockRepo.signInWithGoogle())
          .thenThrow(const AuthException('Server error'));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      expect(
        container.read(authControllerProvider),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          'Gagal masuk dengan Google. Periksa koneksi lalu coba lagi.',
        ),
      );
      verify(() => mockRepo.signInWithGoogle()).called(1);
    });
  });

  group('AuthController.sendMagicLink', () {
    test('sets AuthError on invalid email without calling repo', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.sendMagicLink('invalid-email');

      expect(
        container.read(authControllerProvider),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          'Format email tidak valid',
        ),
      );
      verifyNever(() => mockRepo.signInWithOtp(any()));
    });
  });

  group('AuthController.signOut', () {
    test('calls repo signOut and resets to AuthInitial', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      expect(
        container.read(authControllerProvider),
        isA<AuthInitial>(),
      );
      verify(() => mockRepo.signOut()).called(1);
    });
  });
}
