import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../../../core/risk/risk_validator.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../entities/risk_result.dart';
import 'cardiovascular_engine.dart';
import 'dehydration_engine.dart';
import 'emergency_evaluator.dart';
import 'fatigue_engine.dart';
import 'heat_stress_engine.dart';
import 'overall_health_engine.dart';
import 'respiratory_engine.dart';

class UnifiedHealthRiskEngine {
  UnifiedHealthRiskEngine({
    HeatStressRiskEngine? heatStressEngine,
    RespiratoryRiskEngine? respiratoryEngine,
    CardiovascularRiskEngine? cardiovascularEngine,
    DehydrationRiskEngine? dehydrationEngine,
    FatigueRiskEngine? fatigueEngine,
    OverallHealthRiskEngine? overallEngine,
    EmergencyRuleEvaluator? emergencyEvaluator,
    RiskValidator? validator,
  })  : _heatStressEngine = heatStressEngine ?? HeatStressRiskEngine(),
        _respiratoryEngine = respiratoryEngine ?? RespiratoryRiskEngine(),
        _cardiovascularEngine = cardiovascularEngine ?? CardiovascularRiskEngine(),
        _dehydrationEngine = dehydrationEngine ?? DehydrationRiskEngine(),
        _fatigueEngine = fatigueEngine ?? FatigueRiskEngine(),
        _overallEngine = overallEngine ?? OverallHealthRiskEngine(),
        _emergencyEvaluator = emergencyEvaluator ?? EmergencyRuleEvaluator(),
        _validator = validator ?? const RiskValidator();

  final HeatStressRiskEngine _heatStressEngine;
  final RespiratoryRiskEngine _respiratoryEngine;
  final CardiovascularRiskEngine _cardiovascularEngine;
  final DehydrationRiskEngine _dehydrationEngine;
  final FatigueRiskEngine _fatigueEngine;
  final OverallHealthRiskEngine _overallEngine;
  final EmergencyRuleEvaluator _emergencyEvaluator;
  final RiskValidator _validator;

  OverallRiskResult assessRisk({
    required CurrentHealthSnapshot snapshot,
    required PersonalBaseline baseline,
    required RiskConfig config,
    EnvironmentalContext? environment,
    ActivityContext? activity,
    SleepContext? sleep,
  }) {
    // 1. Sanity Check
    final validationResult = _validator.validate(snapshot);
    if (!validationResult.isValid) {
      throw ArgumentError('Invalid snapshot data: ${validationResult.errors.join(", ")}');
    }

    // 2. Emergency Rules
    final emergencies = _emergencyEvaluator.evaluate(snapshot);
    final emergencyAlerts = emergencies.map((e) => '${e.alertType}: ${e.message}').toList();

    // 3. Domain Risk Calculations
    final domainResults = <String, DomainRiskResult>{};

    domainResults['Heat Stress'] = _heatStressEngine.calculateRisk(
      currentSnapshot: snapshot,
      baseline: baseline,
      environment: environment,
      activity: activity,
      sleep: sleep,
      config: config,
    );

    domainResults['Respiratory'] = _respiratoryEngine.calculateRisk(
      currentSnapshot: snapshot,
      baseline: baseline,
      environment: environment,
      activity: activity,
      sleep: sleep,
      config: config,
    );

    domainResults['Cardiovascular'] = _cardiovascularEngine.calculateRisk(
      currentSnapshot: snapshot,
      baseline: baseline,
      environment: environment,
      activity: activity,
      sleep: sleep,
      config: config,
    );

    domainResults['Dehydration'] = _dehydrationEngine.calculateRisk(
      currentSnapshot: snapshot,
      baseline: baseline,
      environment: environment,
      activity: activity,
      sleep: sleep,
      config: config,
    );

    domainResults['Fatigue'] = _fatigueEngine.calculateRisk(
      currentSnapshot: snapshot,
      baseline: baseline,
      environment: environment,
      activity: activity,
      sleep: sleep,
      config: config,
    );

    // Filter out unavailable domains
    final validDomainResults = Map.fromEntries(
        domainResults.entries.where((e) => e.value.level != RiskLevel.unknown));

    // 4. Overall Aggregation
    final overallResult = _overallEngine.calculateRisk(
      domainResults: validDomainResults,
      config: config,
    );

    // If there are emergencies, override the overall level to critical
    RiskLevel finalOverallLevel = overallResult.level;
    double finalOverallScore = overallResult.score;

    if (emergencies.isNotEmpty) {
      finalOverallLevel = RiskLevel.critical;
      if (finalOverallScore < 80.0) {
        finalOverallScore = 85.0; // Ensure score reflects critical state
      }
    }

    return OverallRiskResult(
      overallScore: finalOverallScore,
      overallLevel: finalOverallLevel,
      overallConfidence: overallResult.confidence,
      domainResults: validDomainResults, // Only return the ones that were calculable
      criticalAlerts: emergencyAlerts,
      calculatedAt: DateTime.now(),
    );
  }
}
