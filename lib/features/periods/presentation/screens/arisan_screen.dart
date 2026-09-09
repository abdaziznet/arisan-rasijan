import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/period_model.dart';
import '../providers/periods_providers.dart';
import '../widgets/period_form_dialog.dart';

/// Menu tab "Arisan": info periode berjalan + daftar semua periode arisan.
///
/// Per PRD §5.1 (Fitur C — Jadwal & Periode Arisan), layar ini menampilkan
/// periode aktif beserta aksi acara (agenda, kocokan, galeri) untuk admin,
/// plus riwayat semua periode.
class ArisanScreen extends ConsumerWidget {
  const ArisanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(periodsControllerProvider);
    final isAdmin = ref.watch(currentMemberProfileProvider).valueOrNull?.isAdmin ??
        false;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(periodsControllerProvider);
        ref.invalidate(activePeriodProvider);
      },
      child: periodsAsync.when(
        loading: () => ListView(
          children: const [
            SizedBox(height: 200, child: AppLoading()),
          ],
        ),
        error: (err, _) =>
            AppErrorState(onRetry: () => ref.invalidate(periodsControllerProvider)),
        data: (periods) {
          if (periods.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SizedBox(height: AppSpacing.xl),
                AppEmptyState(
                  title: 'Belum ada periode arisan',
                  message: isAdmin
                      ? 'Buat periode pertama untuk mulai arisan keluarga.'
                      : 'Belum ada jadwal arisan yang dibuat pengurus.',
                ),
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Buat Periode Baru',
                    icon: Icons.add,
                    onPressed: () => PeriodFormDialog.show(context),
                  ),
                ],
              ],
            );
          }

          // Sorted: periode terbaru (period_number terbesar) di atas.
          final sorted = [...periods]
            ..sort((a, b) => b.periodNumber.compareTo(a.periodNumber));
          final active = sorted.firstWhere(
            (p) => p.status != 'completed',
            orElse: () => sorted.first,
          );
          final history = sorted
              .where((p) => p.id != active.id)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ===== Header =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('Arisan Keluarga', style: AppTypography.h2),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ===== Periode Aktif =====
              AppSectionHeader(
                title: 'Periode Berjalan',
                actionLabel: isAdmin ? 'Periode Baru' : null,
                onAction: isAdmin
                    ? () => PeriodFormDialog.show(context)
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActivePeriodCard(period: active, isAdmin: isAdmin),
              const SizedBox(height: AppSpacing.lg),

              // ===== Riwayat Periode =====
              AppSectionHeader(
                title: 'Riwayat Periode',
                actionLabel: 'Lihat Semua',
                onAction: () => Navigator.pushNamed(context, AppRouter.history),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (history.isEmpty)
                const AppEmptyState(
                  title: 'Belum ada riwayat',
                  message: 'Periode selesai akan muncul di sini.',
                )
              else
                ...history.map(
                  (p) => _PeriodHistoryTile(
                    period: p,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.history,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivePeriodCard extends StatelessWidget {
  const _ActivePeriodCard({required this.period, required this.isAdmin});
  final PeriodModel period;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final hostName = period.host?.fullName ?? 'Belum ditentukan';
    final address =
        period.hostAddress ?? period.host?.address ?? 'Rumah Tuan Rumah';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge(
                label: 'ARISAN PERIODE #${period.periodNumber}',
              ),
              _StatusBadge(status: period.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            Formatters.formatDate(period.eventDate),
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.home_rounded,
            iconColor: AppColors.primary,
            label: 'Tuan Rumah',
            value: 'Di rumah $hostName',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.accent,
            label: 'Lokasi Acara',
            value: address,
          ),
          if (period.contributionAmount != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.payments_rounded,
              iconColor: AppColors.success,
              label: 'Iuran Anggota',
              value: Formatters.formatCurrency(period.contributionAmount!),
            ),
          ],
          if (period.winner != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.accent,
              label: 'Pemenang',
              value: period.winner!.fullName,
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.checklist_rounded,
                    label: 'Agenda Acara',
                    color: AppColors.info,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.eventChecklist,
                      arguments: period.id,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.casino_rounded,
                    label: 'Mulai Kocok',
                    color: AppColors.accent,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.draw,
                      arguments: period.id,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.gallery,
                      arguments: period.id,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('SELESAI', AppColors.textSecondary),
      'ongoing' => ('BERLANGSUNG', AppColors.info),
      _ => ('AKAN DATANG', AppColors.warning),
    };
    return AppBadge(label: label, color: color);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            Text(value, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
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
    ),
  );
}

class _PeriodHistoryTile extends StatelessWidget {
  const _PeriodHistoryTile({required this.period, required this.onTap});
  final PeriodModel period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hostName = period.host?.fullName ?? 'Belum ditentukan';
    final isCompleted = period.status == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Row(
            children: [
              AppBadge(label: '#${period.periodNumber}'),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDate(period.eventDate),
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted && period.winner != null
                          ? 'Menang: ${period.winner!.fullName}'
                          : 'Tuan Rumah: $hostName',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}