import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockGoTrue;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleAccount;
  late MockGoogleSignInAuthentication mockGoogleAuth;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleAccount = MockGoogleSignInAccount();
    mockGoogleAuth = MockGoogleSignInAuthentication();

    when(() => mockGoogleAccount.email).thenReturn('test@example.com');
    when(() => mockGoogleAccount.id).thenReturn('google-user-123');
    when(() => mockSupabase.auth).thenReturn(mockGoTrue);

    repository = AuthRepository(
      client: mockSupabase,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthRepository.signInWithGoogle', () {
    test('successfully signs in with Google and Supabase', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(() => mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('valid-id-token');
      when(() => mockGoogleAuth.accessToken).thenReturn('valid-access-token');

      final mockResponse = MockAuthResponse();
      when(() => mockGoTrue.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: 'valid-id-token',
            accessToken: 'valid-access-token',
          )).thenAnswer((_) async => mockResponse);

      final result = await repository.signInWithGoogle();

      expect(result, equals(mockResponse));
      verify(() => mockGoogleSignIn.signIn()).called(1);
      verify(() => mockGoTrue.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: 'valid-id-token',
            accessToken: 'valid-access-token',
          )).called(1);
    });

    test('throws exception when user cancels Google Sign-In', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Login Google dibatalkan',
        )),
      );
      verifyNever(() => mockGoTrue.signInWithIdToken(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
            accessToken: any(named: 'accessToken'),
          ));
    });

    test('throws exception when idToken is null', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(() => mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn(null);

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'ID Token Google tidak ditemukan',
        )),
      );
      verifyNever(() => mockGoTrue.signInWithIdToken(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
            accessToken: any(named: 'accessToken'),
          ));
    });
  });

  group('AuthRepository.signOut', () {
    test('signs out from both Google and Supabase', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockGoogleSignIn.disconnect()).thenAnswer((_) async => null);
      when(() => mockGoTrue.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
      verify(() => mockGoogleSignIn.disconnect()).called(1);
      verify(() => mockGoTrue.signOut()).called(1);
    });
  });
}
