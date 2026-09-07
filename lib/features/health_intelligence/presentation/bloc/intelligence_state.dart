import 'package:equatable/equatable.dart';
import '../../domain/entities/health_insight.dart';

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
  
  const IntelligenceLoaded(this.insights);

  @override
  List<Object?> get props => [insights];
}

class IntelligenceError extends IntelligenceState {
  final String message;

  const IntelligenceError(this.message);

  @override
  List<Object?> get props => [message];
}
