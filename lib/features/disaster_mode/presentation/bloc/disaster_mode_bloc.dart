import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/disaster_service.dart';
import 'disaster_mode_event.dart';
import 'disaster_mode_state.dart';

class DisasterModeBloc extends Bloc<DisasterModeEvent, DisasterModeStateBase> {
  final DisasterModeService disasterService;

  DisasterModeBloc({required this.disasterService}) : super(DisasterModeInitial()) {
    on<CheckDisasterReadiness>((event, emit) async {
      emit(DisasterModeChecking());
      final readiness = await disasterService.checkReadiness();
      // Assume initial state is safe for now, this could be driven by an external network stream
      final state = await disasterService.evaluateDisasterState(readiness.hasNetwork, 0);
      emit(DisasterModeStatus(state: state, readiness: readiness));
    });

    on<UpdateDisasterState>((event, emit) async {
      if (state is DisasterModeStatus) {
        final currentReadiness = (state as DisasterModeStatus).readiness;
        final newState = await disasterService.evaluateDisasterState(event.hasNetwork, event.currentRiskScore);
        emit(DisasterModeStatus(state: newState, readiness: currentReadiness));
      }
    });
  }
}
