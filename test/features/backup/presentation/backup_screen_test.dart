import 'package:bani_rasijan/features/backup/domain/backup_job.dart';
import 'package:bani_rasijan/features/backup/presentation/backup_providers.dart';
import 'package:bani_rasijan/features/backup/presentation/backup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  final successfulJob = BackupJob(
    id: 'job-success',
    status: 'success',
    triggerType: 'scheduled',
    scope: 'full',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    finishedAt: DateTime.now().subtract(const Duration(days: 8)),
    sizeBytes: 1024 * 1024,
  );

  testWidgets('admin sees recent backup, request action and history',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupAdminAccessProvider.overrideWith((ref) => true),
          backupJobsProvider
              .overrideWith((ref) => Stream.value([successfulJob])),
          lastSuccessfulBackupProvider
              .overrideWith((ref) async => successfulJob),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup sukses terakhir:'), findsOneWidget);
    expect(find.text('Backup sekarang'), findsOneWidget);
    expect(find.text('Riwayat backup'), findsOneWidget);
    expect(find.text('Berhasil'), findsOneWidget);
  });

  testWidgets('non-admin is shown an access denied state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupAdminAccessProvider.overrideWith((ref) => false)],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );

    expect(find.text('Akses tidak tersedia'), findsOneWidget);
    expect(find.text('Backup sekarang'), findsNothing);
  });

  testWidgets('active backup disables the manual request action',
      (tester) async {
    final activeJob = BackupJob(
      id: 'job-running',
      status: 'running',
      triggerType: 'manual',
      scope: 'db_only',
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupAdminAccessProvider.overrideWith((ref) => true),
          backupJobsProvider.overrideWith((ref) => Stream.value([activeJob])),
          lastSuccessfulBackupProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.pump();

    final button =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
    expect(button.onPressed, isNull);
    expect(find.text('Backup sedang berjalan'), findsOneWidget);
  });

  testWidgets('request dialog explains database-only scope and limits notes',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupAdminAccessProvider.overrideWith((ref) => true),
          backupJobsProvider.overrideWith((ref) => Stream.value([])),
          lastSuccessfulBackupProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Backup sekarang'), findsNWidgets(2));
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    await tester.tap(find.text('Database saja'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Storage tidak diperbarui.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 200);
  });

  testWidgets('job detail shows diagnostic fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupAdminAccessProvider.overrideWith((ref) => true),
          backupJobsProvider
              .overrideWith((ref) => Stream.value([successfulJob])),
          lastSuccessfulBackupProvider
              .overrideWith((ref) async => successfulJob),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berhasil'));
    await tester.pumpAndSettle();

    expect(find.text('Detail backup'), findsOneWidget);
    expect(find.text('job-success'), findsOneWidget);
    expect(find.text('Lokasi'), findsOneWidget);
    expect(find.text('Durasi'), findsOneWidget);
  });
}
