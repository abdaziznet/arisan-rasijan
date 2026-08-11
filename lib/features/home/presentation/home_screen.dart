import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _index,
        children: [
          _HomeOverview(onNavigate: (index) => setState(() => _index = index)),
          const _PlaceholderPage(title: 'Iuran'),
          const _PlaceholderPage(title: 'Arisan'),
          const _PlaceholderPage(title: 'Profil'),
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

class _HomeOverview extends StatelessWidget {
  const _HomeOverview({required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.md),
    children: [
      Row(
        children: [
          const AppAvatar(name: 'A'),
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
                const Text('Ahmad Rasijan', style: AppTypography.h2),
              ],
            ),
          ),
          const AppBadge(label: 'Anggota'),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge(label: 'ARISAN BERIKUTNYA'),
            const SizedBox(height: AppSpacing.md),
            Text('Minggu, 15 Oktober 2026', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Icon(Icons.home_outlined, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Di rumah Budi Rasijan')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Jl. Melati No. 17')),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      AppSectionHeader(
        title: 'Ringkasan keluarga',
        actionLabel: 'Lihat semua',
        onAction: () {},
      ),
      const SizedBox(height: AppSpacing.sm),
      _SummaryCard(
        icon: Icons.receipt_long_outlined,
        title: 'Iuran Saya',
        value: 'Belum dibayar',
        detail: 'Rp100.000 periode ini',
        color: AppColors.warning,
        onTap: () => onNavigate(1),
      ),
      _SummaryCard(
        icon: Icons.savings_outlined,
        title: 'Kas Gathering',
        value: 'Rp4.250.000',
        detail: '10% dari iuran dialokasikan',
        color: AppColors.primary,
        onTap: () => AppSnackbar.show(
          context,
          'Modul gathering akan tersedia pada fase berikutnya.',
        ),
      ),
      _SummaryCard(
        icon: Icons.emoji_events_outlined,
        title: 'Pemenang Terakhir',
        value: 'Budi Rasijan',
        detail: 'Periode #9 · tuan rumah berikutnya',
        color: AppColors.accent,
        onTap: () => onNavigate(2),
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppSectionHeader(title: 'Untuk keluarga'),
      const SizedBox(height: AppSpacing.sm),
      const AppCard(
        child: Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kenangan terbaru', style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Lihat foto kebersamaan keluarga',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ],
  );
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
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
