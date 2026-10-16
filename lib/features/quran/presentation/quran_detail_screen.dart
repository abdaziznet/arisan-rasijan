import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/quran_repository.dart';
import '../domain/quran_models.dart';
import 'quran_providers.dart';

class QuranDetailScreen extends ConsumerStatefulWidget {
  const QuranDetailScreen({super.key, required this.number});
  final int number;
  @override
  ConsumerState<QuranDetailScreen> createState() => _QuranDetailScreenState();
}

class _QuranDetailScreenState extends ConsumerState<QuranDetailScreen> {
  double _fontSize = 28;
  bool _latin = true;
  bool _translation = true;
  Set<String> _bookmarks = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await loadQuranBookmarks();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble('quran.fontSize') ?? 28;
      _latin = prefs.getBool('quran.showLatin') ?? true;
      _translation = prefs.getBool('quran.showTranslation') ?? true;
      _bookmarks = bookmarks;
      _loaded = true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran.fontSize', _fontSize);
    await prefs.setBool('quran.showLatin', _latin);
    await prefs.setBool('quran.showTranslation', _translation);
  }

  Future<void> _toggleBookmark(int verse) async {
    final key = quranBookmarkKey(widget.number, verse);
    final add = !_bookmarks.contains(key);
    await setQuranBookmark(widget.number, verse, add);
    if (mounted)
      setState(() => add ? _bookmarks.add(key) : _bookmarks.remove(key));
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
          builder: (context, updateSheet) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text('Pengaturan bacaan', style: AppTypography.h3)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Ukuran teks Arab • ${_fontSize.round()} sp',
                      style: AppTypography.bodyMedium),
                  Slider(
                      min: 20,
                      max: 40,
                      divisions: 10,
                      value: _fontSize,
                      onChanged: (value) =>
                          updateSheet(() => setState(() => _fontSize = value)),
                      onChangeEnd: (_) => _savePrefs()),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tampilkan transliterasi'),
                      value: _latin,
                      onChanged: (value) => updateSheet(() {
                            setState(() => _latin = value);
                            _savePrefs();
                          })),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tampilkan terjemahan'),
                      value: _translation,
                      onChanged: (value) => updateSheet(() {
                            setState(() => _translation = value);
                            _savePrefs();
                          })),
                ]),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(quranSurahProvider(widget.number));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Surah ${widget.number}'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              tooltip: 'Pengaturan bacaan',
              onPressed: _settings,
              icon: const Icon(Icons.text_fields_rounded))
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Bacaan belum tersedia offline. Periksa koneksi lalu coba lagi.',
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(quranSurahProvider(widget.number)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi')),
        ])),
        data: (surah) => !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                _SurahHeader(surah: surah),
                Expanded(
                    child: _AyahList(
                  surah: surah,
                  fontSize: _fontSize,
                  showLatin: _latin,
                  showTranslation: _translation,
                  bookmarks: _bookmarks,
                  onBookmark: _toggleBookmark,
                )),
              ]),
      ),
      bottomNavigationBar: detail.valueOrNull == null
          ? null
          : _SurahNavigation(
              number: widget.number,
              onOpen: (number) => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                      builder: (_) => QuranDetailScreen(number: number))),
            ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});
  final QuranSurahDetail surah;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Text(surah.nameArabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontSize: 32, height: 1.7, color: Colors.white)),
          Text(surah.nameLatin,
              style: AppTypography.h3.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.xs),
          Text(
              '${surah.meaning} • ${surah.verseCount} ayat • ${surah.revelationPlace}',
              style: AppTypography.caption.copyWith(color: Colors.white70),
              textAlign: TextAlign.center),
        ]),
      );
}

class _AyahList extends StatefulWidget {
  const _AyahList(
      {required this.surah,
      required this.fontSize,
      required this.showLatin,
      required this.showTranslation,
      required this.bookmarks,
      required this.onBookmark});
  final QuranSurahDetail surah;
  final double fontSize;
  final bool showLatin;
  final bool showTranslation;
  final Set<String> bookmarks;
  final ValueChanged<int> onBookmark;
  @override
  State<_AyahList> createState() => _AyahListState();
}

class _AyahListState extends State<_AyahList> {
  final _listKey = GlobalKey();
  final Map<int, GlobalKey> _verseKeys = {};
  int _lastSaved = 0;

  bool _saveVisibleVerse(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        widget.surah.verses.isEmpty) return false;
    final viewport = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return false;
    final top = viewport.localToGlobal(Offset.zero).dy;
    for (var i = 0; i < widget.surah.verses.length; i++) {
      final verseBox =
          _verseKeys[i]?.currentContext?.findRenderObject() as RenderBox?;
      if (verseBox == null) continue;
      final y = verseBox.localToGlobal(Offset.zero).dy;
      if (y + verseBox.size.height >= top && y <= top + viewport.size.height) {
        final number = widget.surah.verses[i].number;
        if (number != _lastSaved) {
          _lastSaved = number;
          saveLastRead(widget.surah.number, number);
        }
        break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _saveVisibleVerse,
        child: ListView.separated(
          key: _listKey,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          itemCount: widget.surah.verses.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final verse = widget.surah.verses[index];
            final key = _verseKeys.putIfAbsent(index, GlobalKey.new);
            return _AyahCard(
              key: key,
              verse: verse,
              fontSize: widget.fontSize,
              showLatin: widget.showLatin,
              showTranslation: widget.showTranslation,
              bookmarked: widget.bookmarks.contains(
                  quranBookmarkKey(widget.surah.number, verse.number)),
              onBookmark: () => widget.onBookmark(verse.number),
            );
          },
        ),
      );
}

class _AyahCard extends StatelessWidget {
  const _AyahCard(
      {super.key,
      required this.verse,
      required this.fontSize,
      required this.showLatin,
      required this.showTranslation,
      required this.bookmarked,
      required this.onBookmark});
  final QuranVerse verse;
  final double fontSize;
  final bool showLatin;
  final bool showTranslation;
  final bool bookmarked;
  final VoidCallback onBookmark;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${verse.number}',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.primary))),
            const Spacer(),
            IconButton(
                tooltip: bookmarked ? 'Hapus penanda ayat' : 'Tandai ayat',
                onPressed: onBookmark,
                icon: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(verse.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: fontSize, height: 2, color: AppColors.textPrimary)),
          if (showLatin && verse.transliteration.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(verse.transliteration,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.primaryDark)),
          ],
          if (showTranslation && verse.translation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(verse.translation,
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ]),
      );
}

class _SurahNavigation extends StatelessWidget {
  const _SurahNavigation({required this.number, required this.onOpen});
  final int number;
  final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: number > 1 ? () => onOpen(number - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Sebelumnya'))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: number < 114 ? () => onOpen(number + 1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Berikutnya'),
                    iconAlignment: IconAlignment.end)),
          ]),
        ),
      );
}
