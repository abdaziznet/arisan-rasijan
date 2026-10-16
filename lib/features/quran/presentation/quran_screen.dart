import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../data/quran_repository.dart';
import '../domain/quran_models.dart';
import 'quran_detail_screen.dart';
import 'quran_providers.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key, this.initialSurah});
  final int? initialSurah;

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  (int, int)? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSurah != null && mounted) _open(widget.initialSurah!);
    });
  }

  Future<void> _loadLastRead() async {
    final value = await loadLastRead();
    if (mounted) setState(() => _lastRead = value);
  }

  void _open(int number) => Navigator.of(context)
      .push(MaterialPageRoute<void>(
          builder: (_) => QuranDetailScreen(number: number)))
      .then((_) => _loadLastRead());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(quranSurahsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bacaan Al-Qur’an'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              if (_lastRead != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: _ResumeCard(
                      lastRead: _lastRead!, onTap: () => _open(_lastRead!.$1)),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama, arti, atau nomor surah',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: AppRadii.input,
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadii.input,
                        borderSide: const BorderSide(color: AppColors.divider)),
                  ),
                ),
              ),
              Expanded(
                child: surahs.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _ErrorState(
                      onRetry: () => ref.invalidate(quranSurahsProvider)),
                  data: (items) {
                    final results = items
                        .where((surah) =>
                            _query.isEmpty ||
                            surah.nameLatin.toLowerCase().contains(_query) ||
                            surah.meaning.toLowerCase().contains(_query) ||
                            '${surah.number}'.contains(_query))
                        .toList(growable: false);
                    if (results.isEmpty)
                      return const Center(
                          child: Text('Surah tidak ditemukan.'));
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                      itemCount: results.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SurahTile(
                            surah: results[index],
                            onTap: () => _open(results[index].number)),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Text('Sumber bacaan: Kementerian Agama RI',
                    style: AppTypography.caption, textAlign: TextAlign.center),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.lastRead, required this.onTap});
  final (int, int) lastRead;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(
                      'Lanjutkan bacaan • Surah ${lastRead.$1}, ayat ${lastRead.$2}',
                      style: AppTypography.bodyMedium)),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ]),
          ),
        ),
      );
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});
  final QuranSurah surah;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isYasin = surah.number == 36;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isYasin
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.divider)),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${surah.number}',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.primary))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Row(children: [
                    Text(surah.nameLatin, style: AppTypography.bodyMedium),
                    if (isYasin) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const AppBadge(
                          label: 'Bacaan bersama', color: AppColors.primary)
                    ]
                  ]),
                  const SizedBox(height: 3),
                  Text(
                      '${surah.meaning} • ${surah.verseCount} ayat • ${surah.revelationPlace}',
                      style: AppTypography.caption),
                ])),
            const SizedBox(width: AppSpacing.sm),
            Text(surah.nameArabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.h3.copyWith(color: AppColors.primaryDark)),
          ]),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textSecondary, size: 40),
          const SizedBox(height: AppSpacing.sm),
          const Text(
              'Bacaan belum tersedia offline. Periksa koneksi lalu coba lagi.',
              textAlign: TextAlign.center,
              style: AppTypography.body),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi')),
        ]),
      ));
}
