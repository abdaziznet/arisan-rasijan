import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/backup_job.dart';
import 'backup_providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _requesting = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(backupAdminAccessProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Backup')),
        body: const AppEmptyState(
          title: 'Akses tidak tersedia',
          message: 'Fitur Backup hanya tersedia untuk admin aplikasi.',
          icon: Icons.lock_outline,
        ),
      );
    }

    ref.listen<AsyncValue<List<BackupJob>>>(backupJobsProvider,
        (previous, next) {
      final previousSuccessIds = previous?.valueOrNull
              ?.where((job) => job.status == 'success')
              .map((job) => job.id)
              .toSet() ??
          <String>{};
      final hasNewSuccess = next.valueOrNull?.any(
            (job) =>
                job.status == 'success' && !previousSuccessIds.contains(job.id),
          ) ??
          false;
      if (hasNewSuccess) {
        ref.invalidate(lastSuccessfulBackupProvider);
      }
    });
    final jobsAsync = ref.watch(backupJobsProvider);
    final lastSuccessAsync = ref.watch(lastSuccessfulBackupProvider);
    final active = jobsAsync.valueOrNull?.any((job) => job.isActive) ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal:
                    constraints.maxWidth > 600 ? AppSpacing.xl : AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              children: [
                lastSuccessAsync.when(
                  loading: () => const _BackupBanner.loading(),
                  error: (_, __) => _BackupBanner.error(
                    message: 'Status backup terakhir belum dapat dimuat.',
                    onRetry: () => ref.invalidate(lastSuccessfulBackupProvider),
                  ),
                  data: (job) => _BackupBanner(lastSuccess: job),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: active ? 'Backup sedang berjalan' : 'Backup sekarang',
                  icon: active ? Icons.hourglass_top : Icons.backup_outlined,
                  isLoading: _requesting,
                  onPressed: active || _requesting ? null : _confirmRequest,
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(title: 'Riwayat backup'),
                const SizedBox(height: AppSpacing.sm),
                jobsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: AppLoading(),
                  ),
                  error: (_, __) => AppCard(
                    child: Column(
                      children: [
                        const Text('Riwayat backup belum dapat dimuat.'),
                        TextButton(
                          onPressed: () => ref.invalidate(backupJobsProvider),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                  data: (jobs) => jobs.isEmpty
                      ? const AppCard(
                          child: AppEmptyState(
                            title: 'Belum ada backup',
                            message: 'Riwayat backup akan muncul di sini.',
                            icon: Icons.inventory_2_outlined,
                          ),
                        )
                      : Column(
                          children: [
                            for (final (index, job) in jobs.indexed) ...[
                              _BackupJobTile(
                                job: job,
                                onTap: () => _showDetails(job),
                              ),
                              if (index != jobs.length - 1)
                                const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRequest() async {
    var scope = 'full';
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Backup sekarang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'full', label: Text('Lengkap')),
                    ButtonSegment(
                      value: 'db_only',
                      label: Text('Database saja'),
                    ),
                  ],
                  selected: {scope},
                  onSelectionChanged: (selected) =>
                      setDialogState(() => scope = selected.first),
                ),
                AnimatedSwitcher(
                  duration: Duration(
                    milliseconds:
                        MediaQuery.disableAnimationsOf(context) ? 0 : 180,
                  ),
                  child: scope == 'db_only'
                      ? const Padding(
                          key: ValueKey('db-only-help'),
                          padding: EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            'Storage tidak diperbarui. Salinan storage tetap dari backup lengkap terakhir.',
                            style: AppTypography.body,
                          ),
                        )
                      : const SizedBox(key: ValueKey('full-help')),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: noteController,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mulai'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }
    setState(() => _requesting = true);
    try {
      await ref.read(backupRepositoryProvider).request(
            scope: scope,
            note: noteController.text,
          );
      ref.invalidate(backupJobsProvider);
      if (mounted) {
        AppSnackbar.show(
            context, 'Job dibuat. Worker mengambilnya dalam ±1 menit.');
      }
    } catch (error) {
      final message = switch (_functionStatus(error)) {
        401 => 'Sesi berakhir, silakan login ulang',
        403 => 'Anda tidak punya akses untuk fitur ini',
        409 => 'Masih ada backup yang berjalan',
        _ => 'Gagal memulai backup. Coba lagi.',
      };
      if (mounted) AppSnackbar.show(context, message);
    } finally {
      noteController.dispose();
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _showDetails(BackupJob job) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _BackupJobDetails(job: job),
      );

  int? _functionStatus(Object error) {
    try {
      final status = (error as dynamic).status;
      return status is int ? status : null;
    } on NoSuchMethodError {
      return null;
    }
  }
}

class _BackupBanner extends StatelessWidget {
  const _BackupBanner({this.lastSuccess})
      : _loading = false,
        _error = null,
        _onRetry = null;

  const _BackupBanner.loading()
      : lastSuccess = null,
        _loading = true,
        _error = null,
        _onRetry = null;

  const _BackupBanner.error(
      {required String message, required VoidCallback onRetry})
      : lastSuccess = null,
        _loading = false,
        _error = message,
        _onRetry = onRetry;

  final BackupJob? lastSuccess;
  final bool _loading;
  final String? _error;
  final VoidCallback? _onRetry;

  @override
  Widget build(BuildContext context) {
    final age = lastSuccess == null
        ? null
        : DateTime.now()
            .difference(lastSuccess!.finishedAt ?? lastSuccess!.createdAt)
            .inDays;
    final color = _loading
        ? AppColors.info
        : _error != null || lastSuccess == null
            ? AppColors.error
            : age! > 35
                ? AppColors.warning
                : AppColors.success;
    final title = _loading
        ? 'Memuat status backup terakhir…'
        : _error ??
            (lastSuccess == null
                ? 'Belum ada backup yang berhasil'
                : 'Backup sukses terakhir: $age hari lalu');

    return AppCard(
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _loading
                  ? Icons.sync
                  : _error != null || lastSuccess == null
                      ? Icons.error_outline
                      : age! > 35
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodyMedium.copyWith(color: color)),
                  if (lastSuccess != null)
                    Text(
                      DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(
                        lastSuccess!.finishedAt ?? lastSuccess!.createdAt,
                      ),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  if (_onRetry != null)
                    TextButton(
                        onPressed: _onRetry, child: const Text('Coba lagi')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupJobTile extends StatelessWidget {
  const _BackupJobTile({required this.job, required this.onTap});
  final BackupJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (job.status) {
      'success' => AppColors.success,
      'failed' => AppColors.error,
      'running' || 'pending' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final icon = switch (job.status) {
      'success' => Icons.check_circle,
      'failed' => Icons.error,
      'running' => Icons.autorenew,
      _ => Icons.schedule,
    };
    final status = switch (job.status) {
      'success' => 'Berhasil',
      'failed' => 'Gagal',
      'running' => 'Berjalan',
      _ => 'Menunggu',
    };
    final scope = job.scope == 'full' ? 'Lengkap' : 'Database saja';
    final trigger = job.triggerType == 'scheduled' ? 'Terjadwal' : 'Manual';

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (job.status == 'running')
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    semanticsLabel: 'Backup sedang berjalan',
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 26),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status, style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$trigger · $scope',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary)),
                    Text(
                      DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                          .format(job.createdAt),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (job.error?.isNotEmpty ?? false)
                      Text(
                        job.error!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.error),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupJobDetails extends StatelessWidget {
  const _BackupJobDetails({required this.job});
  final BackupJob job;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm:ss', 'id_ID');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detail backup', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.md),
                _detail('ID', job.id),
                _detail('Status', job.status),
                _detail('Pemicu',
                    job.triggerType == 'scheduled' ? 'Terjadwal' : 'Manual'),
                _detail('Cakupan',
                    job.scope == 'full' ? 'Lengkap' : 'Database saja'),
                _detail('Catatan', job.note ?? '—'),
                _detail('Dibuat', dateFormat.format(job.createdAt)),
                _detail(
                    'Dimulai',
                    job.startedAt == null
                        ? '—'
                        : dateFormat.format(job.startedAt!)),
                _detail(
                    'Selesai',
                    job.finishedAt == null
                        ? '—'
                        : dateFormat.format(job.finishedAt!)),
                _detail('Durasi', _duration(job.duration)),
                _detail(
                    'Ukuran',
                    job.sizeBytes == null
                        ? '—'
                        : '${(job.sizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB'),
                _detail('Lokasi', job.location ?? '—'),
                if (job.status == 'failed')
                  _detail(
                      'Pesan error', job.error ?? 'Tidak ada detail error.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
            SelectableText(value, style: AppTypography.body),
          ],
        ),
      );

  static String _duration(Duration? duration) {
    if (duration == null) return '—';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return minutes > 0 ? '$minutes menit $seconds detik' : '$seconds detik';
  }
}
