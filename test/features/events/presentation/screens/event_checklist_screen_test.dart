import 'package:bani_rasijan/features/events/data/event_checklist_repository.dart';
import 'package:bani_rasijan/features/events/domain/event_checklist_model.dart';
import 'package:bani_rasijan/features/events/presentation/providers/event_checklist_providers.dart';
import 'package:bani_rasijan/features/events/presentation/screens/event_checklist_screen.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventChecklistRepository extends Mock
    implements EventChecklistRepository {}

void main() {
  late MockEventChecklistRepository mockRepo;

  const admin = MemberModel(id: 'm-1', fullName: 'Ahmad Rasijan', role: 'admin');
  const member = MemberModel(id: 'm-2', fullName: 'Siti Rasijan', role: 'member');

  final sampleItems = [
    const EventChecklistModel(
      id: 'item-1',
      periodId: 'p-1',
      stepName: 'Kumpul & Kehadiran',
      stepOrder: 1,
    ),
    const EventChecklistModel(
      id: 'item-2',
      periodId: 'p-1',
      stepName: 'Yasin & Sholawat',
      stepOrder: 2,
    ),
    const EventChecklistModel(
      id: 'item-3',
      periodId: 'p-1',
      stepName: 'Makan Bersama',
      stepOrder: 3,
    ),
  ];

  setUp(() {
    mockRepo = MockEventChecklistRepository();
    when(() => mockRepo.getChecklistForPeriod('p-1'))
        .thenAnswer((_) async => sampleItems);
  });

  Widget buildWidget({MemberModel profile = admin, String periodId = 'p-1'}) {
    return ProviderScope(
      overrides: [
        eventChecklistRepositoryProvider.overrideWithValue(mockRepo),
        currentMemberProfileProvider.overrideWith((ref) async => profile),
      ],
      child: MaterialApp(
        home: EventChecklistScreen(periodId: periodId),
      ),
    );
  }

  testWidgets('renders ordered agenda items without checkboxes or completion dates',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Susunan Acara'), findsOneWidget);
    expect(find.text('Kumpul & Kehadiran'), findsOneWidget);
    expect(find.text('Yasin & Sholawat'), findsOneWidget);
    expect(find.text('Buka Bacaan Yasin'), findsOneWidget);
    expect(find.text('Makan Bersama'), findsOneWidget);
    expect(find.text('Doa Pembuka Pertemuan'), findsOneWidget);
    expect(find.text('Doa Sebelum Makan'), findsOneWidget);

    // Sequence indicators
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);

    // No checkbox or completed status
    expect(find.byType(Checkbox), findsNothing);
    expect(find.textContaining('selesai'), findsNothing);
  });

  testWidgets('shows admin controls (FAB, delete, drag handles) for admin users',
      (tester) async {
    await tester.pumpWidget(buildWidget(profile: admin));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Agenda'), findsWidgets);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(4)); // 1 in header, 3 in items
  });

  testWidgets('hides admin controls for non-admin users', (tester) async {
    await tester.pumpWidget(buildWidget(profile: member));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byType(ReorderableDragStartListener), findsNothing);
  });

  testWidgets('shows empty state when no items exist', (tester) async {
    when(() => mockRepo.getChecklistForPeriod('p-empty'))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildWidget(periodId: 'p-empty'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Susunan Acara'), findsOneWidget);
    expect(find.text('Buat Agenda Standar'), findsOneWidget);
    expect(find.text('Tambah Agenda Manual'), findsOneWidget);
  });
}
