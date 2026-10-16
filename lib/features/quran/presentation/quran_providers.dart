import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quran_repository.dart';
import '../domain/quran_models.dart';

final quranRepositoryProvider =
    Provider<QuranRepository>((ref) => QuranRepositoryImpl());

final quranSurahsProvider = FutureProvider<List<QuranSurah>>(
    (ref) => ref.watch(quranRepositoryProvider).getSurahs());

final quranSurahProvider = FutureProvider.family<QuranSurahDetail, int>(
    (ref, number) => ref.watch(quranRepositoryProvider).getSurah(number));
