import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/activity/activity_models.dart';
import '../../../../core/activity/activity_repository.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/environment/environment_repository.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../../../../core/sleep/sleep_repository.dart';
import '../../domain/engines/unified_risk_engine.dart';
import '../../domain/repositories/health_risk_repository.dart';
import '../../../emergency/presentation/bloc/emergency_bloc.dart';
import '../../../emergency/presentation/bloc/emergency_event.dart';
import '../../../emergency/domain/emergency_models.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../domain/entities/health_risk_record.dart';
import 'health_risk_event.dart';
import 'health_risk_state.dart';
import '../../../vitals_history/domain/repositories/vitals_repository.dart';
import '../../../../services/notifications/notification_service.dart';

class HealthRiskBloc extends Bloc<HealthRiskEvent, HealthRiskState> {
  final UnifiedHealthRiskEngine _engine;
  final HealthRiskRepository _riskRepository;
  final ActivityRepository _activityRepository;
  final SleepRepository _sleepRepository;
  final VitalsRepository _vitalsRepository;
  final EnvironmentRepository _environmentRepository;
  final EmergencyBloc? emergencyBloc;

  HealthRiskBloc({
    required this._engine,
    required this._riskRepository,
    required this._activityRepository,
    required this._sleepRepository,
    required this._vitalsRepository,
    required this._environmentRepository,
    this.emergencyBloc,
  })  : super(const HealthRiskInitial()) {
    on<EvaluateHealthRisk>(_onEvaluateHealthRisk);
  }

  Future<void> _onEvaluateHealthRisk(
    EvaluateHealthRisk event,
    Emitter<HealthRiskState> emit,
  ) async {
    emit(const HealthRiskLoading()); print("Evaluating Health Risk...");
    try {
      final now = DateTime.now();
      
      // Fetch data from all repositories concurrently
      final recentRecordsFuture = _vitalsRepository.getRecordsBetween(
        now.subtract(const Duration(hours: 24)),
        now,
      );
      final environmentFuture = _environmentRepository.getCurrentEnvironment();
      final activityFuture = _activityRepository.getCurrentActivityContext();
      final sleepFuture = _sleepRepository.getCurrentSleepContext();

      final results = await Future.wait([
        recentRecordsFuture,
        environmentFuture,
        activityFuture,
        sleepFuture,
      ]).timeout(const Duration(seconds: 15));

      final recentRecords = results[0] as List;
      final environment = results[1] as EnvironmentalContext;
      final activity = results[2] as ActivityContext;
      final sleep = results[3] as SleepContext;

      if (recentRecords.isEmpty) {
        print("HealthRiskBloc: recentRecords is empty. Emitting HealthRiskInitial.");
        emit(const HealthRiskInitial());
        return;
      }

      
      final latest = recentRecords.first;

      final snapshot = CurrentHealthSnapshot(
        timestamp: latest.timestamp,
        heartRateBpm: latest.heartRateBpm,
        spo2Percent: latest.spo2Percent,
        systolicBp: latest.systolicBp,
        diastolicBp: latest.diastolicBp,
        bodyTemperatureCelsius: 37.0, // No body temp sensor available
        ambientTemperatureCelsius: environment.ambientTemperatureCelsius ?? 25.0,
        humidityPercent: environment.humidityPercent ?? 50.0,
        aqi: environment.aqi ?? 50.0,
        activityLevel: activity.intensity,
        movementLevel: activity.intensity,
        sleepDuration: sleep.sleepDuration,
        signalQuality: latest.signalQualityIndex,
      );

      final prefs = await SharedPreferences.getInstance();
      int? userAge;
      final dobStr = prefs.getString('user_dob');
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

      // WHO-defined normal baselines for adults
      final baseline = PersonalBaseline(
        age: userAge,
        averageHeartRateBpm: 75.0,  // WHO: 60-100 bpm, midpoint ~75
        averageSpo2Percent: 97.0,   // WHO: >=95% normal
        averageSystolicBp: 120.0,   // WHO: <120 mmHg optimal
        averageDiastolicBp: 80.0,   // WHO: <80 mmHg optimal
        sampleCount: 1,
        calculatedAt: now,
      );

      const config = SystemRiskConfiguration();

      final result = _engine.assessRisk(
        snapshot: snapshot,
        baseline: baseline,
        config: config.domainConfig,
        environment: environment,
        activity: activity,
        sleep: sleep,
      );
      
      await _riskRepository.saveRiskRecord(HealthRiskRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        riskResult: result,
      ));
      
      // Trigger notification if risk is elevated or worse
      if (result.overallLevel == RiskLevel.elevated || 
          result.overallLevel == RiskLevel.high || 
          result.overallLevel == RiskLevel.critical) {
        
        final highestDomain = result.domainResults.entries
            .reduce((a, b) => a.value.score > b.value.score ? a : b)
            .key;
            
        final title = '${result.overallLevel.name.toUpperCase()} Health Risk Detected';
        final body = result.criticalAlerts.isNotEmpty 
            ? result.criticalAlerts.first 
            : 'Elevated risk detected in $highestDomain domain.';
            
        NotificationService().showRiskAlert(
          title,
          body,
          result.overallLevel,
        );
      }

      // Automatically trigger emergency flow if critical
      if (result.overallLevel == RiskLevel.critical) {
        emergencyBloc?.add(TriggerEmergency(
          alertType: EmergencyAlertType.manualEmergency,
          customHeadline: 'Critical Health Risk Detected: ${result.criticalAlerts.join(", ")}',
        ));
      }

      print("HealthRiskBloc: Finished evaluation. Emitting HealthRiskLoaded.");
      emit(HealthRiskLoaded(result));
    } catch (e, stackTrace) {
      print("HealthRiskBloc Error: $e\n$stackTrace");
      emit(HealthRiskError(e.toString()));
    }
  }
}
