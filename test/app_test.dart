import 'package:bani_rasijan/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on the branded splash screen', (tester) async {
    await tester.pumpWidget(const BaniRasijanApp());
    expect(find.text('BANI RASIJAN'), findsOneWidget);
    expect(find.text('Arisan Keluarga'), findsOneWidget);
  });
}
