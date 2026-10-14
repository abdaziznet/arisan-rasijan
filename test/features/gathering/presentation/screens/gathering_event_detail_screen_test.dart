import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_poll_option_model.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/gathering/presentation/screens/gathering_event_detail_screen.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/voting_progress_bar.dart';
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
        optionLabel: 'Wisata ke Bandung',
        createdAt: DateTime.now(),
        voteCount: 1,
      ),
    ];

    when(() => mockGatheringRepository.getEvent('event-1'))
        .thenAnswer((_) async => testEvent);
    when(() => mockGatheringRepository.getPollOptions('event-1'))
        .thenAnswer((_) async => testOptions);
    when(() => mockGatheringRepository.getAppSettings())
        .thenAnswer((_) async => {'gathering_votes_visible_to_members': 'true'});
    when(() => mockGatheringRepository.hasMemberVoted(
          eventId: 'event-1',
          memberId: 'member-1',
        )).thenAnswer((_) async => false);
    when(() => mockGatheringRepository.getGatheringTally('event-1'))
        .thenAnswer((_) async => {'opt-1': 1});
  });

  Widget createTestableWidget({bool hasVoted = false}) {
    when(() => mockGatheringRepository.hasMemberVoted(
          eventId: 'event-1',
          memberId: 'member-1',
        )).thenAnswer((_) async => hasVoted);

    return ProviderScope(
      overrides: [
        gatheringRepositoryProvider.overrideWithValue(mockGatheringRepository),
        currentMemberProfileProvider.overrideWith(
          (ref) async => const MemberModel(
            id: 'member-1',
            fullName: 'Member',
            role: 'member',
          ),
        ),
      ],
      child: const MaterialApp(
        home: GatheringEventDetailScreen(eventId: 'event-1'),
      ),
    );
  }

  testWidgets('renders event details, progress bar, and voting options',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(hasVoted: false));
    await tester.pumpAndSettle();

    expect(find.text('Test Gathering Event'), findsOneWidget);
    expect(find.byType(VotingProgressBar), findsOneWidget);
    expect(find.text('Pilih Satu Opsi Destinasi:'), findsOneWidget);
    expect(find.text('Wisata ke Bandung'), findsWidgets);
    expect(find.text('Kirim Suara'), findsOneWidget);
  });

  testWidgets('renders voted confirmation card when member has already voted',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(hasVoted: true));
    await tester.pumpAndSettle();

    expect(find.text('Suara Anda Telah Tercatat'), findsOneWidget);
    expect(
      find.text(
        'Terima kasih telah berpartisipasi! Pilihan bersifat final dan tidak dapat diubah.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kirim Suara'), findsNothing);
  });
}
