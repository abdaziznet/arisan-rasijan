import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
