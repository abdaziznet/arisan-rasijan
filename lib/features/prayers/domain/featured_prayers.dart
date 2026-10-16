import 'daily_prayer.dart';

class FeaturedPrayer {
  const FeaturedPrayer({required this.id, required this.contextLabel});
  final int id;
  final String contextLabel;
}

abstract final class FeaturedPrayers {
  static const List<FeaturedPrayer> all = [
    FeaturedPrayer(id: 211, contextLabel: 'Pembuka pertemuan'),
    FeaturedPrayer(id: 68, contextLabel: 'Untuk orang tua'),
    FeaturedPrayer(id: 69, contextLabel: 'Untuk keluarga'),
    FeaturedPrayer(id: 103, contextLabel: 'Memohon kemudahan'),
    FeaturedPrayer(id: 135, contextLabel: 'Sebelum makan'),
    FeaturedPrayer(id: 139, contextLabel: 'Sesudah makan'),
    FeaturedPrayer(id: 140, contextLabel: 'Untuk tuan rumah'),
    FeaturedPrayer(id: 51, contextLabel: 'Saat bepergian'),
    FeaturedPrayer(id: 57, contextLabel: 'Pulang dari perjalanan'),
    FeaturedPrayer(id: 214, contextLabel: 'Penutup pertemuan'),
  ];

  static List<DailyPrayer> select(List<DailyPrayer> prayers) {
    final byId = {for (final prayer in prayers) prayer.id: prayer};
    final selected = <DailyPrayer>[];
    for (final featured in all) {
      final prayer = byId[featured.id];
      if (prayer != null) selected.add(prayer);
    }
    return selected;
  }

  static String contextFor(int id) {
    for (final prayer in all) {
      if (prayer.id == id) return prayer.contextLabel;
    }
    return '';
  }
}
