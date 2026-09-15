class NavigationDestination {
  const NavigationDestination({
    this.latitude,
    this.longitude,
    this.address,
    this.label,
  });

  final double? latitude;
  final double? longitude;
  final String? address;
  final String? label;

  bool get hasValidCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  bool get hasAddress => address?.trim().isNotEmpty == true;

  bool get hasLaunchTarget => hasValidCoordinates || hasAddress;

  Uri? get googleNavigationUri {
    if (!hasValidCoordinates) return null;
    return Uri.parse('google.navigation:q=$latitude,$longitude');
  }

  Uri? get browserUri {
    if (hasValidCoordinates) {
      return Uri.https(
        'www.google.com',
        '/maps/dir/',
        <String, String>{
          'api': '1',
          'destination': '$latitude,$longitude',
          if (label?.trim().isNotEmpty == true) 'travelmode': 'driving',
        },
      );
    }

    if (hasAddress) {
      return Uri.https(
        'www.google.com',
        '/maps/search/',
        <String, String>{
          'api': '1',
          'query': address!.trim(),
        },
      );
    }

    return null;
  }
}
