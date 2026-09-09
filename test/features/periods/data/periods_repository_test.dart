import 'dart:async';

import 'package:bani_rasijan/core/services/cache_service.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockCacheService extends Mock implements CacheService {}

/// Mirror dari fluent chain Supabase:
/// from → select → inFilter/order (FilterBuilder) → limit (ListTransform)
/// → maybeSingle (MapTransform yang bisa di-await).
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final PostgrestFilterBuilder<List<Map<String, dynamic>>> builder;
  FakeQueryBuilder(this.builder);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) =>
      builder;
}

class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? result;
  FakeFilterBuilder(this.result);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> inFilter(
    String column,
    List<Object?> values,
  ) =>
      this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> limit(
    int count, {
    String? referencedTable,
  }) =>
      FakeListTransform(result);
}

class FakeListTransform extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? result;
  FakeListTransform(this.result);

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      FakeMapTransform(result);
}

class FakeMapTransform extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  final PostgrestMap? result;
  FakeMapTransform(Map<String, dynamic>? result) : result = result;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) async =>
      onValue(result);
}

void main() {
  late PeriodsRepository repository;
  late MockSupabaseClient mockClient;
  late MockCacheService mockCache;

  final sampleJson = <String, dynamic>{
    'id': 'p-1',
    'period_number': 1,
    'event_date': '2026-10-15',
    'status': 'upcoming',
    'host': {'id': 'h-1', 'full_name': 'Ahmad'},
  };

  void stubServer(Map<String, dynamic>? result) {
    when(() => mockClient.from('arisan_periods')).thenAnswer(
      (_) => FakeQueryBuilder(FakeFilterBuilder(result)),
    );
  }

  setUp(() {
    mockClient = MockSupabaseClient();
    mockCache = MockCacheService();
    // Stub void-returning cache ops secara default (mocktail tidak menyediakan
    // return untuk method yang mengembalikan Future<void>).
    when(() => mockCache.saveData(any(), any())).thenAnswer((_) async {});
    when(() => mockCache.removeData(any())).thenAnswer((_) async {});
    repository = PeriodsRepository(client: mockClient, cacheService: mockCache);
  });

  group('PeriodsRepository.getActivePeriod', () {
    test('fetches fresh from server, saves cache, does not read cache on success',
        () async {
      stubServer(sampleJson);

      final result = await repository.getActivePeriod();

      expect(result, isNotNull);
      expect(result!.id, 'p-1');
      expect(result.periodNumber, 1);
      verify(() => mockCache.saveData('activePeriod', any())).called(1);
      verifyNever(() => mockCache.getData(any()));
    });

    test('clears stale cache when server returns no active period', () async {
      stubServer(null);

      final result = await repository.getActivePeriod();

      expect(result, isNull);
      verify(() => mockCache.removeData('activePeriod')).called(1);
    });

    test('falls back to cache when server request fails', () async {
      when(() => mockClient.from('arisan_periods'))
          .thenThrow(Exception('network error'));
      when(() => mockCache.getData('activePeriod'))
          .thenAnswer((_) async => sampleJson);

      final result = await repository.getActivePeriod();

      expect(result, isNotNull);
      expect(result!.id, 'p-1');
      verify(() => mockCache.getData('activePeriod')).called(1);
    });

    test('rethrows when server fails and cache is empty', () async {
      when(() => mockClient.from('arisan_periods'))
          .thenThrow(Exception('network error'));
      when(() => mockCache.getData('activePeriod'))
          .thenAnswer((_) async => null);

      expect(() => repository.getActivePeriod(), throwsA(isA<Exception>()));
    });
  });
}