class RiskConfig {
  const RiskConfig({
    this.environmentalWeight = 0.33,
    this.physiologicalWeight = 0.34,
    this.activityWeight = 0.33,
  });

  final double environmentalWeight;
  final double physiologicalWeight;
  final double activityWeight;
}

class SystemRiskConfiguration {
  const SystemRiskConfiguration({
    this.domainConfig = const RiskConfig(),
    this.expectedSleep = const Duration(hours: 8),
    this.baselineWindow = const Duration(days: 7),
    this.minimumSignalQuality = 0.5,
    this.environmentMaxAge = const Duration(hours: 6),
    this.riskModelVersion = 'senvo-risk-v1',
  });

  final RiskConfig domainConfig;
  final Duration expectedSleep;
  final Duration baselineWindow;
  final double minimumSignalQuality;
  final Duration environmentMaxAge;
  final String riskModelVersion;
}

