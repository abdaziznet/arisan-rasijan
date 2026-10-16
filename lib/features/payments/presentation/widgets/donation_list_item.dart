import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/payment_model.dart';

class DonationListItem extends StatelessWidget {
  const DonationListItem({
    super.key,
    required this.donation,
    this.memberName,
    this.isAdmin = false,
    this.onTap,
  });

  final Donation donation;
  final String? memberName;
  final bool isAdmin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _status(donation.status);
    final method = _method(donation.paymentMethod);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadii.small,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? (memberName ?? 'Anggota') : 'Donasi saya',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          Formatters.formatDate(donation.donatedAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      Formatters.formatCurrency(donation.amount),
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _MetaPill(
                    icon: Icons.payments_outlined,
                    label: method,
                    color: AppColors.textSecondary,
                  ),
                  _MetaPill(
                    icon: status.$2,
                    label: status.$1,
                    color: status.$3,
                  ),
                  if (donation.uniqueCode != null)
                    _MetaPill(
                      icon: Icons.tag_rounded,
                      label:
                          'Kode ${donation.uniqueCode!.toString().padLeft(3, '0')}',
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              if (donation.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  donation.notes!.trim(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (donation.verificationNote?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Catatan admin: ${donation.verificationNote!.trim()}',
                  style: AppTypography.caption.copyWith(
                    color: status.$3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    isAdmin ? 'Periksa donasi' : 'Lihat detail',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (String, IconData, Color) _status(String value) => switch (value) {
        'pending_payment' => (
            'Menunggu pembayaran',
            Icons.schedule_rounded,
            AppColors.textSecondary,
          ),
        'pending_verification' => (
            'Menunggu verifikasi',
            Icons.hourglass_top_rounded,
            AppColors.info,
          ),
        'needs_review' => (
            'Perlu diperiksa',
            Icons.error_outline_rounded,
            AppColors.warning,
          ),
        'rejected' => ('Ditolak', Icons.cancel_outlined, AppColors.error),
        'expired' => (
            'Kedaluwarsa',
            Icons.timer_off_outlined,
            AppColors.textSecondary
          ),
        _ => (
            'Terverifikasi',
            Icons.check_circle_outline_rounded,
            AppColors.success
          ),
      };

  String _method(String? value) => switch (value) {
        'cash' => 'Tunai',
        'transfer' => 'Transfer',
        'qris' => 'QRIS',
        _ => 'Metode lama',
      };
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
