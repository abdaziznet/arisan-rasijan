import 'package:flutter_test/flutter_test.dart';

import 'package:bani_rasijan/features/maps/domain/navigation_destination.dart';

void main() {
  group('NavigationDestination', () {
    test('accepts valid coordinates at their boundaries', () {
      const destination = NavigationDestination(
        latitude: -90,
        longitude: 180,
        label: 'Rumah Host',
      );

      expect(destination.hasValidCoordinates, isTrue);
      expect(destination.googleNavigationUri.toString(),
          'google.navigation:q=-90.0,180.0');
    });

    test('rejects invalid or incomplete coordinates', () {
      expect(
        const NavigationDestination(latitude: 91, longitude: 0)
            .hasValidCoordinates,
        isFalse,
      );
      expect(
        const NavigationDestination(latitude: 0, longitude: -181)
            .hasValidCoordinates,
        isFalse,
      );
      expect(
        const NavigationDestination(latitude: 0).hasValidCoordinates,
        isFalse,
      );
    });

    test('uses an encoded address when coordinates are unavailable', () {
      const destination = NavigationDestination(address: 'Jl. Mawar No. 1 & 2');

      expect(destination.hasAddress, isTrue);
      expect(
        destination.browserUri?.queryParameters['query'],
        'Jl. Mawar No. 1 & 2',
      );
      expect(destination.googleNavigationUri, isNull);
    });

    test('has no launch target when address and coordinates are absent', () {
      const destination = NavigationDestination();

      expect(destination.hasLaunchTarget, isFalse);
      expect(destination.browserUri, isNull);
    });
  });
}
