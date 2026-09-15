import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bani_rasijan/features/maps/data/maps_launcher.dart';
import 'package:bani_rasijan/features/maps/domain/navigation_destination.dart';

class FakeExternalUrlLauncher implements ExternalUrlLauncher {
  FakeExternalUrlLauncher(this.responses);

  final List<bool> responses;
  final List<Uri> launchedUris = [];

  @override
  Future<bool> launch(Uri uri, {required LaunchMode mode}) async {
    launchedUris.add(uri);
    return responses.removeAt(0);
  }
}

void main() {
  test('opens Google navigation first when coordinates are available',
      () async {
    final fakeLauncher = FakeExternalUrlLauncher([true]);
    final result = await MapsLauncher(launcher: fakeLauncher).open(
      const NavigationDestination(latitude: -6.9, longitude: 107.6),
    );

    expect(result.launched, isTrue);
    expect(fakeLauncher.launchedUris, hasLength(1));
    expect(fakeLauncher.launchedUris.single.scheme, 'google.navigation');
  });

  test('falls back to browser when Maps app cannot be opened', () async {
    final fakeLauncher = FakeExternalUrlLauncher([false, true]);
    final result = await MapsLauncher(launcher: fakeLauncher).open(
      const NavigationDestination(latitude: -6.9, longitude: 107.6),
    );

    expect(result.launched, isTrue);
    expect(fakeLauncher.launchedUris, hasLength(2));
    expect(fakeLauncher.launchedUris.last.host, 'www.google.com');
  });

  test('returns unavailable when no destination exists', () async {
    final fakeLauncher = FakeExternalUrlLauncher([]);
    final result = await MapsLauncher(launcher: fakeLauncher).open(
      const NavigationDestination(),
    );

    expect(result.launched, isFalse);
    expect(fakeLauncher.launchedUris, isEmpty);
  });
}
