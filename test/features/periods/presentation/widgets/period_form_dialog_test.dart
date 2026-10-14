import 'package:bani_rasijan/features/members/data/members_repository.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository_provider.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:bani_rasijan/features/periods/presentation/widgets/period_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPeriodsRepository extends Mock implements PeriodsRepository {}

class MockMembersRepository extends Mock implements MembersRepository {}

void main() {
  late MockPeriodsRepository periodsRepository;
  late MockMembersRepository membersRepository;

  setUp(() {
    periodsRepository = MockPeriodsRepository();
    membersRepository = MockMembersRepository();
    when(() => membersRepository.getMembers()).thenAnswer((_) async => []);
  });

  Widget buildDialog() => ProviderScope(
        overrides: [
          periodsRepositoryProvider.overrideWithValue(periodsRepository),
          membersRepositoryProvider.overrideWithValue(membersRepository),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => PeriodFormDialog.show(context),
                  child: const Text('Tambah periode'),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.tap(find.text('Tambah periode'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts at period 1 and locks its number when database is empty',
      (tester) async {
    when(() => periodsRepository.getPeriods()).thenAnswer((_) async => []);

    await openDialog(tester);

    final numberField =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(numberField.controller?.text, '1');
    final numberInput = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(TextField),
      ),
    );
    expect(numberInput.readOnly, isTrue);
  });

  testWidgets('uses latest database period number plus one and locks the field',
      (tester) async {
    when(() => periodsRepository.getPeriods()).thenAnswer(
      (_) async => [
        PeriodModel(
          id: 'period-4',
          periodNumber: 4,
          eventDate: DateTime(2026, 10, 15),
          status: 'upcoming',
        ),
        PeriodModel(
          id: 'period-2',
          periodNumber: 2,
          eventDate: DateTime(2026, 8, 15),
          status: 'completed',
        ),
      ],
    );

    await openDialog(tester);

    final numberField =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(numberField.controller?.text, '5');
    final numberInput = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(TextField),
      ),
    );
    expect(numberInput.readOnly, isTrue);
  });
}
