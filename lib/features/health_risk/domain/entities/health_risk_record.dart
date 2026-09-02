import 'risk_result.dart';

class HealthRiskRecord {
  final String id;
  final OverallRiskResult riskResult;
  final String? userId;
  final DateTime createdAt;

  HealthRiskRecord({
    required this.id,
    required this.riskResult,
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
