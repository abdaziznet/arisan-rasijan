import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/daily_prayer.dart';
import '../domain/featured_prayers.dart';
import 'daily_prayer_detail_screen.dart';
import 'daily_prayer_providers.dart';

class DailyPrayersScreen extends ConsumerStatefulWidget {
  const DailyPrayersScreen({super.key, this.initialPrayerId});
  final int? initialPrayerId;

  @override
  ConsumerState<DailyPrayersScreen> createState() => _DailyPrayersScreenState();
}

class _DailyPrayersScreenState extends ConsumerState<DailyPrayersScreen> {
  final _searchController = TextEditingController();
  bool _showAll = false;
  String _query = '';
  String? _group;
  bool _initialPrayerOpened = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(DailyPrayer prayer) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DailyPrayerDetailScreen(prayer: prayer),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final prayersAsync = ref.watch(dailyPrayersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doa Keluarga'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: prayersAsync.when(
              loading: () => const AppLoading(),
              error: (_, __) => _PrayerError(
                onRetry: () => ref.invalidate(dailyPrayersProvider),
              ),
              data: (prayers) => _buildContent(prayers),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<DailyPrayer> prayers) {
    if (widget.initialPrayerId != null && !_initialPrayerOpened) {
      _initialPrayerOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final prayer in prayers) {
          if (prayer.id == widget.initialPrayerId) {
            _open(prayer);
            break;
          }
        }
      });
    }
    final allGroups = prayers.map((prayer) => prayer.group).toSet().toList()
      ..sort();
    final featuredIds = FeaturedPrayers.all.map((item) => item.id).toSet();
    final source = _showAll
        ? prayers
        : prayers.where((prayer) => featuredIds.contains(prayer.id)).toList();
    final visible = source.where((prayer) {
      final matchesQuery = _query.isEmpty ||
          prayer.title.toLowerCase().contains(_query) ||
          prayer.group.toLowerCase().contains(_query) ||
          prayer.tags.any((tag) => tag.toLowerCase().contains(_query));
      final matchesGroup =
          !_showAll || _group == null || prayer.group == _group;
      return matchesQuery && matchesGroup;
    }).toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: _PrayerIntro(
            selectedCount: featuredIds
                .intersection(prayers.map((e) => e.id).toSet())
                .length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.favorite_border_rounded),
                label: Text('Pilihan arisan'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.library_books_outlined),
                label: Text('Semua doa'),
              ),
            ],
            selected: {_showAll},
            onSelectionChanged: (value) => setState(() {
              _showAll = value.single;
              _group = null;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: _showAll
                  ? 'Cari judul, kategori, atau kata kunci'
                  : 'Cari doa pilihan',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.input,
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadii.input,
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
        ),
        if (_showAll)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _GroupFilter(
              groups: allGroups,
              selected: _group,
              onChanged: (group) => setState(() => _group = group),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    _showAll
                        ? 'Doa tidak ditemukan.'
                        : 'Belum ada doa yang cocok.',
                    style: AppTypography.body,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _PrayerTile(
                    prayer: visible[index],
                    contextLabel: _showAll
                        ? visible[index].group
                        : FeaturedPrayers.contextFor(visible[index].id),
                    onTap: () => _open(visible[index]),
                  ),
                ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Text(
            'Teks doa dan rujukan ditampilkan sesuai data dari  Kementerian Agama Republik Indonesia.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PrayerIntro extends StatelessWidget {
  const _PrayerIntro({required this.selectedCount});
  final int selectedCount;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadii.hero,
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: AppRadii.input,
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Doa untuk kebersamaan',
                  style: AppTypography.h3.copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text('$selectedCount doa pilihan • seluruh koleksi tersedia',
                  style: AppTypography.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
        ]),
      );
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile(
      {required this.prayer, required this.contextLabel, required this.onTap});
  final DailyPrayer prayer;
  final String contextLabel;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadii.input),
                child: const Icon(Icons.menu_book_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(prayer.title,
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text(contextLabel,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.primaryDark)),
                  ])),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ]),
          ),
        ),
      );
}

class _GroupFilter extends StatelessWidget {
  const _GroupFilter(
      {required this.groups, required this.selected, required this.onChanged});
  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Kategori doa',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: AppRadii.input),
        ),
        items: [
          const DropdownMenuItem<String?>(
              value: null, child: Text('Semua kategori')),
          ...groups.map((group) => DropdownMenuItem<String?>(
              value: group,
              child:
                  Text(group, maxLines: 1, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: onChanged,
      );
}

class _PrayerError extends StatelessWidget {
  const _PrayerError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.menu_book_outlined,
                color: AppColors.textSecondary, size: 40),
            const SizedBox(height: AppSpacing.sm),
            const Text('Data doa belum dapat dibuka.',
                style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi')),
          ]),
        ),
      );
}
