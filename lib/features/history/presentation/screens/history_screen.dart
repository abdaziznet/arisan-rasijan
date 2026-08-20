import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:bani_rasijan/core/widgets/app_components.dart';
import 'package:bani_rasijan/core/theme/app_colors.dart';
import 'package:bani_rasijan/core/theme/app_spacing.dart';
import 'package:bani_rasijan/core/theme/app_typography.dart';
import 'package:bani_rasijan/core/theme/app_radii.dart';
import 'package:bani_rasijan/features/history/domain/period_history_model.dart';
import 'package:bani_rasijan/features/history/presentation/providers/history_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyStreamProvider);
    final controller = ref.watch(historyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Arisan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshHistory(),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorState(onRetry: () => controller.refreshHistory()),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada riwayat arisan', style: AppTypography.h3),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyStreamProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = history[index];
                return _PeriodHistoryCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PeriodHistoryCard extends StatelessWidget {
  const _PeriodHistoryCard({required this.item});
  final PeriodHistoryModel item;

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode ${item.periodNumber}',
                style: AppTypography.h3,
              ),
              Text(
                _formatDate(item.startDate),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _InfoChip(label: 'Tuan Rumah', value: item.hostName, icon: Icons.home),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(
                label: 'Pemenang',
                value: item.winnerName,
                icon: Icons.emoji_events,
                isWinner: true,
              ),
            ],
          ),
          if (item.totalCollected > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Terkumpul: ',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  '${item.totalCollected.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.isWinner = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _Chip(
        label: label,
        value: value,
        icon: icon,
        isWinner: isWinner,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.value,
    required this.icon,
    this.isWinner = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.success.withAlpha(25) : AppColors.primary.withAlpha(25),
        borderRadius: AppRadii.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isWinner ? AppColors.success : AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}