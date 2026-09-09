import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';

class DrawValidationCard extends StatelessWidget {
  const DrawValidationCard({
    super.key,
    required this.isAllPaid,
    required this.isDrawDay,
    required this.isAlreadyDone,
  });

  final bool isAllPaid;
  final bool isDrawDay;
  final bool isAlreadyDone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Status Validasi Kocokan',
                style: AppTypography.h3.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ValidationRow(
            isMet: isAllPaid,
            text: isAllPaid
                ? 'Semua iuran lunas'
                : 'Belum semua anggota membayar iuran',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ValidationRow(
            isMet: isDrawDay,
            text: isDrawDay
                ? 'Hari ini adalah hari acara'
                : 'Bukan hari pelaksanaan arisan',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ValidationRow(
            isMet: !isAlreadyDone,
            text: !isAlreadyDone
                ? 'Kocokan belum dijalankan'
                : 'Kocokan sudah selesai',
          ),
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({
    required this.isMet,
    required this.text,
  });

  final bool isMet;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isMet ? AppColors.success : AppColors.error,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: isMet ? AppColors.textPrimary : AppColors.error,
              fontWeight: isMet ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
