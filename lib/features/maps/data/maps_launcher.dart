import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/navigation_destination.dart';

enum MapsLaunchStatus { launched, unavailable }

class MapsLaunchResult {
  const MapsLaunchResult(this.status);

  final MapsLaunchStatus status;

  bool get launched => status == MapsLaunchStatus.launched;
}

abstract interface class ExternalUrlLauncher {
  Future<bool> launch(Uri uri, {required LaunchMode mode});
}

class UrlLauncherAdapter implements ExternalUrlLauncher {
  const UrlLauncherAdapter();

  @override
  Future<bool> launch(Uri uri, {required LaunchMode mode}) =>
      launchUrl(uri, mode: mode);
}

class MapsLauncher {
  MapsLauncher({ExternalUrlLauncher? launcher})
      : _launcher = launcher ?? const UrlLauncherAdapter();

  final ExternalUrlLauncher _launcher;

  Future<MapsLaunchResult> open(NavigationDestination destination) async {
    final appUri = destination.googleNavigationUri;
    if (appUri != null && !kIsWeb) {
      try {
        if (await _launcher.launch(
          appUri,
          mode: LaunchMode.externalApplication,
        )) {
          return const MapsLaunchResult(MapsLaunchStatus.launched);
        }
      } catch (_) {
        // Continue to the browser fallback.
      }
    }

    final browserUri = destination.browserUri;
    if (browserUri == null) {
      return const MapsLaunchResult(MapsLaunchStatus.unavailable);
    }

    try {
      final launched = await _launcher.launch(
        browserUri,
        mode: LaunchMode.externalApplication,
      );
      return MapsLaunchResult(
        launched ? MapsLaunchStatus.launched : MapsLaunchStatus.unavailable,
      );
    } catch (_) {
      return const MapsLaunchResult(MapsLaunchStatus.unavailable);
    }
  }
}
