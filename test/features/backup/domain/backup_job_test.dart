import 'package:bani_rasijan/features/backup/domain/backup_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupJob', () {
    test('parses nullable timestamps and bytes and converts timestamps locally',
        () {
      final job = BackupJob.fromMap({
        'id': 'job-1',
        'status': 'running',
        'trigger_type': 'manual',
        'scope': 'full',
        'created_at': '2026-10-21T00:00:00Z',
        'started_at': '2026-10-21T00:01:00Z',
        'finished_at': null,
        'size_bytes': 1250,
        'note': null,
        'location': null,
        'error': null,
      });

      expect(job.isActive, isTrue);
      expect(job.finishedAt, isNull);
      expect(job.duration, isNull);
      expect(job.sizeBytes, 1250);
      expect(job.createdAt.isUtc, isFalse);
    });

    test('calculates duration only when start and finish exist', () {
      final job = BackupJob(
        id: 'job-2',
        status: 'success',
        triggerType: 'scheduled',
        scope: 'db_only',
        createdAt: DateTime(2026),
        startedAt: DateTime(2026, 10, 21, 10),
        finishedAt: DateTime(2026, 10, 21, 10, 2, 5),
      );

      expect(job.isActive, isFalse);
      expect(job.duration, const Duration(minutes: 2, seconds: 5));
    });
  });
}
