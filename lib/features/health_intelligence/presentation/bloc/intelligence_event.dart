import 'package:equatable/equatable.dart';

abstract class IntelligenceEvent extends Equatable {
  const IntelligenceEvent();

  @override
  List<Object?> get props => [];
}

class GenerateInsights extends IntelligenceEvent {
  const GenerateInsights();
}
