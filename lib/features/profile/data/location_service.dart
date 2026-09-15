import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  granted,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  failed,
}

class LocationResult {
  const LocationResult({required this.status, this.position, this.message});

  final LocationStatus status;
  final Position? position;
  final String? message;

  bool get isGranted => status == LocationStatus.granted && position != null;
}

abstract interface class LocationService {
  Future<LocationResult> getCurrentLocation();
  Future<bool> openAppSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(status: LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(status: LocationStatus.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationStatus.permissionPermanentlyDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        status: LocationStatus.granted,
        position: position,
      );
    } catch (error) {
      return LocationResult(
        status: LocationStatus.failed,
        message: error.toString(),
      );
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
