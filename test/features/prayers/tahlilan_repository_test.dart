import 'package:bani_rasijan/features/prayers/data/tahlilan_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads ordered tahlilan readings from the supplied asset', () async {
    final readings = await AssetTahlilanRepository().loadAll();

    expect(readings, hasLength(44));
    expect(readings.first.title, 'Pengantar Al-Fatihah');
    expect(readings.first.arabic, isNotEmpty);
    expect(readings.first.latin, startsWith('Ila hadhratin'));
    expect(readings.first.translation, contains('Al-Fatihah'));
    expect(readings[1].prefix?.arabic, isNotEmpty);
    expect(readings[1].prefix?.latin, startsWith('A\'udzu'));
    expect(readings[25].title, 'Tahlil');
    expect(readings[25].repeat, 160);
    expect(readings.last.title, 'Doa Kemurahan dan Keridhaan Allah');
  });
}
