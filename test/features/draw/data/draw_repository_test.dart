import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bani_rasijan/features/draw/data/draw_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}
class MockFunctionResponse extends Mock implements FunctionResponse {}

// A simple fake for Supabase queries
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> data;
  FakeQueryBuilder(this.data);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakeFilterBuilder(data);
  }
}

class FakeFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakeFilterBuilder(this.data);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> not(String column, String operator, Object? value) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(String column, {bool ascending = false, bool nullsFirst = false, String? referencedTable}) {
    return FakeTransformBuilder(data);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue(data);
  }
}

class FakeTransformBuilder extends Fake implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakeTransformBuilder(this.data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue(data);
  }
}

void main() {
  late DrawRepository repository;
  late MockSupabaseClient mockSupabase;
  late MockFunctionsClient mockFunctions;
  
  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockSupabase.functions).thenReturn(mockFunctions);
    
    repository = DrawRepository(client: mockSupabase);
  });

  group('DrawRepository.runDraw', () {
    test('throws exception when data is null', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.data).thenReturn(null);
      when(() => mockFunctions.invoke('run-draw', body: {'periodId': '1'}))
          .thenAnswer((_) async => mockResponse);

      expect(() => repository.runDraw('1'), throwsA(isA<Exception>()));
    });

    test('throws exception when data contains error', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.data).thenReturn({'error': {'message': 'Custom error'}});
      when(() => mockFunctions.invoke('run-draw', body: {'periodId': '1'}))
          .thenAnswer((_) async => mockResponse);

      expect(() => repository.runDraw('1'), throwsException);
    });

    test('returns DrawModel on success', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.data).thenReturn({
        'id': 'd1',
        'periodId': 'p1',
        'winnerId': 'w1',
        'createdAt': '2023-01-01T00:00:00Z'
      });
      when(() => mockFunctions.invoke('run-draw', body: {'periodId': '1'}))
          .thenAnswer((_) async => mockResponse);

      final result = await repository.runDraw('1');
      expect(result.id, 'd1');
      expect(result.winnerId, 'w1');
    });
  });

  group('DrawRepository.getCandidates', () {
    test('returns candidates excluding past winners', () async {
      when(() => mockSupabase.from('profiles')).thenAnswer((_) => FakeQueryBuilder([
        {'id': 'm1', 'full_name': 'Member 1'},
        {'id': 'm2', 'full_name': 'Member 2'},
        {'id': 'm3', 'full_name': 'Member 3'},
      ]));

      when(() => mockSupabase.from('arisan_periods')).thenAnswer((_) => FakeQueryBuilder([
        {'winner_id': 'm1'}
      ]));

      final candidates = await repository.getCandidates('p1');
      
      expect(candidates.length, 2);
      expect(candidates[0].id, 'm2');
      expect(candidates[1].id, 'm3');
    });

    test('returns all active members if everyone has won', () async {
      when(() => mockSupabase.from('profiles')).thenAnswer((_) => FakeQueryBuilder([
        {'id': 'm1', 'full_name': 'Member 1'},
        {'id': 'm2', 'full_name': 'Member 2'},
      ]));

      when(() => mockSupabase.from('arisan_periods')).thenAnswer((_) => FakeQueryBuilder([
        {'winner_id': 'm1'},
        {'winner_id': 'm2'},
      ]));

      final candidates = await repository.getCandidates('p1');
      
      expect(candidates.length, 2);
      expect(candidates[0].id, 'm1');
      expect(candidates[1].id, 'm2');
    });
  });

  group('DrawRepository.getDrawHistory', () {
    test('returns draw history', () async {
      when(() => mockSupabase.from('draws')).thenAnswer((_) => FakeQueryBuilder([
        {
          'id': 'd1',
          'period_id': 'p1',
          'winner_id': 'm1',
          'conducted_at': '2023-01-01T00:00:00Z',
          'arisan_periods': {'period_number': 1},
          'winner': {'full_name': 'Member 1'}
        }
      ]));

      final history = await repository.getDrawHistory();
      
      expect(history.length, 1);
      expect(history[0].id, 'd1');
      expect(history[0].winnerName, 'Member 1');
      expect(history[0].periodNumber, 1);
    });
  });
}
