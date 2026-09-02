import 'package:equatable/equatable.dart';

abstract class HealthRiskEvent extends Equatable {
  const HealthRiskEvent();

  @override
  List<Object?> get props => [];
}

class EvaluateHealthRisk extends HealthRiskEvent {
  const EvaluateHealthRisk();
}

class StreamHealthRiskUpdates extends HealthRiskEvent {
  const StreamHealthRiskUpdates();
}
