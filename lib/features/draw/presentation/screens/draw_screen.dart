import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/draw_model.dart';
import '../providers/draw_providers.dart';
import '../widgets/draw_candidate_tile.dart';
import '../widgets/winner_reveal_dialog.dart';
import '../widgets/draw_history_list.dart';

class DrawScreen extends ConsumerWidget {
  const DrawScreen({super.key, required this.periodId});
  final String periodId;

  void _showErrorSnackbar(BuildContext context, Object? error) {
    AppSnackbar.show(
      context,
      'Gagal menjalankan kocokan: ${error.toString()}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<DrawModel?>>(
      drawControllerProvider,
      (_, state) => switch (state) {
        AsyncError(:final error) => _showErrorSnackbar(context, error),
        AsyncData(:final value) when value != null => _showWinnerDialog(context, value),
        _ => null,
      },
    );

    final candidatesAsync = ref.watch(drawCandidatesForPeriodProvider(periodId));
    final drawState = ref.watch(drawControllerProvider);
    final historyAsync = ref.watch(drawHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kocokan Arisan'),
      ),
      body: candidatesAsync.when(
        loading: () => const AppLoading(),
        error: (err, stack) => AppErrorState(onRetry: () {
          ref.invalidate(drawCandidatesForPeriodProvider(periodId));
        }),
        data: (candidates) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(drawCandidatesForPeriodProvider(periodId));
              ref.invalidate(drawHistoryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Header info
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.casino_outlined, color: AppColors.primary),
                          SizedBox(width: AppSpacing.sm),
                          Text('Kandidat Pemenang', style: AppTypography.h3),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        candidates.isEmpty
                            ? 'Semua anggota aktif sudah pernah menang. Siklus direset.'
                            : '${candidates.length} kandidat (pemenang sebelumnya dikecualikan)',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Candidates list
                if (candidates.isEmpty)
                  const AppEmptyState(
                    title: 'Siklus Lengkap',
                    message: 'Semua anggota aktif sudah pernah menang. Kocokan berikutnya akan melibatkan semua anggota kembali.',
                  )
                else
                  Column(
                    children: candidates.map((member) => DrawCandidateTile(member: member)).toList(),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: drawState.isLoading ? 'Mengocok...' : 'Mulai Kocokan',
                    icon: Icons.casino_outlined,
                    isLoading: drawState.isLoading,
                    onPressed: drawState.isLoading || candidates.isEmpty
                        ? null
                        : () => _showConfirmationDialog(context, ref),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // History section
                AppSectionHeader(
                  title: 'Riwayat Pemenang',
                  actionLabel: 'Segarkan',
                  onAction: () => ref.invalidate(drawHistoryStreamProvider),
                ),
                const SizedBox(height: AppSpacing.sm),
                DrawHistoryList(historyAsync: historyAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Kocokan'),
        content: const Text(
          'Apakah Anda yakin ingin memulai kocokan arisan? '
          'Pemenang akan ditentukan secara acak dan periode berikutnya '
          'akan dibuat secara otomatis dengan pemenang sebagai tuan rumah. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(drawControllerProvider.notifier).runDraw(periodId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Ya, Mulai Kocokan'),
          ),
        ],
      ),
    );
  }

  void _showWinnerDialog(BuildContext context, DrawModel draw) {
    // We need winner name - would need to fetch from members or pass in dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WinnerRevealDialog(draw: draw),
    );
  }
}