import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/period_history_model.dart';

/// Item kartu riwayat periode berbentuk vertical timeline.
/// Mengikuti panduan Section 13 DESIGN.md (node `● #X`, 🏆 Pemenang, 🏠 Tuan Rumah).
class HistoryTimelineItem extends StatelessWidget {
  const HistoryTimelineItem({
    super.key,
    required this.item,
    this.isFirst = false,
    this.isLast = false,
    this.highlighted = false,
    this.onTap,
  });

  final PeriodHistoryModel item;
  final bool isFirst;
  final bool isLast;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column: Line + Node
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Line Before Node
                Expanded(
                  flex: 1,
                  child: isFirst
                      ? const SizedBox.shrink()
                      : Container(
                          width: 2.5,
                          color: highlighted
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                ),

                // Timeline Node Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppColors.primary
                        : (isFirst ? AppColors.primary : AppColors.surface),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: highlighted
                          ? AppColors.accent
                          : AppColors.primary,
                      width: highlighted ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (highlighted ? AppColors.accent : AppColors.primary)
                            .withValues(alpha: 0.25),
                        blurRadius: highlighted ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '#${item.periodNumber}',
                      style: AppTypography.caption.copyWith(
                        color: (highlighted || isFirst)
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

                // Line After Node
                Expanded(
                  flex: 3,
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                          width: 2.5,
                          color: highlighted
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadii.card,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.card,
                      border: Border.all(
                        color: highlighted
                            ? AppColors.primary
                            : AppColors.divider,
                        width: highlighted ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: highlighted
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: highlighted ? 10 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header: Periode & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Periode #${item.periodNumber}',
                                      style: AppTypography.h3.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (highlighted) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'Dipilih',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      Formatters.formatDate(item.startDate),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Total Collected Badge
                            if (item.totalCollected > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(item.totalCollected),
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Total Terkumpul',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: AppSpacing.sm),

                        // Winner & Host Cards
                        Row(
                          children: [
                            // 🏆 Winner Tile
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events_rounded,
                                        size: 16,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pemenang',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            item.winnerName.isNotEmpty
                                                ? item.winnerName
                                                : '-',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),

                            // 🏠 Host Tile
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.home_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tuan Rumah',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            item.hostName.isNotEmpty
                                                ? item.hostName
                                                : '-',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
