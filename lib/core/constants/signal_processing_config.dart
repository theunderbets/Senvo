class SignalProcessingConfig {
  const SignalProcessingConfig({
    this.lowCutoffHz = 0.7,
    this.highCutoffHz = 4.0,
    this.targetSamplingRate = 30.0,
    this.filterOrder = 2,
    this.minimumSqi = 0.50,
  });
  final double lowCutoffHz;
  final double highCutoffHz;
  final double targetSamplingRate;
  final int filterOrder;
  final double minimumSqi;
}
