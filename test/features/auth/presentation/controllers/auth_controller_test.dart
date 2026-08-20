import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/domain/auth_state.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

    test('sets AuthMagicLinkSent on successful send', () async {
      when(() => mockRepo.signInWithOtp('test@example.com'))
          .thenAnswer((_) async {});

      final controller = container.read(authControllerProvider.notifier);
      await controller.sendMagicLink('test@example.com');

      expect(
        container.read(authControllerProvider),
        isA<AuthMagicLinkSent>().having(
          (s) => s.email,
          'email',
          'test@example.com',
        ),
      );
      verify(() => mockRepo.signInWithOtp('test@example.com')).called(1);
    });

    test('sets user-friendly AuthError on AuthException', () async {
      when(() => mockRepo.signInWithOtp('test@example.com'))
          .thenThrow(const AuthException('rate limit exceeded'));

      final controller = container.read(authControllerProvider.notifier);
      await controller.sendMagicLink('test@example.com');

      expect(
        container.read(authControllerProvider),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Terlalu banyak percobaan'),
        ),
      );
    });
  });

  group('AuthController.redeemInviteAndSendLink', () {
    test('sets AuthError when code is empty', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.redeemInviteAndSendLink(
        code: '',
        email: 'test@example.com',
      );

      expect(
        container.read(authControllerProvider),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          'Kode undangan tidak boleh kosong',
        ),
      );
      verifyNever(
        () => mockRepo.redeemInviteCode(
          code: any(named: 'code'),
          email: any(named: 'email'),
        ),
      );
    });

    test('sets AuthMagicLinkSent on valid redeem', () async {
      when(
        () => mockRepo.redeemInviteCode(
          code: 'VALID123',
          email: 'new@example.com',
        ),
      ).thenAnswer((_) async {});

      final controller = container.read(authControllerProvider.notifier);
      await controller.redeemInviteAndSendLink(
        code: 'VALID123',
        email: 'new@example.com',
      );

      expect(
        container.read(authControllerProvider),
        isA<AuthMagicLinkSent>().having(
          (s) => s.email,
          'email',
          'new@example.com',
        ),
      );
    });

    test('sets generic error on invalid/expired/revoked invite code', () async {
      when(
        () => mockRepo.redeemInviteCode(
          code: 'EXPIRED',
          email: 'new@example.com',
        ),
      ).thenThrow(const AuthException('Kode undangan tidak valid'));

      final controller = container.read(authControllerProvider.notifier);
      await controller.redeemInviteAndSendLink(
        code: 'EXPIRED',
        email: 'new@example.com',
      );

      expect(
        container.read(authControllerProvider),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          'Kode undangan tidak valid',
        ),
      );
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
