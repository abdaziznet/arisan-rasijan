import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/draw_model.dart';
import '../providers/draw_providers.dart';

class DrawHistoryList extends ConsumerWidget {
  const DrawHistoryList({super.key, required this.historyAsync});
  final AsyncValue<List<DrawHistoryModel>> historyAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return historyAsync.when(
      loading: () => const AppLoading(),
      error: (err, stack) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppErrorState(
          onRetry: () => ref.invalidate(drawHistoryStreamProvider),
        ),
      ),
      data: (history) {
        if (history.isEmpty) {
          return const AppEmptyState(
            title: 'Belum Ada Riwayat',
            message: 'Riwayat pemenang akan muncul di sini setelah kocokan pertama.',
          );
        }
        return Column(
          children: history.map((draw) => DrawHistoryTile(draw: draw)).toList(),
        );
      },
    );
  }
}

class DrawHistoryTile extends StatelessWidget {
  const DrawHistoryTile({super.key, required this.draw});
  final DrawHistoryModel draw;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: AppRadii.card,
              ),
              child: const Icon(Icons.emoji_events_outlined, color: AppColors.accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draw.winnerName,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Periode #${draw.periodNumber} • ${_formatDate(draw.createdAt)}',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const AppBadge(label: 'Pemenang', color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}