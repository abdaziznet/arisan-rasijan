import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/gathering_event_model.dart';

class GatheringEventCard extends StatelessWidget {
  const GatheringEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.hasVoted,
  });

  final GatheringEventModel event;
  final VoidCallback onTap;
  final bool? hasVoted;

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(event.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(
                          label: statusConfig.label,
                          color: statusConfig.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (event.eventDate != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            Formatters.formatDate(event.eventDate!),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    if (event.fundUsed > 0) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Alokasi Kas: ${Formatters.formatCurrency(event.fundUsed)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Dibuat ${Formatters.formatDate(event.createdAt)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (event.status == 'voting')
                      Row(
                        children: [
                          Icon(
                            hasVoted == true
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: hasVoted == true
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            hasVoted == true
                                ? 'Suara Anda sudah tercatat'
                                : 'Belum memberikan suara',
                            style: AppTypography.caption.copyWith(
                              color: hasVoted == true
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Ketuk untuk melihat detail',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'voting':
        return const _StatusConfig(
          label: 'VOTING DIBUKA',
          color: AppColors.primary,
        );
      case 'decided':
        return const _StatusConfig(
          label: 'TUJUAN TERPILIH',
          color: AppColors.accent,
        );
      case 'completed':
        return const _StatusConfig(
          label: 'SELESAI',
          color: AppColors.success,
        );
      case 'cancelled':
        return const _StatusConfig(
          label: 'DIBATALKAN',
          color: AppColors.error,
        );
      default:
        return _StatusConfig(
          label: status.toUpperCase(),
          color: AppColors.primary,
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({required this.label, required this.color});
  final String label;
  final Color color;
}
