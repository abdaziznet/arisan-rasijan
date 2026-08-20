import 'package:bani_rasijan/core/theme/app_colors.dart';
import 'package:bani_rasijan/core/widgets/app_components.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/gathering/presentation/screens/gathering_screen.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks.dart';

void main() {
  late MockGatheringRepository mockGatheringRepository;
  late GatheringEventModel testEvent;

  setUp(() {
    mockGatheringRepository = MockGatheringRepository();
    testEvent = GatheringEventModel(
      id: 'event-1',
      title: 'Test Gathering Event',
      status: 'voting',
      createdBy: 'admin-id',
      createdAt: DateTime.now(),
    );

    when(() => mockGatheringRepository.getEvents()).thenAnswer((_) async => [testEvent]);
    when(() => mockGatheringRepository.getFundLedger()).thenAnswer((_) async => []);
  });

  Widget createTestableWidget() {
    return ProviderScope(
      overrides: [
        gatheringRepositoryProvider.overrideWithValue(mockGatheringRepository),
        currentMemberProfileProvider.overrideWith((ref) async => const MemberModel(
              id: 'admin-id',
              fullName: 'Admin',
              role: 'admin',
            )),
      ],
      child: const MaterialApp(
        home: GatheringScreen(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }

  testWidgets('renders list of gathering events', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Test Gathering Event'), findsOneWidget);
    expect(find.text('VOTING'), findsOneWidget);
    expect(find.byType(AppBadge), findsOneWidget);
    expect((tester.widget<AppBadge>(find.byType(AppBadge))).color,
        AppColors.primary);

    await tester.tap(find.text('Test Gathering Event'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Acara Gathering'), findsOneWidget);
  });
}