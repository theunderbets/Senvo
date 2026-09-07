import 'package:geolocator/geolocator.dart';
import '../../domain/emergency_models.dart';

class RealLocationService implements LocationService {
  @override
  Future<CachedLocation?> getCachedLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return CachedLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          capturedAt: position.timestamp,
          accuracy: position.accuracy,
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<CachedLocation?> getFreshLocation({required Duration timeout}) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        timeLimit: timeout,
      );
      
      return CachedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: position.timestamp,
        accuracy: position.accuracy,
      );
    } catch (_) {
      return null;
    }
  }
}
