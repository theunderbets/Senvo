import 'package:equatable/equatable.dart';
import '../../domain/entities/health_insight.dart';
import '../../domain/entities/risk_timeline_event.dart';

abstract class IntelligenceState extends Equatable {
  const IntelligenceState();

  @override
  List<Object?> get props => [];
}

class IntelligenceInitial extends IntelligenceState {
  const IntelligenceInitial();
}

class IntelligenceLoading extends IntelligenceState {
  const IntelligenceLoading();
}

class IntelligenceLoaded extends IntelligenceState {
  final List<HealthInsight> insights;
  final List<RiskTimelineEvent> timelineEvents;
  
  const IntelligenceLoaded(this.insights, this.timelineEvents);

  @override
  List<Object?> get props => [insights, timelineEvents];
}

class IntelligenceError extends IntelligenceState {
  final String message;

  const IntelligenceError(this.message);

  @override
  List<Object?> get props => [message];
}
