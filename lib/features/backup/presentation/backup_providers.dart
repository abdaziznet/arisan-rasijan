import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../members/presentation/providers/members_providers.dart';

import '../data/backup_repository.dart';
import '../domain/backup_job.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(client: Supabase.instance.client);
});

final backupAdminAccessProvider = Provider<bool>((ref) {
  return ref.watch(currentMemberProfileProvider).valueOrNull?.isAdmin ?? false;
});

final backupJobsProvider = StreamProvider.autoDispose<List<BackupJob>>((ref) {
  return ref.watch(backupRepositoryProvider).watchRecent();
});

final lastSuccessfulBackupProvider = FutureProvider.autoDispose<BackupJob?>(
  (ref) => ref.watch(backupRepositoryProvider).lastSuccess(),
);
