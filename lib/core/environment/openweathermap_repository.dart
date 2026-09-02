import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'environment_models.dart';
import 'environment_repository.dart';

class OpenWeatherMapRepository implements EnvironmentRepository {
  final String apiKey;
  final http.Client _client;

  // Fallback coordinates (New Delhi) used when GPS is unavailable
  static const double _fallbackLat = 28.6139;
  static const double _fallbackLon = 77.2090;

  OpenWeatherMapRepository({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  /// Attempts to get GPS coordinates via geolocator.
  /// Returns fallback coordinates if permission denied or location unavailable.
  Future<({double lat, double lon})> _getLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (lat: _fallbackLat, lon: _fallbackLon);
      }

      // Check and request permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (lat: _fallbackLat, lon: _fallbackLon);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return (lat: _fallbackLat, lon: _fallbackLon);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return (lat: position.latitude, lon: position.longitude);
    } catch (_) {
      return (lat: _fallbackLat, lon: _fallbackLon);
    }
  }

  @override
  Stream<EnvironmentalContext> watchEnvironment() async* {
    yield await getCurrentEnvironment();
    yield* Stream.periodic(const Duration(minutes: 15), (_) => null)
        .asyncMap((_) => getCurrentEnvironment());
  }

  @override
  Future<EnvironmentalContext> getCurrentEnvironment() async {
    try {
      final loc = await _getLocation();

      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${loc.lat}&lon=${loc.lon}&appid=$apiKey&units=metric'
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        double aqi = 50.0;

        try {
          final aqiUrl = Uri.parse(
            'https://api.openweathermap.org/data/2.5/air_pollution?lat=${loc.lat}&lon=${loc.lon}&appid=$apiKey'
          );
          final aqiResponse = await _client.get(aqiUrl).timeout(const Duration(seconds: 5));
          if (aqiResponse.statusCode == 200) {
            final aqiData = json.decode(aqiResponse.body);
            final int rawAqi = aqiData['list'][0]['main']['aqi'] ?? 1;
            aqi = rawAqi * 20.0;
          }
        } catch (_) {}

        return EnvironmentalContext(
          ambientTemperatureCelsius: (data['main']['temp'] as num).toDouble(),
          humidityPercent: (data['main']['humidity'] as num).toDouble(),
          aqi: aqi,
          pm25: null,
          pm10: null,
          observedAt: DateTime.now(),
          cachedAt: DateTime.now(),
          source: EnvironmentalDataSource.live,
        );
      }
    } catch (e) {
      // Fallback to defaults on any error
    }

    return EnvironmentalContext(
      ambientTemperatureCelsius: 22.0,
      humidityPercent: 45.0,
      aqi: 40.0,
      pm25: 12.0,
      pm10: 20.0,
      observedAt: DateTime.now(),
      cachedAt: DateTime.now(),
      source: EnvironmentalDataSource.cached,
    );
  }

  Stream<EnvironmentalContext> watchCurrentEnvironment() async* {
    yield await getCurrentEnvironment();
    yield* Stream.periodic(const Duration(minutes: 15), (_) => null)
        .asyncMap((_) => getCurrentEnvironment());
  }
}
