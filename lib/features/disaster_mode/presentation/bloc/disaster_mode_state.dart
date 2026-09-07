import 'package:equatable/equatable.dart';
import '../../domain/disaster_models.dart';

abstract class DisasterModeStateBase extends Equatable {
  const DisasterModeStateBase();
  
  @override
  List<Object?> get props => [];
}

class DisasterModeInitial extends DisasterModeStateBase {}

class DisasterModeChecking extends DisasterModeStateBase {}

class DisasterModeStatus extends DisasterModeStateBase {
  final DisasterModeState state;
  final EmergencyReadinessResult readiness;

  const DisasterModeStatus({
    required this.state,
    required this.readiness,
  });

  @override
  List<Object?> get props => [state, readiness];
}
