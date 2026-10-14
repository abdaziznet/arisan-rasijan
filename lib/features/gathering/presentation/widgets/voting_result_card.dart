import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/gathering_poll_option_model.dart';

class VotingResultCard extends StatelessWidget {
  const VotingResultCard({
    super.key,
    required this.option,
    required this.voteCount,
    required this.totalVotes,
    this.isWinning = false,
  });

  final GatheringPollOptionModel option;
  final int voteCount;
  final int totalVotes;
  final bool isWinning;

  @override
  Widget build(BuildContext context) {
    final double percentage =
        totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
    final double ratio = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isWinning
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: isWinning ? AppColors.accent : AppColors.divider,
          width: isWinning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWinning) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  option.optionLabel,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: isWinning ? FontWeight.w700 : FontWeight.w600,
                    color: isWinning ? AppColors.textPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isWinning)
                const AppBadge(
                  label: 'TERPILIH',
                  color: AppColors.accent,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadii.small,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isWinning ? AppColors.accent : AppColors.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$voteCount suara',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isWinning ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isWinning ? AppColors.accent : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
