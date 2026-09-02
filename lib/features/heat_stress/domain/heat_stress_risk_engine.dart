import 'dart:math' as math;
import 'heat_environment_calculator.dart';
import 'heat_stress_models.dart';
import 'heat_stress_repositories.dart';

class HeatStressRiskConfig {
  const HeatStressRiskConfig({
    this.watchThreshold = .30,
    this.alertThreshold = .55,
    this.emergencyThreshold = .80,
    this.environmentalWeight = .35,
    this.heartRateWeight = .30,
    this.spo2Weight = .15,
    this.bloodPressureWeight = .15,
    this.aqiWeight = .05,
    this.minimumBaselineSamples = 3,
    this.baselineWindow = const Duration(days: 7),
    this.minimumSignalQuality = .5,
    this.environmentCacheMaxAge = const Duration(hours: 2),
    this.staleEnvironmentMaxAge = const Duration(hours: 6),
  }) : assert(watchThreshold >= 0 && watchThreshold <= 1),
       assert(alertThreshold > watchThreshold && alertThreshold <= 1),
       assert(emergencyThreshold > alertThreshold && emergencyThreshold <= 1),
       assert(minimumBaselineSamples > 0);

  final double watchThreshold;
  final double alertThreshold;
  final double emergencyThreshold;
  final double environmentalWeight;
  final double heartRateWeight;
  final double spo2Weight;
  final double bloodPressureWeight;
  final double aqiWeight;
  final int minimumBaselineSamples;
  final Duration baselineWindow;
  final double minimumSignalQuality;
  final Duration environmentCacheMaxAge;
  final Duration staleEnvironmentMaxAge;
}

class HeatStressRiskEngine {
  HeatStressRiskEngine({
    required this.baselineRepository,
    required this.environmentalRepository,
    this.config = const HeatStressRiskConfig(),
    this.environmentCalculator = const HeatEnvironmentCalculatorImpl(),
  });

  final PersonalBaselineRepository baselineRepository;
  final EnvironmentalCacheRepository environmentalRepository;
  final HeatStressRiskConfig config;
  final HeatEnvironmentCalculator environmentCalculator;

  Future<HeatStressRiskResult> evaluate({
    required CurrentVitals vitals,
    DateTime? timestamp,
  }) async {
    _validateVitals(vitals);
    final evaluatedAt = timestamp ?? vitals.timestamp;
    final baseline = await baselineRepository.getRollingBaseline(
      now: evaluatedAt,
      window: config.baselineWindow,
    );
    final cached = await environmentalRepository.getLatest();
    final environment = _usableEnvironment(cached, evaluatedAt);
    final environmentAge = cached == null
        ? null
        : evaluatedAt.difference(cached.cachedAt);
    final baselineAge = baseline == null
        ? null
        : evaluatedAt.difference(baseline.calculatedAt);
    final baselineAvailable =
        baseline != null &&
        baseline.sampleCount >= config.minimumBaselineSamples &&
        baseline.status == BaselineStatus.available;
    final qualityAcceptable =
        vitals.signalQuality >= config.minimumSignalQuality;
    final factors = <RiskFactor>[];
    var weightedScore = 0.0;
    var availableWeight = 0.0;

    if (environment != null) {
      final assessment = environmentCalculator.calculate(environment);
      final environmentalScore = assessment.stress.combinedHeatScore;
      weightedScore += environmentalScore * config.environmentalWeight;
      availableWeight += config.environmentalWeight;
      if (environmentalScore > 0) {
        factors.add(
          RiskFactor(
            id: 'heat_environment',
            title: 'Ambient Heat',
            description: assessment.stress.description,
            contribution: environmentalScore * config.environmentalWeight,
            severity: _severity(environmentalScore),
          ),
        );
      }
      if (assessment.stress.aqiModifier > 0) {
        weightedScore += assessment.stress.aqiModifier * config.aqiWeight;
        availableWeight += config.aqiWeight;
        factors.add(
          RiskFactor(
            id: 'aqi',
            title: 'Air Quality Burden',
            description: 'AQI is contributing additional environmental strain.',
            contribution: assessment.stress.aqiModifier * config.aqiWeight,
            severity: _severity(assessment.stress.aqiModifier),
          ),
        );
      }
    } else {
      factors.add(
        const RiskFactor(
          id: 'environment_unavailable',
          title: 'Environment Unavailable',
          description:
              'Environmental conditions are unavailable, so this result uses physiological data only.',
          contribution: 0,
          severity: RiskFactorSeverity.info,
        ),
      );
    }

    final deviations = <String, double>{};
    void addVital(
      String id,
      String title,
      double? current,
      double? normal,
      double weight,
      double sensitivity,
      String Function(double) message,
    ) {
      if (current == null || normal == null || normal == 0) return;
      final deviation = (current - normal) / normal;
      deviations[id] = deviation;
      final score = _clamp01(deviation.abs() / sensitivity);
      weightedScore += score * weight;
      availableWeight += weight;
      if (score > .05) {
        factors.add(
          RiskFactor(
            id: id,
            title: title,
            description: message(deviation * 100),
            contribution: score * weight,
            severity: _severity(score),
          ),
        );
      }
    }

    addVital(
      'heart_rate',
      'Heart Rate',
      vitals.heartRateBpm,
      baselineAvailable ? baseline.averageHeartRateBpm : null,
      config.heartRateWeight,
      .30,
      (change) => change >= 0
          ? 'Heart rate is ${change.abs().toStringAsFixed(1)}% above the recent baseline.'
          : 'Heart rate is ${change.abs().toStringAsFixed(1)}% below the recent baseline.',
    );
    addVital(
      'spo2',
      'Oxygen Saturation',
      vitals.spo2Percent,
      baselineAvailable ? baseline.averageSpo2Percent : null,
      config.spo2Weight,
      .08,
      (change) =>
          'SpO2 is ${change.abs().toStringAsFixed(1)}% ${change < 0 ? 'below' : 'above'} the recent baseline.',
    );
    addVital(
      'systolic_bp',
      'Blood Pressure',
      vitals.systolicBp,
      baselineAvailable ? baseline.averageSystolicBp : null,
      config.bloodPressureWeight / 2,
      .25,
      (change) =>
          'Systolic blood pressure changed ${change.abs().toStringAsFixed(1)}% from the recent baseline.',
    );
    addVital(
      'diastolic_bp',
      'Blood Pressure',
      vitals.diastolicBp,
      baselineAvailable ? baseline.averageDiastolicBp : null,
      config.bloodPressureWeight / 2,
      .25,
      (change) =>
          'Diastolic blood pressure changed ${change.abs().toStringAsFixed(1)}% from the recent baseline.',
    );

    if (!baselineAvailable) {
      factors.add(
        const RiskFactor(
          id: 'baseline_unavailable',
          title: 'Limited Personal Baseline',
          description:
              'There are not enough suitable recent measurements for personalized comparison.',
          contribution: 0,
          severity: RiskFactorSeverity.info,
        ),
      );
    }

    final score = availableWeight == 0
        ? 0.0
        : _clamp01(weightedScore / availableWeight);
    final heatScore = environment == null
        ? 0
        : environmentCalculator.calculate(environment).stress.combinedHeatScore;
    final hrDeviation = deviations['heart_rate'] ?? 0;
    final emergency = heatScore >= .8 && hrDeviation >= .25;
    final level = emergency ? HeatStressRiskLevel.emergency : _classify(score);
    final confidence = _confidence(
      vitals,
      baselineAvailable,
      environmentAge,
      environment != null,
      availableWeight,
    );
    if (factors.isEmpty) {
      factors.add(
        const RiskFactor(
          id: 'stable_inputs',
          title: 'Stable Measurements',
          description:
              'Current vitals and available environmental conditions are close to expected values.',
          contribution: 0,
          severity: RiskFactorSeverity.info,
        ),
      );
    }
    factors.sort((a, b) => b.contribution.compareTo(a.contribution));
    final selectedFactors = factors.take(3).toList(growable: false);
    return HeatStressRiskResult(
      level: level,
      riskScore: score,
      confidence: confidence,
      evaluatedAt: evaluatedAt,
      vitals: vitals,
      baseline: baseline,
      environment: environment,
      factors: selectedFactors,
      headline: _headline(level),
      recommendation: _recommendation(level),
      baselineAvailable: baselineAvailable,
      environmentalDataAvailable: environment != null,
      measurementQualityAcceptable: qualityAcceptable,
      environmentalDataAge: environmentAge,
      baselineAge: baselineAge,
    );
  }

  HeatStressRiskLevel _classify(double score) {
    if (score >= config.emergencyThreshold) {
      return HeatStressRiskLevel.emergency;
    }
    if (score >= config.alertThreshold) return HeatStressRiskLevel.alert;
    if (score >= config.watchThreshold) return HeatStressRiskLevel.watch;
    return HeatStressRiskLevel.normal;
  }

  EnvironmentalMetrics? _usableEnvironment(
    CachedEnvironmentalMetrics? cached,
    DateTime now,
  ) {
    if (cached == null) return null;
    final age = now.difference(cached.cachedAt);
    if (age.isNegative || age > config.staleEnvironmentMaxAge) return null;
    return cached.toMetrics();
  }

  double _confidence(
    CurrentVitals vitals,
    bool baselineAvailable,
    Duration? age,
    bool environmentAvailable,
    double availableWeight,
  ) {
    var result = _clamp01(vitals.signalQuality);
    if (!baselineAvailable) result *= .65;
    if (!environmentAvailable) result *= .8;
    if (age != null && age > config.environmentCacheMaxAge) result *= .8;
    if (availableWeight == 0) result *= .5;
    return result;
  }

  void _validateVitals(CurrentVitals vitals) {
    if (!_valid(vitals.signalQuality) ||
        vitals.signalQuality < 0 ||
        vitals.signalQuality > 1) {
      throw ArgumentError.value(vitals.signalQuality, 'signalQuality');
    }
    _validateRange(vitals.heartRateBpm, 'heartRateBpm', 30, 260);
    _validateRange(vitals.spo2Percent, 'spo2Percent', 50, 100);
    _validateRange(vitals.systolicBp, 'systolicBp', 40, 300);
    _validateRange(vitals.diastolicBp, 'diastolicBp', 20, 200);
  }

  void _validateRange(double? value, String name, double min, double max) {
    if (value != null && (!_valid(value) || value < min || value > max)) {
      throw ArgumentError.value(value, name);
    }
  }

  bool _valid(double? value) => value != null && value.isFinite;
  double _clamp01(double value) => math.max(0, math.min(1, value));
  RiskFactorSeverity _severity(double value) => value >= .8
      ? RiskFactorSeverity.severe
      : value >= .55
      ? RiskFactorSeverity.high
      : value >= .3
      ? RiskFactorSeverity.moderate
      : RiskFactorSeverity.info;

  String _headline(HeatStressRiskLevel level) => switch (level) {
    HeatStressRiskLevel.normal => 'Heat-stress risk is low.',
    HeatStressRiskLevel.watch =>
      'Environmental heat or physiological changes are increasing your risk.',
    HeatStressRiskLevel.alert =>
      'Heat-stress indicators are significantly elevated.',
    HeatStressRiskLevel.emergency =>
      'Severe heat and physiological risk indicators require immediate attention.',
  };

  String _recommendation(HeatStressRiskLevel level) => switch (level) {
    HeatStressRiskLevel.normal => 'Continue normal activity and stay hydrated.',
    HeatStressRiskLevel.watch =>
      'Reduce prolonged heat exposure, hydrate, and monitor your symptoms.',
    HeatStressRiskLevel.alert =>
      'Move to a cooler environment, rest, hydrate, and repeat the measurement.',
    HeatStressRiskLevel.emergency =>
      'Stop strenuous activity and seek immediate medical assistance if you feel unwell or have severe symptoms.',
  };
}
