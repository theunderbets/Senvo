import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/emergency_models.dart';
import 'emergency_event.dart';
import 'emergency_state.dart';

class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  final EmergencyOrchestrator orchestrator;

  EmergencyBloc({required this.orchestrator}) : super(EmergencyIdle()) {
    on<TriggerEmergency>((event, emit) async {
      final explanation = event.customHeadline ?? 
                          event.riskResult?.headline ?? 
                          'Emergency detected! Please check on the user.';
                          
      emit(EmergencyActive(
        alertType: event.alertType,
        explanation: explanation,
      ));

      final result = await orchestrator.trigger(
        alertType: event.alertType,
        fallEvidence: event.fallEvidence,
        riskResult: event.riskResult,
      );

      emit(EmergencyActive(
        alertType: event.alertType,
        explanation: explanation,
        smsStatus: result.status,
      ));
    });

    on<CancelEmergency>((event, emit) {
      orchestrator.clearActiveIncident();
      emit(EmergencyIdle());
    });
  }
}
