import 'package:bani_rasijan/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_components.dart';
import '../../../routing/app_router.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../members/presentation/providers/members_providers.dart';
import '../../periods/presentation/providers/periods_providers.dart';
import '../../periods/presentation/screens/arisan_screen.dart';
import '../../periods/presentation/widgets/period_form_dialog.dart';
import '../../payments/presentation/screens/payment_list_screen.dart';
import '../../payments/presentation/providers/payments_providers.dart';
import '../../gathering/presentation/providers/gathering_providers.dart';

final _adminQuickActionsExpandedProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    ref.invalidate(currentMemberProfileProvider);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              _HomeOverview(
                onNavigate: (index) => setState(() => _index = index),
                onSignOut: _signOut,
              ),
              const PaymentListScreen(),
              const ArisanScreen(),
              _ProfilePage(onSignOut: _signOut),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Iuran',
            ),
            NavigationDestination(
              icon: Icon(Icons.card_giftcard_outlined),
              selectedIcon: Icon(Icons.card_giftcard),
              label: 'Arisan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      );
}

class _HomeOverview extends ConsumerWidget {
  const _HomeOverview({required this.onNavigate, required this.onSignOut});
  final ValueChanged<int> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalGatheringFund = ref.watch(fundBalanceProvider);
    final areAdminQuickActionsExpanded =
        ref.watch(_adminQuickActionsExpandedProvider);

    final connectionStatus = ref.watch(connectionStatusProvider);
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final session = ref.watch(currentSessionProvider).valueOrNull;
    final googleName = session?.user.userMetadata?['full_name'] as String? ??
        session?.user.userMetadata?['name'] as String?;
    final googleAvatar = session?.user.userMetadata?['avatar_url'] as String? ??
        session?.user.userMetadata?['picture'] as String?;

    final displayName =
        (currentMember?.fullName != null && currentMember!.fullName.isNotEmpty)
            ? currentMember.fullName
            : (googleName ?? 'Anggota Keluarga');

    final displayPhoto =
        (currentMember?.photoUrl != null && currentMember!.photoUrl!.isNotEmpty)
            ? currentMember.photoUrl
            : googleAvatar;

    final activePeriodAsync = ref.watch(activePeriodProvider);
    final isAdmin = currentMember?.isAdmin ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
      child: Column(
        children: [
          if (connectionStatus.value == ConnectionStatus.offline)
            Container(
              color: AppColors.error,
              padding: const EdgeInsets.all(AppSpacing.sm),
              width: double.infinity,
              child: const Text(
                'Anda sedang offline. Data mungkin tidak terbaru.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(_adminQuickActionsExpandedProvider.notifier).state = false;
                ref.invalidate(activePeriodProvider);
                ref.invalidate(currentMemberProfileProvider);
                ref.invalidate(currentMemberHasPaidProvider);
                ref.invalidate(fundLedgerProvider);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  // Hero Greeting Card (Emerald Gradient)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            if (displayPhoto != null && displayPhoto.isNotEmpty)
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(displayPhoto),
                              )
                            else
                              AppAvatar(name: displayName, radius: 24),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assalamu’alaikum,',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: AppTypography.h2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white, size: 20),
                            tooltip: 'Keluar',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showLogoutDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Active Period Card
                  activePeriodAsync.when(
                    loading: () => const AppCard(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => AppCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('Gagal memuat periode arisan: $err'),
                    ),
                    data: (period) {
                      if (period == null) {
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              const AppBadge(label: 'ARISAN BERIKUTNYA'),
                              const SizedBox(height: AppSpacing.md),
                              const Text(
                                'Belum ada periode aktif',
                                style: AppTypography.h3,
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Buat Periode Baru'),
                                  onPressed: () =>
                                      PeriodFormDialog.show(context),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      final hostName =
                          period.host?.fullName ?? 'Belum ditentukan';
                      final address = period.hostAddress ??
                          period.host?.address ??
                          'Rumah Tuan Rumah';

                      return Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryDark,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -54,
                              right: -34,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -72,
                              left: -36,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: Text(
                                          'ARISAN PERIODE #${period.periodNumber}',
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (isAdmin)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.14),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            tooltip: 'Ubah periode arisan',
                                            icon: const Icon(Icons.edit_outlined,
                                                size: 20, color: Colors.white),
                                            onPressed: () => PeriodFormDialog.show(
                                              context,
                                              period: period,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    Formatters.formatDate(period.eventDate),
                                    style: AppTypography.h2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _PeriodDetailRow(
                                    icon: Icons.home_rounded,
                                    label: 'Tuan Rumah',
                                    value: 'Di rumah $hostName',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _PeriodDetailRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'Lokasi Acara',
                                    value: address,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Admin Quick Actions Grid
                  if (isAdmin) ...[
                    const AppSectionHeader(title: 'Aksi Cepat Admin'),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedSize(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: LayoutBuilder(builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth < 360
                          ? 3
                          : constraints.maxWidth >= 600
                              ? 5
                              : 4;
                      final childAspectRatio = crossAxisCount == 3
                          ? 0.78
                          : crossAxisCount == 4
                              ? 0.62
                              : 0.82;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.mdSm,
                        crossAxisSpacing: AppSpacing.mdSm,
                        childAspectRatio: childAspectRatio,
                        children: [
                          _AdminActionCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'Periode Baru',
                            color: AppColors.primary,
                            onTap: () => PeriodFormDialog.show(context),
                          ),
                          _AdminActionCard(
                            icon: Icons.receipt_long_rounded,
                            label: 'Catat Iuran',
                            color: AppColors.info,
                            onTap: () => onNavigate(1),
                          ),
                          _AdminActionCard(
                            icon: Icons.event_note_rounded,
                            label: 'Agenda Acara',
                            color: AppColors.primaryDark,
                            onTap: () => activePeriodAsync.maybeWhen(
                              data: (period) {
                                if (period != null) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.eventChecklist,
                                    arguments: period.id,
                                  );
                                } else {
                                  AppSnackbar.show(
                                      context, 'Tidak ada periode aktif.');
                                }
                              },
                              orElse: () => AppSnackbar.show(
                                  context, 'Tidak ada periode aktif.'),
                            ),
                          ),
                          if (!areAdminQuickActionsExpanded)
                            _AdminActionCard(
                              icon: Icons.grid_view_rounded,
                              label: 'Semua Menu',
                              color: AppColors.textSecondary,
                              onTap: () => ref
                                  .read(_adminQuickActionsExpandedProvider.notifier)
                                  .state = true,
                            ),
                          if (areAdminQuickActionsExpanded) ...[
                            _AdminActionCard(
                              icon: Icons.celebration_rounded,
                              label: 'Kocokan',
                              color: AppColors.accent,
                              onTap: () => activePeriodAsync.maybeWhen(
                                data: (period) {
                                  if (period != null) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.draw,
                                      arguments: period.id,
                                    );
                                  } else {
                                    AppSnackbar.show(
                                        context, 'Tidak ada periode aktif.');
                                  }
                                },
                                orElse: () => AppSnackbar.show(
                                    context, 'Tidak ada periode aktif.'),
                              ),
                            ),
                            _AdminActionCard(
                              icon: Icons.timeline_rounded,
                              label: 'Riwayat',
                              color: AppColors.orange,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRouter.history),
                            ),
                            _AdminActionCard(
                              icon: Icons.photo_outlined,
                              label: 'Galeri',
                              color: AppColors.success,
                              onTap: () => activePeriodAsync.maybeWhen(
                                data: (period) {
                                  if (period != null) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.gallery,
                                      arguments: period.id,
                                    );
                                  } else {
                                    AppSnackbar.show(
                                        context, 'Tidak ada periode aktif.');
                                  }
                                },
                                orElse: () => AppSnackbar.show(
                                    context, 'Tidak ada periode aktif.'),
                              ),
                            ),
                            _AdminActionCard(
                              icon: Icons.tune_rounded,
                              label: 'Pengaturan',
                              color: AppColors.textSecondary,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRouter.adminSettings,
                              ),
                            ),
                            _AdminActionCard(
                              icon: Icons.keyboard_arrow_up_rounded,
                              label: 'Ringkas',
                              color: AppColors.textSecondary,
                              onTap: () => ref
                                  .read(_adminQuickActionsExpandedProvider.notifier)
                                  .state = false,
                            ),
                          ],
                        ],
                      );
                    }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Ringkasan Keluarga Section
                  AppSectionHeader(
                    title: 'Ringkasan Keluarga',
                    actionLabel: 'Daftar Anggota',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRouter.members),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (context, ref, _) {
                      final hasPaid = ref.watch(currentMemberHasPaidProvider);
                      return activePeriodAsync.maybeWhen(
                        data: (period) => _SummaryCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Iuran Saya',
                          value: hasPaid.valueOrNull == true
                              ? 'Sudah lunas ✓'
                              : 'Belum dibayar',
                          detail: period?.contributionAmount != null
                              ? '${Formatters.formatCurrency(period!.contributionAmount!)} periode ini'
                              : 'Rp100.000 periode ini',
                          color: hasPaid.valueOrNull == true
                              ? AppColors.success
                              : AppColors.warning,
                          onTap: () => onNavigate(1),
                        ),
                        orElse: () => _SummaryCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Iuran Saya',
                          value: hasPaid.valueOrNull == true
                              ? 'Sudah lunas ✓'
                              : 'Belum dibayar',
                          detail: 'Rp100.000 periode ini',
                          color: hasPaid.valueOrNull == true
                              ? AppColors.success
                              : AppColors.warning,
                          onTap: () => onNavigate(1),
                        ),
                      );
                    },
                  ),
                  _SummaryCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Kas Gathering',
                    value: totalGatheringFund.when(
                      data: (total) => Formatters.formatCurrency(total),
                      loading: () => 'Memuat...',
                      error: (_, __) => 'Rp0',
                    ),
                    detail: 'Total kas dari seluruh periode',
                    color: AppColors.primary,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.gathering),
                  ),
                  activePeriodAsync.maybeWhen(
                    data: (period) => _SummaryCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Pemenang Terakhir',
                      value: period?.winner?.fullName ?? 'Belum ada',
                      detail: period != null
                          ? 'Periode #${period.periodNumber} · Tuan Rumah Berikutnya'
                          : 'Belum ada data',
                      color: AppColors.accent,
                      onTap: () => onNavigate(2),
                    ),
                    orElse: () => _SummaryCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Pemenang Terakhir',
                      value: 'Budi Rasijan',
                      detail: 'Periode #9 · Tuan Rumah Berikutnya',
                      color: AppColors.accent,
                      onTap: () => onNavigate(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Menu Pintasan Keluarga
                  const AppSectionHeader(title: 'Untuk Keluarga'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.members),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.people_alt_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daftar Anggota Keluarga',
                                    style: AppTypography.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Lihat seluruh kerabat, kontak, & silsilah',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Keluar dari akun?',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Anda harus masuk kembali menggunakan akun Google untuk mengakses aplikasi.',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onSignOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodDetailRow extends StatelessWidget {
  const _PeriodDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.mdSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.14),
                  color.withValues(alpha: 0.055),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          button: true,
          label: '$title, $value. $detail',
          child: AppCard(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(value, style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.xs),
                        Text(detail, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final session = ref.watch(currentSessionProvider).valueOrNull;
    final googleName = session?.user.userMetadata?['full_name'] as String? ??
        session?.user.userMetadata?['name'] as String?;
    final googleAvatar = session?.user.userMetadata?['avatar_url'] as String? ??
        session?.user.userMetadata?['picture'] as String?;

    final displayName =
        (currentMember?.fullName != null && currentMember!.fullName.isNotEmpty)
            ? currentMember.fullName
            : (googleName ?? 'Anggota Keluarga');

    final displayPhoto =
        (currentMember?.photoUrl != null && currentMember!.photoUrl!.isNotEmpty)
            ? currentMember.photoUrl
            : googleAvatar;

    final email = session?.user.email ?? 'Keluarga Bani Rasijan';
    final phone = currentMember?.phoneNumber ?? '-';
    final address = currentMember?.address ?? '-';
    final isAdmin = currentMember?.isAdmin ?? false;
    final hasWon = currentMember?.hasWonBefore ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Header Hero Profile Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 3,
                        ),
                      ),
                    ),
                    if (displayPhoto != null && displayPhoto.isNotEmpty)
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: NetworkImage(displayPhoto),
                      )
                    else
                      AppAvatar(name: displayName, radius: 42),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  displayName,
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.family_restroom_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isAdmin ? 'Pengurus Arisan' : 'Anggota Keluarga',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Stats Grid
          Row(
            children: [
              Expanded(
                child: _ProfileStatCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Status',
                  value:
                      currentMember?.isActive == false ? 'Non-Aktif' : 'Aktif',
                  color: currentMember?.isActive == false
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ProfileStatCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Dapat Arisan',
                  value: hasWon ? 'Sudah' : 'Belum',
                  color: hasWon ? AppColors.accent : AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Section 1: Info Kontak & Detail
          const AppSectionHeader(title: 'Detail Anggota'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Nomor Telepon',
                  value: phone,
                ),
                const Divider(height: 1),
                _ProfileInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Rumah',
                  value: address,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 2: Navigasi Akun
          const AppSectionHeader(title: 'Aksi & Navigasi'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _ProfileMenuTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profil Saya',
                  subtitle: 'Ubah nama, nomor HP, alamat, & foto',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.profileCompletion,
                  ),
                ),
                const Divider(height: 1),
                _ProfileMenuTile(
                  icon: Icons.people_outline,
                  title: 'Daftar Anggota Keluarga',
                  subtitle: 'Lihat seluruh kerabat & pengurus',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.members,
                  ),
                ),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  _ProfileMenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Pengaturan Admin',
                    subtitle: 'Atur persentase kas gathering & visibilitas voting',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.adminSettings,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Tombol Keluar dari Akun
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Keluar dari Akun',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onSignOut,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Footer Versi Aplikasi
          Center(
            child: Text(
              'BANI RASIJAN v1.0.0 · Arisan Keluarga',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
