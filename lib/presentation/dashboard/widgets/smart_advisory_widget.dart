import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/environment/environment_models.dart';
import '../../../core/sleep/sleep_models.dart';
import '../../../core/risk/risk_enums.dart';
import '../../../features/health_risk/presentation/bloc/health_risk_bloc.dart';
import '../../../features/health_risk/presentation/bloc/health_risk_state.dart';
import '../../../features/vitals_history/presentation/bloc/history_bloc.dart';
import '../../../features/vitals_history/presentation/bloc/history_state.dart';
import '../../settings/bloc/app_settings_cubit.dart';
import 'health_advisory_card.dart';

class SmartAdvisoryWidget extends StatelessWidget {
  final EnvironmentalContext? environmentalContext;
  final SleepContext? sleepContext;

  const SmartAdvisoryWidget({
    Key? key,
    this.environmentalContext,
    this.sleepContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final healthRiskState = context.watch<HealthRiskBloc>().state;
    final historyState = context.watch<HistoryBloc>().state;
    final isDisasterMode = context.watch<AppSettingsCubit>().state.isDisasterMode;

    String advisory = _generateAdvisory(
      healthRiskState,
      historyState,
      environmentalContext,
      sleepContext,
      isDisasterMode,
    );

    if (advisory.isEmpty) {
      return const SizedBox.shrink();
    }

    return HealthAdvisoryCard(advisoryText: advisory);
  }

  String _generateAdvisory(
    HealthRiskState riskState,
    HistoryState historyState,
    EnvironmentalContext? env,
    SleepContext? sleep,
    bool isDisasterMode,
  ) {
    if (isDisasterMode) {
      return 'DISASTER MODE ACTIVE: Local SOS protocols are armed. Please follow offline emergency guidelines. Keep your device charged and conserve battery.';
    }

    List<String> advice = [];

    // Analyze Vitals
    if (historyState.status == HistoryStatus.loaded && historyState.records.isNotEmpty) {
      final latest = historyState.records.first;
      if (latest.heartRateBpm > 100) {
        advice.add('Your heart rate is elevated.');
      } else if (latest.heartRateBpm < 50) {
        advice.add('Your heart rate is unusually low.');
      }
      
      if (latest.spo2Percent < 95) {
        advice.add('Your oxygen levels are lower than normal.');
      }
    }

    // Analyze Sleep
    if (sleep != null) {
      final sleepHours = sleep.sleepDuration.inMinutes / 60.0;
      if (sleepHours < 6) {
        advice.add('You had short sleep last night.');
      } else if ((sleep.sleepQuality ?? 1.0) < 0.6) {
        advice.add('You had poor sleep quality last night.');
      }
    }

    // Analyze Environment
    if (env != null) {
      final temp = env.ambientTemperatureCelsius ?? 25.0;
      if (temp > 32) {
        advice.add('Given the high ambient temperature, prioritize hydration and avoid strenuous activity outdoors.');
      } else if (temp < 10) {
        advice.add('It is cold outside, make sure to stay warm.');
      }
      
      if ((env.aqi ?? 0) > 100) {
        advice.add('Air quality is poor today, consider staying indoors.');
      }
    }

    if (advice.isEmpty) {
      if (riskState is HealthRiskLoaded && riskState.riskResult.overallLevel != RiskLevel.low) {
         return 'Your overall risk is elevated. Please monitor your health and avoid overexertion.';
      }
      return 'Your vitals and environmental conditions look good. Have a great day!';
    }

    return advice.join(' ');
  }
}
