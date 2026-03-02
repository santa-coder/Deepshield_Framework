import 'package:geolocator/geolocator.dart';
import 'permission_service.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final bool success;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.success,
  });
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    final hasPermission = await PermissionService.requestLocation();
    if (!hasPermission) {
      return const LocationResult(
        latitude: 40.7128,
        longitude: -74.0060,
        displayName: 'New York, US (demo)',
        success: true,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          latitude: 40.7128,
          longitude: -74.0060,
          displayName: 'New York, US (demo)',
          success: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 10),
  ),
);

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        displayName:
            '${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°',
        success: true,
      );
    } catch (_) {
      // Return NYC demo location for emulator/simulator
      return const LocationResult(
        latitude: 40.7128,
        longitude: -74.0060,
        displayName: 'New York, US (demo)',
        success: true,
      );
    }
  }
}
