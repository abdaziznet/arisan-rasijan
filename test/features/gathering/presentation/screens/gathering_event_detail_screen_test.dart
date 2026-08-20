import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_poll_option_model.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/gathering/presentation/screens/gathering_event_detail_screen.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks.dart';

void main() {
  late MockGatheringRepository mockGatheringRepository;
  late GatheringEventModel testEvent;
  late List<GatheringPollOptionModel> testOptions;

  setUp(() {
    mockGatheringRepository = MockGatheringRepository();
    testEvent = GatheringEventModel(
      id: 'event-1',
      title: 'Test Gathering Event',
      status: 'voting',
      createdBy: 'admin-id',
      createdAt: DateTime.now(),
    );
    testOptions = [
      GatheringPollOptionModel(
        id: 'opt-1',
        gatheringEventId: 'event-1',
        optionLabel: 'Option 1',
        createdAt: DateTime.now(),
        voteCount: 1,
      ),
    ];

    when(() => mockGatheringRepository.getEvent('event-1')).thenAnswer((_) async => testEvent);
    when(() => mockGatheringRepository.getPollOptions('event-1')).thenAnswer((_) async => testOptions);
    when(() => mockGatheringRepository.getAppSettings()).thenAnswer((_) async => {'gathering_votes_visible_to_members': 'true'});
    when(() => mockGatheringRepository.hasMemberVoted(eventId: 'event-1', memberId: 'member-1')).thenAnswer((_) async => false);
  });

  Widget createTestableWidget() {
    return ProviderScope(
      overrides: [
        gatheringRepositoryProvider.overrideWithValue(mockGatheringRepository),
        currentMemberProfileProvider.overrideWith((ref) async => const MemberModel(id: 'member-1', fullName: 'Member', role: 'member')),
      ],
      child: const MaterialApp(
        home: GatheringEventDetailScreen(eventId: 'event-1'),
      ),
    );
  }

  testWidgets('renders event details and voting section', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Test Gathering Event'), findsOneWidget);
    expect(find.text('Pilih satu opsi di bawah ini:'), findsOneWidget);
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Kirim Suara'), findsOneWidget);
  });
}
