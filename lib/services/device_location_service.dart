import 'package:geolocator/geolocator.dart';

import '../core/constants/app_strings.dart';
import '../core/network/api_exception.dart';

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

abstract class DeviceLocationService {
  Future<DeviceLocation> currentPosition();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService();

  @override
  Future<DeviceLocation> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ApiException(AppStrings.locationServicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const ApiException(AppStrings.locationPermissionRequired);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ApiException(AppStrings.locationPermissionDeniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(AppStrings.locationUnavailable);
    }
  }
}
