import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/daily_prayer.dart';
import '../domain/featured_prayers.dart';

class DailyPrayerDetailScreen extends StatelessWidget {
  const DailyPrayerDetailScreen({super.key, required this.prayer});
  final DailyPrayer prayer;

  @override
  Widget build(BuildContext context) {
    final selectedContext = FeaturedPrayers.contextFor(prayer.id);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(prayer.group),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(prayer.title, style: AppTypography.h2),
                if (selectedContext.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppBadge(
                      label: selectedContext,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.card,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    prayer.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTypography.h2.copyWith(
                      fontSize: 28,
                      height: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (prayer.transliteration.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _TextSection(
                    title: 'Latin',
                    content: prayer.transliteration,
                    color: AppColors.primaryDark,
                  ),
                ],
                if (prayer.translation.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _TextSection(
                    title: 'Artinya',
                    content: prayer.translation,
                    color: AppColors.textPrimary,
                  ),
                ],
                if (prayer.reference.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ReferenceSection(reference: prayer.reference),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection(
      {required this.title, required this.content, required this.color});
  final String title;
  final String content;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(content, style: AppTypography.body.copyWith(color: color)),
        ]),
      );
}

class _ReferenceSection extends StatelessWidget {
  const _ReferenceSection({required this.reference});
  final String reference;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: AppRadii.card,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Keterangan & rujukan',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: AppSpacing.xs),
          Text(reference,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      );
}
