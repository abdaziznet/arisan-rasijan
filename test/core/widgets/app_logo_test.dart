import 'package:bani_rasijan/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogo Widget', () {
    testWidgets('renders image with correct asset path and semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(size: AppLogoSize.hero),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel('Logo BANI RASIJAN'), findsOneWidget);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, equals('assets/image/Rasijan.png'));
      expect(image.fit, equals(BoxFit.contain));
      expect(image.width, equals(112));
      expect(image.height, equals(112));
    });

    testWidgets('supports custom size override', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(customSize: 80),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, equals(80));
      expect(image.height, equals(80));
    });

    testWidgets('renders container wrapper when withContainer is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(
              size: AppLogoSize.medium,
              withContainer: true,
              elevation: 2,
            ),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
