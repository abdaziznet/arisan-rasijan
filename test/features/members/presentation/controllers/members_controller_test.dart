import 'package:bani_rasijan/features/members/data/members_repository.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMembersRepository extends Mock implements MembersRepository {}
class FakeMemberModel extends Fake implements MemberModel {}

void main() {
  late MockMembersRepository mockRepo;
  late ProviderContainer container;

  const sampleMember = MemberModel(
    id: 'm-1',
    fullName: 'Ahmad Rasijan',
    role: 'admin',
  );

  setUpAll(() {
    registerFallbackValue(FakeMemberModel());
  });

  setUp(() {
    mockRepo = MockMembersRepository();
    container = ProviderContainer(
      overrides: [
        membersRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('MembersController', () {
    test('fetches members on initialization', () async {
      when(() => mockRepo.getMembers())
          .thenAnswer((_) async => [sampleMember]);

      final members = await container.read(membersControllerProvider.future);

      expect(members, hasLength(1));
      expect(members.first.fullName, 'Ahmad Rasijan');
      verify(() => mockRepo.getMembers()).called(1);
    });

    test('saveProfile calls repository upsertProfile', () async {
      when(() => mockRepo.getMembers())
          .thenAnswer((_) async => [sampleMember]);
      when(() => mockRepo.upsertProfile(any()))
          .thenAnswer((_) async => sampleMember);

      final controller = container.read(membersControllerProvider.notifier);
      await controller.saveProfile(sampleMember);

      verify(() => mockRepo.upsertProfile(any())).called(1);
    });

    test('updateMemberStatus updates role and active status', () async {
      when(() => mockRepo.getMembers())
          .thenAnswer((_) async => [sampleMember]);
      when(
        () => mockRepo.updateMemberAdminStatus(
          memberId: 'm-1',
          role: 'admin',
          isActive: false,
        ),
      ).thenAnswer(
        (_) async => sampleMember.copyWith(role: 'admin', isActive: false),
      );

      final controller = container.read(membersControllerProvider.notifier);
      await controller.updateMemberStatus(
        memberId: 'm-1',
        role: 'admin',
        isActive: false,
      );

      verify(
        () => mockRepo.updateMemberAdminStatus(
          memberId: 'm-1',
          role: 'admin',
          isActive: false,
        ),
      ).called(1);
    });
  });
}
