import 'package:bani_rasijan/features/periods/data/periods_repository.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository_provider.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:bani_rasijan/features/periods/presentation/providers/periods_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPeriodsRepository extends Mock implements PeriodsRepository {}
class FakePeriodModel extends Fake implements PeriodModel {}

void main() {
  late MockPeriodsRepository mockRepo;
  late ProviderContainer container;

  final samplePeriod = PeriodModel(
    id: 'p-1',
    periodNumber: 1,
    eventDate: DateTime(2026, 10, 15),
    status: 'upcoming',
  );

  setUpAll(() {
    registerFallbackValue(FakePeriodModel());
  });

  setUp(() {
    mockRepo = MockPeriodsRepository();
    container = ProviderContainer(
      overrides: [
        periodsRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PeriodsController & activePeriodProvider', () {
    test('fetches periods list on initialization', () async {
      when(() => mockRepo.getPeriods())
          .thenAnswer((_) async => [samplePeriod]);

      final periods = await container.read(periodsControllerProvider.future);

      expect(periods, hasLength(1));
      expect(periods.first.periodNumber, 1);
      verify(() => mockRepo.getPeriods()).called(1);
    });

    test('activePeriodProvider returns active period from repository', () async {
      when(() => mockRepo.getActivePeriod())
          .thenAnswer((_) async => samplePeriod);

      final active = await container.read(activePeriodProvider.future);

      expect(active, isNotNull);
      expect(active?.id, 'p-1');
      verify(() => mockRepo.getActivePeriod()).called(1);
    });

    test('createPeriod calls repository createPeriod and re-fetches', () async {
      when(() => mockRepo.getPeriods())
          .thenAnswer((_) async => [samplePeriod]);
      when(() => mockRepo.createPeriod(any()))
          .thenAnswer((_) async => samplePeriod);

      container.read(periodsControllerProvider);

      final controller = container.read(periodsControllerProvider.notifier);
      await controller.createPeriod(samplePeriod);

      verify(() => mockRepo.createPeriod(any())).called(1);
      verify(() => mockRepo.getPeriods()).called(2);
    });

    test('updatePeriod calls repository updatePeriod and re-fetches', () async {
      when(() => mockRepo.getPeriods())
          .thenAnswer((_) async => [samplePeriod]);
      when(() => mockRepo.updatePeriod(any()))
          .thenAnswer((_) async => samplePeriod);

      container.read(periodsControllerProvider);

      final controller = container.read(periodsControllerProvider.notifier);
      await controller.updatePeriod(samplePeriod);

      verify(() => mockRepo.updatePeriod(any())).called(1);
      verify(() => mockRepo.getPeriods()).called(2);
    });
  });
}
