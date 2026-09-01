import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/members/data/members_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockPostgrestFilterBuilder mockBuilder;
  late AuthRepository authRepo;
  late MembersRepository membersRepo;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockBuilder = MockPostgrestFilterBuilder();
    authRepo = AuthRepository(client: mockSupabase);
    membersRepo = MembersRepository(client: mockSupabase);
  });

  group('Admin Generate Invite Code RPC', () {
    test('generateInviteCode calls RPC generate_invite_code with parameters',
        () async {
      when(() => mockSupabase.rpc(
            'generate_invite_code',
            params: {
              'p_custom_code': 'BANI2026',
              'p_max_uses': 5,
              'p_expires_days': 30,
            },
          )).thenAnswer((_) => mockBuilder);
      when(() => mockBuilder.then<dynamic>(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
        return Future.value(onValue('BANI2026'));
      });

      final code = await membersRepo.generateInviteCode(
        customCode: 'BANI2026',
        maxUses: 5,
        expiresDays: 30,
      );

      expect(code, equals('BANI2026'));
      verify(() => mockSupabase.rpc(
            'generate_invite_code',
            params: {
              'p_custom_code': 'BANI2026',
              'p_max_uses': 5,
              'p_expires_days': 30,
            },
          )).called(1);
    });
  });

  group('User Redeem Invite Code & Activate Profile RPC', () {
    test('redeemInviteCodeAndCreateProfile calls RPC redeem_invite_code',
        () async {
      when(() => mockSupabase.rpc(
            'redeem_invite_code',
            params: {
              'p_code': 'BANI2026',
              'p_full_name': 'Ahmad Rasijan',
              'p_phone_number': '08123456789',
              'p_address': 'Jakarta',
            },
          )).thenAnswer((_) => mockBuilder);
      when(() => mockBuilder.then<dynamic>(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
        return Future.value(onValue({'success': true}));
      });

      final result = await authRepo.redeemInviteCodeAndCreateProfile(
        code: 'BANI2026',
        fullName: 'Ahmad Rasijan',
        phoneNumber: '08123456789',
        address: 'Jakarta',
      );

      expect(result, isTrue);
      verify(() => mockSupabase.rpc(
            'redeem_invite_code',
            params: {
              'p_code': 'BANI2026',
              'p_full_name': 'Ahmad Rasijan',
              'p_phone_number': '08123456789',
              'p_address': 'Jakarta',
            },
          )).called(1);
    });
  });
}
