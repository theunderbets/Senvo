enum EnvironmentalDataSource { live, cached }

class EnvironmentalContext {
  const EnvironmentalContext({
    this.ambientTemperatureCelsius,
    this.humidityPercent,
    this.aqi,
    this.pm25,
    this.pm10,
    required this.observedAt,
    required this.cachedAt,
    required this.source,
  });
  
  final double? ambientTemperatureCelsius;
  final double? humidityPercent;
  final double? aqi;
  final double? pm25;
  final double? pm10;
  final DateTime observedAt;
  final DateTime cachedAt;
  final EnvironmentalDataSource source;
}
