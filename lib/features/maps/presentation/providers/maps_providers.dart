import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/maps_launcher.dart';

final mapsLauncherProvider = Provider<MapsLauncher>(
  (ref) => MapsLauncher(),
);
