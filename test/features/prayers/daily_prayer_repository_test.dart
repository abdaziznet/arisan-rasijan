import 'package:bani_rasijan/features/prayers/data/daily_prayer_repository.dart';
import 'package:bani_rasijan/features/prayers/domain/featured_prayers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all uploaded doa records and resolves curated selection',
      () async {
    final prayers = await AssetDailyPrayerRepository().loadAll();

    expect(prayers, hasLength(227));
    expect(FeaturedPrayers.select(prayers), hasLength(10));
    expect(
      FeaturedPrayers.select(prayers).map((prayer) => prayer.id),
      containsAll([211, 68, 69, 103, 135, 139, 140, 51, 57, 214]),
    );
  });
}
