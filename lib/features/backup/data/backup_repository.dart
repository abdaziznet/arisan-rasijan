import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/backup_job.dart';

class BackupRepository {
  BackupRepository({
    required SupabaseClient client,
    Stream<List<Map<String, dynamic>>> Function()? realtimeRows,
    Duration pollInterval = const Duration(seconds: 10),
  })  : _client = client,
        _realtimeRows = realtimeRows,
        _pollInterval = pollInterval;

  final SupabaseClient _client;
  final Stream<List<Map<String, dynamic>>> Function()? _realtimeRows;
  final Duration _pollInterval;

  Future<List<BackupJob>> fetchRecent() async {
    final rows = await _client
        .from('backup_jobs')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    return rows.map((row) => BackupJob.fromMap(row)).toList(growable: false);
  }

  Stream<List<BackupJob>> watchRecent() {
    late final StreamController<List<BackupJob>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSubscription;
    Timer? pollingTimer;
    var polling = false;

    Future<void> poll() async {
      if (!controller.isClosed) {
        try {
          final jobs = await fetchRecent();
          controller.add(jobs);
          if (polling && !jobs.any((job) => job.isActive)) {
            pollingTimer?.cancel();
            pollingTimer = null;
            polling = false;
          }
        } catch (_) {
          // Keep the previous snapshot and retry on the next poll.
        }
      }
    }

    void startPolling(Object error, StackTrace stackTrace) {
      if (polling || controller.isClosed) return;
      polling = true;
      unawaited(poll());
      pollingTimer = Timer.periodic(_pollInterval, (_) {
        unawaited(poll());
      });
    }

    controller = StreamController<List<BackupJob>>(
      onListen: () async {
        try {
          controller.add(await fetchRecent());
        } catch (error, stackTrace) {
          startPolling(error, stackTrace);
        }
        if (controller.isClosed) return;
        final realtimeRows = _realtimeRows?.call() ??
            _client
                .from('backup_jobs')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false)
                .limit(10);
        realtimeSubscription = realtimeRows.listen(
          (rows) {
            controller.add(rows.map(BackupJob.fromMap).toList(growable: false));
          },
          onError: startPolling,
        );
      },
      onCancel: () async {
        pollingTimer?.cancel();
        await realtimeSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<BackupJob?> lastSuccess() async {
    final row = await _client
        .from('backup_jobs')
        .select()
        .eq('status', 'success')
        .order('finished_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : BackupJob.fromMap(row);
  }

  Future<BackupJob> request({required String scope, String? note}) async {
    final response = await _client.functions.invoke(
      'request-backup',
      body: {
        'scope': scope,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final data = response.data;
    if (data is! Map) throw const FormatException('Invalid backup response');
    return BackupJob.fromMap(Map<String, dynamic>.from(data));
  }
}
