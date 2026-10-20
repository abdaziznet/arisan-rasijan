import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/tahlil_reading.dart';
import 'tahlilan_providers.dart';

class TahlilanScreen extends ConsumerStatefulWidget {
  const TahlilanScreen({super.key});

  @override
  ConsumerState<TahlilanScreen> createState() => _TahlilanScreenState();
}

class _TahlilanScreenState extends ConsumerState<TahlilanScreen> {
  bool _largeArabicText = false;

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(tahlilanReadingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bacaan Tahlilan'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _largeArabicText = !_largeArabicText),
              icon: const Icon(Icons.text_increase_rounded),
              label: Text(_largeArabicText ? 'A−' : 'A+'),
              style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: readingsAsync.when(
              loading: () => const AppLoading(),
              error: (_, __) => _TahlilanError(
                onRetry: () => ref.invalidate(tahlilanReadingsProvider),
              ),
              data: (readings) => _buildReadings(context, readings),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadings(BuildContext context, List<TahlilReading> readings) {
    if (readings.isEmpty) {
      return const AppEmptyState(
        title: 'Bacaan belum tersedia',
        message: 'Daftar bacaan tahlilan belum dapat ditampilkan.',
        icon: Icons.menu_book_rounded,
      );
    }

    final arabicFontSize = _largeArabicText ? 36.0 : 30.0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: readings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _TahlilanIntro(count: readings.length);

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _TahlilanReadingCard(
            reading: readings[index - 1],
            sequence: index,
            arabicFontSize: arabicFontSize,
          ),
        );
      },
    );
  }
}

class _TahlilanIntro extends StatelessWidget {
  const _TahlilanIntro({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.hero,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppRadii.input,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bacaan bersama keluarga',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$count bacaan • Arab dan artinya',
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TahlilanReadingCard extends StatelessWidget {
  const _TahlilanReadingCard({
    required this.reading,
    required this.sequence,
    required this.arabicFontSize,
  });

  final TahlilReading reading;
  final int sequence;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBadge(
                  label: sequence.toString().padLeft(2, '0'),
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reading.title, style: AppTypography.h3),
                      if (reading.repeat > 1) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.repeat_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Dibaca ${reading.repeat} kali',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (reading.prefix != null &&
                reading.prefix!.arabic.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _PrefixReading(
                prefix: reading.prefix!,
                arabicFontSize: arabicFontSize,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.045),
                borderRadius: AppRadii.card,
              ),
              child: Text(
                reading.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(
                  fontSize: arabicFontSize,
                  height: 2.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (reading.latin.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _LabeledReadingText(label: 'LATIN', text: reading.latin),
            ],
            if (reading.translation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _LabeledReadingText(
                label: 'ARTI',
                text: reading.translation,
              ),
            ],
          ],
        ),
      );
}

class _PrefixReading extends StatelessWidget {
  const _PrefixReading({
    required this.prefix,
    required this.arabicFontSize,
  });

  final TahlilPrefix prefix;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BACAAN PEMBUKA',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prefix.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(
                fontSize: arabicFontSize < 32 ? 26 : 30,
                height: 1.9,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (prefix.latin.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _LabeledReadingText(label: 'LATIN', text: prefix.latin),
            ],
            if (prefix.translation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _LabeledReadingText(label: 'ARTI', text: prefix.translation),
            ],
          ],
        ),
      );
}

class _LabeledReadingText extends StatelessWidget {
  const _LabeledReadingText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: AppTypography.body.copyWith(height: 1.6)),
        ],
      );
}

class _TahlilanError extends StatelessWidget {
  const _TahlilanError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Bacaan tahlilan belum dapat dibuka.',
                  style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
}
