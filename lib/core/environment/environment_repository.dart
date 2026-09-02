import 'dart:async';
import 'environment_models.dart';

abstract class EnvironmentRepository {
  Future<EnvironmentalContext> getCurrentEnvironment();
  Stream<EnvironmentalContext> watchEnvironment();
}

class MockEnvironmentRepository implements EnvironmentRepository {
  final _controller = StreamController<EnvironmentalContext>.broadcast();

  MockEnvironmentRepository() {
    _startMockStream();
  }

  void _startMockStream() {
    Timer.periodic(const Duration(seconds: 10), (_) async {
      _controller.add(await getCurrentEnvironment());
    });
  }

  @override
  Future<EnvironmentalContext> getCurrentEnvironment() async {
    final now = DateTime.now();
    // Simulate some variance
    final tempOffset = (now.second % 10 - 5) / 10.0; 
    return EnvironmentalContext(
      ambientTemperatureCelsius: 32.0 + tempOffset,
      humidityPercent: 65.0,
      aqi: 110.0,
      observedAt: now,
      cachedAt: now,
      source: EnvironmentalDataSource.live,
    );
  }

  @override
  Stream<EnvironmentalContext> watchEnvironment() {
    return _controller.stream;
  }
}
