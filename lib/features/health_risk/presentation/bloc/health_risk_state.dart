import 'package:equatable/equatable.dart';
import '../../domain/entities/risk_result.dart';

abstract class HealthRiskState extends Equatable {
  const HealthRiskState();

  @override
  List<Object?> get props => [];
}

class HealthRiskInitial extends HealthRiskState {
  const HealthRiskInitial();
}

class HealthRiskLoading extends HealthRiskState {
  const HealthRiskLoading();
}

class HealthRiskLoaded extends HealthRiskState {
  final OverallRiskResult riskResult;

  const HealthRiskLoaded(this.riskResult);

  @override
  List<Object?> get props => [riskResult];
}

class HealthRiskError extends HealthRiskState {
  final String message;

  const HealthRiskError(this.message);

  @override
  List<Object?> get props => [message];
}
