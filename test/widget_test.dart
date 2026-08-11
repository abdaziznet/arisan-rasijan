import 'package:flutter_test/flutter_test.dart';

import 'package:bani_rasijan/app.dart';

void main() {
  testWidgets('menampilkan halaman splash saat aplikasi dimulai', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BaniRasijanApp());

    expect(find.text('BANI RASIJAN'), findsOneWidget);
    expect(find.text('Arisan Keluarga'), findsOneWidget);
  });
}
