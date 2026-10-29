import 'dart:async';

import 'package:bani_rasijan/features/backup/data/backup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

class _MockFunctionResponse extends Mock implements FunctionResponse {}

class _QueryTrace {
  int? limit;
  String? orderColumn;
  bool? ascending;
  String? filterColumn;
  Object? filterValue;
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.rows, this.trace);
  final List<Map<String, dynamic>> rows;
  final _QueryTrace trace;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) =>
      _FakeFilterBuilder(rows, trace);
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  _FakeFilterBuilder(this.rows, this.trace);
  final List<Map<String, dynamic>> rows;
  final _QueryTrace trace;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    trace.filterColumn = column;
    trace.filterValue = value;
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    trace.orderColumn = column;
    trace.ascending = ascending;
    return _FakeTransformBuilder(rows, trace);
  }
}

class _FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  _FakeTransformBuilder(this.rows, this.trace);
  final List<Map<String, dynamic>> rows;
  final _QueryTrace trace;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> limit(
    int count, {
    String? referencedTable,
  }) {
    trace.limit = count;
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeSingleTransformBuilder(rows.isEmpty ? null : rows.first);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async =>
      onValue(rows);
}

class _FakeSingleTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeSingleTransformBuilder(this.row);
  final PostgrestMap? row;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) async =>
      onValue(row);
}

void main() {
  late _MockSupabaseClient client;
  late _MockFunctionsClient functions;
  late BackupRepository repository;

  setUp(() {
    client = _MockSupabaseClient();
    functions = _MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repository = BackupRepository(client: client);
  });

  test('fetchRecent orders newest first and limits the query to ten jobs',
      () async {
    final trace = _QueryTrace();
    when(() => client.from('backup_jobs')).thenAnswer(
      (_) => _FakeQueryBuilder([_jobRow()], trace),
    );

    final jobs = await repository.fetchRecent();

    expect(jobs, hasLength(1));
    expect(jobs.single.id, 'backup-1');
    expect(trace.orderColumn, 'created_at');
    expect(trace.ascending, isFalse);
    expect(trace.limit, 10);
  });

  test('lastSuccess filters successful jobs and requests the newest one',
      () async {
    final trace = _QueryTrace();
    final row = _jobRow()..['status'] = 'success';
    when(() => client.from('backup_jobs')).thenAnswer(
      (_) => _FakeQueryBuilder([row], trace),
    );

    final job = await repository.lastSuccess();

    expect(job?.status, 'success');
    expect(trace.filterColumn, 'status');
    expect(trace.filterValue, 'success');
    expect(trace.orderColumn, 'finished_at');
    expect(trace.ascending, isFalse);
    expect(trace.limit, 1);
  });

  test('request sends trimmed note and selected scope then parses the response',
      () async {
    final response = _MockFunctionResponse();
    when(() => response.data).thenReturn(_jobRow());
    when(() => functions.invoke(
          'request-backup',
          body: {'scope': 'db_only', 'note': 'Pemeriksaan rutin'},
        )).thenAnswer((_) async => response);

    final job = await repository.request(
      scope: 'db_only',
      note: '  Pemeriksaan rutin  ',
    );

    expect(job.id, 'backup-1');
    verify(() => functions.invoke(
          'request-backup',
          body: {'scope': 'db_only', 'note': 'Pemeriksaan rutin'},
        )).called(1);
  });

  test('falls back to polling after realtime errors and stops when idle',
      () async {
    var reads = 0;
    when(() => client.from('backup_jobs')).thenAnswer((_) {
      reads++;
      final row = _jobRow()..['status'] = reads == 1 ? 'pending' : 'success';
      return _FakeQueryBuilder([row], _QueryTrace());
    });
    final pollingRepository = BackupRepository(
      client: client,
      pollInterval: const Duration(milliseconds: 10),
      realtimeRows: () => Stream<List<Map<String, dynamic>>>.error(
        StateError('realtime unavailable'),
      ),
    );
    final snapshots = <List<String>>[];
    final secondSnapshot = Completer<void>();
    final subscription = pollingRepository.watchRecent().listen((jobs) {
      snapshots.add(jobs.map((job) => job.status).toList());
      if (snapshots.length == 2) secondSnapshot.complete();
    });

    await secondSnapshot.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(snapshots, [
      ['pending'],
      ['success'],
    ]);
    await subscription.cancel();
  });
}

Map<String, dynamic> _jobRow() => {
      'id': 'backup-1',
      'status': 'pending',
      'trigger_type': 'manual',
      'scope': 'db_only',
      'created_at': '2026-10-21T00:00:00Z',
      'note': 'Pemeriksaan rutin',
      'started_at': null,
      'finished_at': null,
      'size_bytes': null,
      'location': null,
      'error': null,
    };
