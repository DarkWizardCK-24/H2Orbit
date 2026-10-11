import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

typedef Coordinates = ({double latitude, double longitude});

/// Coarse device location, used only to look up the local weather.
class LocationService {
  LocationService._();

  /// Returns `null` when location is off, denied, or can't be determined.
  static Future<Coordinates?> currentCoordinates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Weather only needs the city, so low accuracy is plenty (and faster).
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      debugPrint('Could not get location: $e');
      return null;
    }
  }
}
