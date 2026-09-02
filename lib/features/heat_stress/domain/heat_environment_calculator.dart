import 'dart:math' as math;
import 'heat_stress_models.dart';

abstract interface class HeatEnvironmentCalculator {
  HeatEnvironmentAssessment calculate(EnvironmentalMetrics metrics);

  double calculateAqiModifier(double? aqi);
}

class HeatEnvironmentCalculatorImpl implements HeatEnvironmentCalculator {
  const HeatEnvironmentCalculatorImpl();

  @override
  HeatEnvironmentAssessment calculate(EnvironmentalMetrics metrics) {
    final temperatureScore = _clamp01((metrics.temperatureCelsius - 24) / 20);
    final humidityScore = _clamp01((metrics.relativeHumidityPercent - 40) / 60);
    final interaction = temperatureScore * humidityScore;
    final combined = _clamp01(
      temperatureScore * .45 + humidityScore * .2 + interaction * .35,
    );
    final heatIndex = _heatIndexCelsius(
      metrics.temperatureCelsius,
      metrics.relativeHumidityPercent,
    );
    final aqiModifier = calculateAqiModifier(metrics.aqi);
    return HeatEnvironmentAssessment(
      heatIndexCelsius: heatIndex,
      stress: EnvironmentalStress(
        temperatureScore: temperatureScore,
        humidityScore: humidityScore,
        combinedHeatScore: combined,
        aqiModifier: aqiModifier,
        description: combined >= .7
            ? 'Temperature and humidity indicate severe environmental heat stress.'
            : combined >= .3
            ? 'Temperature and humidity indicate elevated environmental heat stress.'
            : 'Environmental heat stress is currently low.',
      ),
    );
  }

  @override
  double calculateAqiModifier(double? aqi) {
    if (aqi == null || !aqi.isFinite || aqi <= 50) return 0;
    return _clamp01((aqi - 50) / 200);
  }

  double _heatIndexCelsius(double temperature, double humidity) {
    final fahrenheit = temperature * 9 / 5 + 32;
    if (fahrenheit < 80) return temperature;
    final h = humidity;
    final index =
        -42.379 +
        2.04901523 * fahrenheit +
        10.14333127 * h -
        .22475541 * fahrenheit * h -
        .00683783 * fahrenheit * fahrenheit +
        .05481717 * h * h +
        .00122874 * fahrenheit * fahrenheit * h +
        .00085282 * fahrenheit * h * h -
        .00000199 * fahrenheit * fahrenheit * h * h;
    return (index - 32) * 5 / 9;
  }

  double _clamp01(double value) => math.max(0, math.min(1, value));
}
