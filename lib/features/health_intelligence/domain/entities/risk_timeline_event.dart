import '../../../health_risk/domain/entities/risk_result.dart';

class RiskTimelineEvent {
  final DateTime timestamp;
  final double overallScore;
  final Map<String, DomainRiskResult> domainResults;

  const RiskTimelineEvent({
    required this.timestamp,
    required this.overallScore,
    required this.domainResults,
  });
}
