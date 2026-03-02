import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../services/risk_engine.dart';
import '../utils/constants.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    String model = 'Unknown Device';
    String deviceId = 'unknown';
    bool isNewDevice = false;

    try {
      // Try Android first
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
        deviceId = androidInfo.id;
      } catch (_) {}

      // Try iOS
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        model = iosInfo.utsname.machine;
        deviceId = iosInfo.identifierForVendor ?? 'ios-unknown';
      } catch (_) {}

      // Simulate: 30% chance this is flagged as a new device
      isNewDevice = Random().nextDouble() < 0.3;
    } catch (e) {
      model = 'Pixel 8 Pro (simulated)';
      deviceId = 'sim-device-001';
    }

    final double deviceRisk = isNewDevice ? 65.0 : 10.0;

    return {
      'model': model,
      'deviceId': deviceId,
      'isNewDevice': isNewDevice,
      'deviceRisk': deviceRisk,
    };
  }

  static Future<Map<String, dynamic>> getLocationInfo() async {
    double latitude = AppConstants.prevLat; // fallback
    double longitude = AppConstants.prevLng;
    double locationRisk = 5.0;
    double distanceKm = 0;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          latitude = position.latitude;
          longitude = position.longitude;
        }
      }
    } catch (_) {
      // Simulate a location in India
      latitude = 28.6139 + (Random().nextDouble() - 0.5) * 2;
      longitude = 77.2090 + (Random().nextDouble() - 0.5) * 2;
    }

    distanceKm = RiskEngine.haversineDistance(
      latitude, longitude,
      AppConstants.prevLat, AppConstants.prevLng,
    );

    locationRisk = RiskEngine.calculateLocationRisk(distanceKm);

    return {
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'locationRisk': locationRisk,
    };
  }
}
