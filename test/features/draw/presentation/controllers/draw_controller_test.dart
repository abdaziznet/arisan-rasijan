import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bani_rasijan/features/draw/presentation/providers/draw_providers.dart';
import 'package:bani_rasijan/features/draw/data/draw_repository.dart';
import 'package:bani_rasijan/features/draw/domain/draw_model.dart';

class MockDrawRepository extends Mock implements DrawRepository {}

void main() {
  late MockDrawRepository mockRepository;

  setUp(() {
    mockRepository = MockDrawRepository();
  });

  ProviderContainer makeProviderContainer({
    bool allPaid = true,
    bool isDrawDay = true,
    bool isAlreadyDone = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        drawRepositoryProvider.overrideWithValue(mockRepository),
        allMembersPaidProvider.overrideWith((ref) => Future.value(allPaid)),
        isDrawDayProvider.overrideWithValue(isDrawDay),
        isDrawAlreadyDoneProvider.overrideWith((ref) => Future.value(isAlreadyDone)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('DrawController exists and initial state is null', () {
    final container = makeProviderContainer();
    final state = container.read(drawControllerProvider);
    expect(state.value, isNull);
  });

  test('runDraw returns error if not all members paid', () async {
    final container = makeProviderContainer(allPaid: false);
    final controller = container.read(drawControllerProvider.notifier);

    await controller.runDraw('period1');
    final state = container.read(drawControllerProvider);

    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Belum semua anggota membayar iuran.'));
  });

  test('runDraw returns error if not draw day', () async {
    final container = makeProviderContainer(isDrawDay: false);
    final controller = container.read(drawControllerProvider.notifier);

    await controller.runDraw('period1');
    final state = container.read(drawControllerProvider);

    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Kocokan hanya bisa dijalankan pada hari-H acara.'));
  });

  test('runDraw returns error if draw already done', () async {
    final container = makeProviderContainer(isAlreadyDone: true);
    final controller = container.read(drawControllerProvider.notifier);

    await controller.runDraw('period1');
    final state = container.read(drawControllerProvider);

    expect(state.hasError, isTrue);
    expect(state.error.toString(), contains('Kocokan untuk periode ini sudah selesai.'));
  });

  test('runDraw calls repo and returns DrawModel on success', () async {
    final mockDraw = DrawModel(
      id: 'd1',
      periodId: 'p1',
      winnerId: 'w1',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => mockRepository.runDraw(any())).thenAnswer((_) async => mockDraw);

    final container = makeProviderContainer();
    final controller = container.read(drawControllerProvider.notifier);

    await controller.runDraw('period1');
    final state = container.read(drawControllerProvider);

    expect(state.hasValue, isTrue);
    expect(state.value, equals(mockDraw));
    verify(() => mockRepository.runDraw('period1')).called(1);
  });
}
