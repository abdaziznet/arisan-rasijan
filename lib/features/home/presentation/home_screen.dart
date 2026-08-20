import 'package:bani_rasijan/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../../../routing/app_router.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../members/presentation/providers/members_providers.dart';
import '../../periods/presentation/providers/periods_providers.dart';
import '../../periods/presentation/widgets/period_form_dialog.dart';
import '../../payments/presentation/screens/payment_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  void _signOut() {
    ref.read(authControllerProvider.notifier).signOut();
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
              const _PlaceholderPage(title: 'Arisan'),
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

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    return 'Rp${amount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final activePeriodAsync = ref.watch(activePeriodProvider);
    final isAdmin = currentMember?.isAdmin ?? false;

    return Column(
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
              ref.invalidate(activePeriodProvider);
              ref.invalidate(currentMemberProfileProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
          Row(
            children: [
              if (currentMember?.photoUrl != null &&
                  currentMember!.photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(currentMember.photoUrl!),
                )
              else
                AppAvatar(name: currentMember?.fullName ?? 'A'),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assalamu’alaikum,',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      currentMember?.fullName ?? 'Anggota Keluarga',
                      style: AppTypography.h2,
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: isAdmin ? 'Admin' : 'Anggota',
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Keluar',
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
                          onPressed: () => PeriodFormDialog.show(context),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final hostName = period.host?.fullName ?? 'Belum ditentukan';
              final address =
                  period.hostAddress ?? period.host?.address ?? 'Rumah Tuan Rumah';

              return AppCard(
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
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => PeriodFormDialog.show(
                              context,
                              period: period,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _formatDate(period.eventDate),
                      style: AppTypography.h2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Di rumah $hostName',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(address)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isAdmin) ...[
            const AppSectionHeader(title: 'Aksi Cepat Admin'),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _AdminActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Periode Baru',
                    onTap: () => PeriodFormDialog.show(context),
                  ),
                  _AdminActionButton(
                    icon: Icons.payment_outlined,
                    label: 'Catat Bayar',
                    onTap: () => onNavigate(1),
                  ),
                  _AdminActionButton(
                    icon: Icons.checklist_outlined,
                    label: 'Agenda Acara',
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
                            context,
                            'Tidak ada periode aktif.',
                          );
                        }
                      },
                      orElse: () => AppSnackbar.show(
                        context,
                        'Tidak ada periode aktif.',
                      ),
                    ),
                  ),
                  _AdminActionButton(
                    icon: Icons.casino_outlined,
                    label: 'Mulai Kocokan',
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
                            context,
                            'Tidak ada periode aktif.',
                          );
                        }
                      },
                      orElse: () => AppSnackbar.show(
                        context,
                        'Tidak ada periode aktif.',
                      ),
                    ),
                  ),
                  _AdminActionButton(
                    icon: Icons.history,
                    label: 'Riwayat',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.history,
                    ),
                  ),
                  _AdminActionButton(
                    icon: Icons.photo_library,
                    label: 'Galeri',
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
                            context,
                            'Tidak ada periode aktif.',
                          );
                        }
                      },
                      orElse: () => AppSnackbar.show(
                        context,
                        'Tidak ada periode aktif.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppSectionHeader(
            title: 'Ringkasan keluarga',
            actionLabel: 'Daftar Anggota',
            onAction: () => Navigator.pushNamed(context, AppRouter.members),
          ),
          const SizedBox(height: AppSpacing.sm),
          activePeriodAsync.maybeWhen(
            data: (period) => _SummaryCard(
              icon: Icons.receipt_long_outlined,
              title: 'Iuran Saya',
              value: 'Belum dibayar',
              detail: period?.contributionAmount != null
                  ? '${_formatCurrency(period!.contributionAmount!)} periode ini'
                  : 'Rp100.000 periode ini',
              color: AppColors.warning,
              onTap: () => onNavigate(1),
            ),
            orElse: () => _SummaryCard(
              icon: Icons.receipt_long_outlined,
              title: 'Iuran Saya',
              value: 'Belum dibayar',
              detail: 'Rp100.000 periode ini',
              color: AppColors.warning,
              onTap: () => onNavigate(1),
            ),
          ),
          _SummaryCard(
            icon: Icons.savings_outlined,
            title: 'Kas Gathering',
            value: 'Rp4.250.000',
            detail: '10% dari iuran dialokasikan',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, AppRouter.gathering),
          ),
          activePeriodAsync.maybeWhen(
            data: (period) => _SummaryCard(
              icon: Icons.emoji_events_outlined,
              title: 'Pemenang Terakhir',
              value: period?.winner?.fullName ?? 'Belum ada',
              detail: period != null
                  ? 'Periode #${period.periodNumber} · tuan rumah berikutnya'
                  : 'Belum ada data',
              color: AppColors.accent,
              onTap: () => onNavigate(2),
            ),
            orElse: () => _SummaryCard(
              icon: Icons.emoji_events_outlined,
              title: 'Pemenang Terakhir',
              value: 'Budi Rasijan',
              detail: 'Periode #9 · tuan rumah berikutnya',
              color: AppColors.accent,
              onTap: () => onNavigate(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Untuk keluarga'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRouter.members),
              child: const Row(
                children: [
                  Icon(Icons.people_outline, color: AppColors.primary),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Anggota Keluarga',
                          style: AppTypography.bodyMedium,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Lihat semua anggota & kontak keluarga',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
],
);
}

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text(
          'Anda harus masuk kembali menggunakan email untuk mengakses aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.primary),
        label: Text(label, style: AppTypography.caption),
        onPressed: onTap,
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => AppEmptyState(
        title: title,
        message: 'Fitur ini akan dibangun pada tahap berikutnya.',
      );
}

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentMember?.photoUrl != null &&
              currentMember!.photoUrl!.isNotEmpty)
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(currentMember.photoUrl!),
            )
          else
            AppAvatar(name: currentMember?.fullName ?? 'A', radius: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            currentMember?.fullName ?? 'Anggota Keluarga',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppBadge(
            label: currentMember?.isAdmin == true ? 'Admin' : 'Anggota',
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil Saya'),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.profileCompletion,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.people_outline),
            label: const Text('Daftar Anggota Keluarga'),
            onPressed: () => Navigator.pushNamed(context, AppRouter.members),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Keluar dari Akun',
            icon: Icons.logout,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
