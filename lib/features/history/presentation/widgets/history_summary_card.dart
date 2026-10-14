import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/period_history_model.dart';

/// Card ringkasan statistik riwayat arisan keluarga Bani Rasijan.
/// Menampilkan total periode selesai, total dana tersalurkan, dan pemenang unik.
class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.history,
  });

  final List<PeriodHistoryModel> history;

  int get _totalPeriods => history.length;

  double get _totalCollected => history.fold<double>(
        0.0,
        (sum, item) => sum + item.totalCollected,
      );

  int get _uniqueWinners {
    final winners = history
        .map((e) => e.winnerId.isNotEmpty ? e.winnerId : e.winnerName)
        .where((name) => name.trim().isNotEmpty)
        .toSet();
    return winners.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative trophy icon
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'ARSIP KELUARGA',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Transparan',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  'Kilas Balik Arisan',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jejak kebersamaan & amanah keluarga Bani Rasijan',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3 Statistics Column
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: AppRadii.small,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Stat 1: Total Periode
                      Expanded(
                        child: _StatTile(
                          icon: Icons.history_rounded,
                          value: '$_totalPeriods',
                          label: 'Periode',
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      // Stat 2: Total Dana
                      Expanded(
                        flex: 2,
                        child: _StatTile(
                          icon: Icons.payments_rounded,
                          value: Formatters.formatCurrency(_totalCollected),
                          label: 'Dana Tersalurkan',
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      // Stat 3: Pemenang Unik
                      Expanded(
                        child: _StatTile(
                          icon: Icons.emoji_events_rounded,
                          value: '$_uniqueWinners',
                          label: 'Pemenang',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
