import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/fund_ledger_model.dart';

class GatheringLedgerList extends StatelessWidget {
  const GatheringLedgerList({
    super.key,
    required this.entries,
    required this.onRefresh,
  });

  final List<FundLedgerModel> entries;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            SizedBox(height: AppSpacing.xl),
            AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada transaksi',
              message:
                  'Transaksi alokasi iuran atau pengeluaran acara gathering akan tercatat otomatis di sini.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isInflow = entry.amount >= 0;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.card,
              border: Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isInflow ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInflow
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isInflow ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              title: Text(
                _getEntryTitle(entry),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  Formatters.formatDate(entry.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              trailing: Text(
                '${isInflow ? '+' : '-'} ${Formatters.formatCurrency(entry.amount.abs())}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isInflow ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getEntryTitle(FundLedgerModel entry) {
    if (entry.description != null && entry.description!.trim().isNotEmpty) {
      return entry.description!;
    }
    switch (entry.type) {
      case 'contribution_allocation':
        return 'Alokasi Iuran Anggota';
      case 'gathering_expense':
        return 'Pengeluaran Acara Gathering';
      case 'adjustment':
        return 'Koreksi Kas (Adjustment)';
      default:
        return 'Transaksi Kas';
    }
  }
}
