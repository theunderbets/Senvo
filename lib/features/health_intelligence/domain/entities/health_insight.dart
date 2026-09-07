enum InsightType {
  positiveTrend,
  anomaly,
  caution,
  educational,
}

enum InsightUrgency {
  low,
  medium,
  high,
}

class HealthInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final InsightUrgency urgency;
  final String? relatedDomain; // e.g., 'Cardiovascular'
  final DateTime generatedAt;

  const HealthInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.urgency,
    this.relatedDomain,
    required this.generatedAt,
  });
}
