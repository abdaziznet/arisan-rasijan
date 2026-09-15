import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/draw_model.dart';
import '../../../periods/presentation/providers/periods_providers.dart';

class WinnerRevealDialog extends ConsumerStatefulWidget {
  const WinnerRevealDialog({super.key, required this.draw});
  final DrawModel draw;

  @override
  ConsumerState<WinnerRevealDialog> createState() => _WinnerRevealDialogState();
}

class _WinnerRevealDialogState extends ConsumerState<WinnerRevealDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return 'Rp${amount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(activePeriodProvider);
    final periodNumber = periodAsync.valueOrNull?.periodNumber ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        size: 50,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '🎉 SELAMAT! 🎉',
                      style:
                          AppTypography.h2.copyWith(color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadii.card,
                      ),
                      child: Column(
                        children: [
                          AppAvatar(
                            name: widget.draw.winnerName ?? 'Pemenang',
                            radius: 32,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            widget.draw.winnerName ?? 'Nama Tidak Diketahui',
                            style: AppTypography.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Pemenang Periode #${periodNumber}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.draw.totalCollected != null &&
                              widget.draw.totalCollected! > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _formatCurrency(widget.draw.totalCollected!),
                              style: AppTypography.h1.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.home_rounded,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'Tuan Rumah Berikutnya\n(Periode #${periodNumber + 1})',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Tutup',
                        icon: Icons.check,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
