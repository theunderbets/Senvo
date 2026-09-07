import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/activity/activity_repository.dart';
import '../../../../core/environment/environment_repository.dart';
import '../../../../core/sleep/sleep_repository.dart';
import '../../../health_risk/domain/repositories/health_risk_repository.dart';

import '../../../vitals_history/domain/repositories/vitals_repository.dart';
import '../../domain/engines/intelligence_engine.dart';
import 'intelligence_event.dart';
import 'intelligence_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/risk_timeline_event.dart';
import '../../../../core/health/health_models.dart';

class IntelligenceBloc extends Bloc<IntelligenceEvent, IntelligenceState> {
  final HealthIntelligenceEngine _engine;
  final HealthRiskRepository _riskRepository;
  final VitalsRepository _vitalsRepository;
  final ActivityRepository _activityRepository;
  final SleepRepository _sleepRepository;
  final EnvironmentRepository _environmentRepository;

  IntelligenceBloc({
    required this._engine,
    required this._riskRepository,
    required this._vitalsRepository,
    required this._activityRepository,
    required this._sleepRepository,
    required this._environmentRepository,
  })  : super(const IntelligenceInitial()) {
    on<GenerateInsights>(_onGenerateInsights);
  }

  Future<void> _onGenerateInsights(
    GenerateInsights event,
    Emitter<IntelligenceState> emit,
  ) async {
    emit(const IntelligenceLoading());
    try {
      final now = DateTime.now();
      
      final riskHistory = await _riskRepository.getRiskRecords(limit: 50); // Get last 50 risk evaluations
      final vitalsHistory = await _vitalsRepository.getRecordsBetween(
        now.subtract(const Duration(days: 7)),
        now,
      );
      
      const storage = FlutterSecureStorage();
      int? userAge;
      final dobStr = await storage.read(key: 'user_dob');
      if (dobStr != null) {
        try {
          final dob = DateTime.parse(dobStr);
          final today = DateTime.now();
          userAge = today.year - dob.year;
          if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
            userAge--;
          }
        } catch (_) {}
      }

      final baselineModel = await _vitalsRepository.getRollingBaseline(now: now);
      PersonalBaseline baseline;
      if (baselineModel != null) {
        baseline = PersonalBaseline(
          age: userAge,
          averageHeartRateBpm: baselineModel.averageHeartRate,
          averageSpo2Percent: baselineModel.averageSpo2,
          averageSystolicBp: baselineModel.averageSystolicBp,
          averageDiastolicBp: baselineModel.averageDiastolicBp,
          sampleCount: baselineModel.sampleCount,
          calculatedAt: baselineModel.calculatedAt,
        );
      } else {
        baseline = PersonalBaseline(
          age: userAge,
          averageHeartRateBpm: 75.0,
          averageSpo2Percent: 97.0,
          averageSystolicBp: 120.0,
          averageDiastolicBp: 80.0,
          sampleCount: 1,
          calculatedAt: now,
        );
      }

      final environment = await _environmentRepository.getCurrentEnvironment();
      final activity = await _activityRepository.getCurrentActivityContext();
      final sleep = await _sleepRepository.getCurrentSleepContext();

      final insights = _engine.generateInsights(
        riskHistory: riskHistory,
        vitalsHistory: vitalsHistory,
        baseline: baseline,
        currentActivity: activity,
        currentSleep: sleep,
        currentEnvironment: environment,
      );

      final timelineEvents = riskHistory.map((risk) => RiskTimelineEvent(
        timestamp: risk.createdAt,
        overallScore: risk.riskResult.overallScore,
        domainResults: risk.riskResult.domainResults,
      )).toList();

      emit(IntelligenceLoaded(insights, timelineEvents));
    } catch (e) {
      emit(IntelligenceError(e.toString()));
    }
  }
}
