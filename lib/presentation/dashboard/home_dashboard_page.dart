import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/senvo_theme.dart';
import '../../core/risk/risk_enums.dart';
import '../../core/widgets/cards/risk_status_card.dart';
import '../../core/widgets/cards/vital_sign_card.dart';
import 'widgets/overall_risk_card.dart';
import 'widgets/environmental_banner.dart';
import 'widgets/health_advisory_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/ppg_scan/presentation/bloc/ppg_scan_bloc.dart';
import '../../features/ppg_scan/presentation/bloc/ppg_scan_state.dart';
import '../../services/camera/camera_service.dart';
import '../../features/vitals_history/data/repositories/vitals_repository_impl.dart';
import '../vitals/vitals_page.dart';
import '../../features/health_risk/presentation/bloc/health_risk_bloc.dart';
import '../../features/health_risk/presentation/bloc/health_risk_state.dart';
import '../../features/health_risk/presentation/bloc/health_risk_event.dart';
import '../../features/vitals_history/presentation/bloc/history_bloc.dart';
import '../../features/vitals_history/presentation/bloc/history_state.dart';
import '../../features/vitals_history/presentation/bloc/history_event.dart';
import '../settings/profile_page.dart';
import '../settings/bloc/app_settings_cubit.dart';
import '../settings/bloc/app_settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../core/environment/environment_repository.dart';
import '../../core/sleep/sleep_repository.dart';
import '../../core/activity/activity_repository.dart';
import '../../core/sleep/sleep_models.dart';
import '../../core/activity/activity_models.dart';
import '../../core/environment/environment_models.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({
    required this.camera,
    required this.vitalsRepository,
    required this.environmentRepository,
    required this.sleepRepository,
    required this.activityRepository,
    super.key,
  });

  final CameraService camera;
  final VitalsRepositoryImpl vitalsRepository;
  final EnvironmentRepository environmentRepository;
  final SleepRepository sleepRepository;
  final ActivityRepository activityRepository;

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  late Future<SleepContext> _sleepFuture;
  late Future<ActivityContext> _activityFuture;
  late Future<EnvironmentalContext> _envFuture;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _sleepFuture = widget.sleepRepository.getCurrentSleepContext();
    _activityFuture = widget.activityRepository.getCurrentActivityContext();
    _envFuture = widget.environmentRepository.getCurrentEnvironment();
    context.read<HistoryBloc>().add(LoadHistory());
    context.read<HealthRiskBloc>().add(const EvaluateHealthRisk());
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
      });
    }
  }

  String _getGreeting(AppLocalizations loc) {
    final hour = DateTime.now().hour;
    final name = _userName.isNotEmpty && _userName != 'User' ? ', $_userName' : '';
    if (hour < 12) return '${loc.goodMorning}$name';
    if (hour < 17) return '${loc.goodAfternoon}$name';
    return '${loc.goodEvening}$name';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/senvo_logo.png', height: 32),
            const SizedBox(width: 8),
            Text(_getGreeting(loc)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.asset('assets/images/cvrgu_logo.jpg', height: 28),
            ),
          ),
          BlocBuilder<AppSettingsCubit, AppSettingsState>(
            builder: (context, state) {
              final isDark = state.themeMode == ThemeMode.dark || 
                (state.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  context.read<AppSettingsCubit>().updateThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilePage(vitalsRepository: widget.vitalsRepository),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<PpgScanBloc, PpgScanState>(
        listener: (context, state) {
          if (state.status == ScanStatus.completed) {
            context.read<HealthRiskBloc>().add(const EvaluateHealthRisk());
            context.read<HistoryBloc>().add(LoadHistory());
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SenvoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<HealthRiskBloc, HealthRiskState>(
              builder: (context, state) {
                if (state is HealthRiskLoading) {
                  return const OverallRiskCard(
                    healthRiskLevel: HealthRiskLevel.normal,
                    score: 0,
                    message: '',
                    isLoading: true,
                  );
                } else if (state is HealthRiskError) {
                  return OverallRiskCard(
                    healthRiskLevel: HealthRiskLevel.normal,
                    score: 0,
                    message: '',
                    hasError: true,
                    errorMessage: state.message,
                  );
                } else if (state is HealthRiskLoaded) {
                  HealthRiskLevel hLevel = HealthRiskLevel.normal;
                  if (state.riskResult.overallLevel == RiskLevel.elevated) hLevel = HealthRiskLevel.watch;
                  if (state.riskResult.overallLevel == RiskLevel.high) hLevel = HealthRiskLevel.alert;
                  if (state.riskResult.overallLevel == RiskLevel.critical) hLevel = HealthRiskLevel.emergency;
                  return OverallRiskCard(
                    healthRiskLevel: hLevel,
                    score: state.riskResult.overallScore.toInt(),
                    message: state.riskResult.criticalAlerts.isNotEmpty
                        ? state.riskResult.criticalAlerts.join(' ')
                        : loc.overallHealthGood,
                  );
                }
                return OverallRiskCard(
                  healthRiskLevel: HealthRiskLevel.normal,
                  score: 0,
                  message: loc.allSystemsGood,
                );
              },
            ),
            const SizedBox(height: SenvoSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.liveVitals,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VitalsPage(),
                      ),
                    );
                  },
                  child: Text(loc.seeAll),
                ),
              ],
            ),
            BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, state) {
                final isLoading = state.status == HistoryStatus.loading || state.status == HistoryStatus.initial;
                final hasError = state.status == HistoryStatus.error;
                
                String hr = '--';
                String spo2 = '--';
                String bp = '--/--';
                
                if (state.status == HistoryStatus.loaded && state.records.isNotEmpty) {
                  final latest = state.records.first;
                  hr = latest.heartRateBpm.toStringAsFixed(0);
                  spo2 = latest.spo2Percent.toStringAsFixed(0);
                  bp = '${latest.systolicBp.toStringAsFixed(0)}/${latest.diastolicBp.toStringAsFixed(0)}';
                }
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: VitalSignCard(
                            title: loc.heartRate,
                            value: hr,
                            unit: loc.bpm,
                            icon: Icons.monitor_heart,
                            riskLevel: RiskLevel.low,
                            isLoading: isLoading,
                            hasError: hasError,
                          ),
                        ),
                        const SizedBox(width: SenvoSpacing.sm),
                        Expanded(
                          child: VitalSignCard(
                            title: loc.spo2,
                            value: spo2,
                            unit: loc.percent,
                            icon: Icons.air,
                            riskLevel: RiskLevel.low,
                            isLoading: isLoading,
                            hasError: hasError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SenvoSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: VitalSignCard(
                            title: loc.bloodPressure,
                            value: bp,
                            unit: loc.mmHg,
                            icon: Icons.monitor_heart,
                            riskLevel: RiskLevel.low,
                            isLoading: isLoading,
                            hasError: hasError,
                          ),
                        ),
                        const SizedBox(width: SenvoSpacing.sm),
                        Expanded(
                          child: FutureBuilder<SleepContext>(
                            future: _sleepFuture,
                            builder: (context, snapshot) {
                              final isLoading = snapshot.connectionState == ConnectionState.waiting;
                              final hasError = snapshot.hasError;
                              final sleepHours = snapshot.hasData ? snapshot.data!.sleepDuration.inMinutes / 60.0 : 0.0;
                              final value = snapshot.hasData ? sleepHours.toStringAsFixed(1) : '--';
                              final quality = snapshot.hasData ? (snapshot.data!.sleepQuality ?? 0.5) : 0.5;
                              final riskLevel = quality >= 0.7 ? RiskLevel.low : (quality >= 0.4 ? RiskLevel.elevated : RiskLevel.high);
                              
                              return VitalSignCard(
                                title: loc.sleep,
                                value: value,
                                unit: loc.hrs,
                                icon: Icons.bedtime,
                                riskLevel: riskLevel,
                                isLoading: isLoading,
                                hasError: hasError,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

          ],
        );
      },
    ),
            const SizedBox(height: SenvoSpacing.lg),
            Text(
              loc.activeRisks,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SenvoSpacing.sm),
            BlocBuilder<HealthRiskBloc, HealthRiskState>(
              builder: (context, state) {
                if (state is HealthRiskLoaded) {
                  final elevatedRisks = state.riskResult.domainResults.values.where(
                      (r) => r.level == RiskLevel.elevated || r.level == RiskLevel.high || r.level == RiskLevel.critical).toList();
                  
                  if (elevatedRisks.isEmpty) {
                    return RiskStatusCard(
                      title: loc.noActiveRisks,
                      subtitle: loc.allDomainsNormal,
                      riskLevel: RiskLevel.low,
                      icon: Icons.check_circle_outline,
                      value: loc.normal,
                    );
                  }

                  return Column(
                    children: elevatedRisks.map((risk) {
                      IconData icon = Icons.warning_amber_rounded;
                      if (risk.domain.toLowerCase().contains('cardiovascular')) icon = Icons.favorite_border;
                      if (risk.domain.toLowerCase().contains('respiratory')) icon = Icons.air;
                      if (risk.domain.toLowerCase().contains('heat')) icon = Icons.local_fire_department;
                      if (risk.domain.toLowerCase().contains('dehydration')) icon = Icons.water_drop;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: SenvoSpacing.sm),
                        child: RiskStatusCard(
                          title: risk.domain,
                          subtitle: risk.primaryContributors.isNotEmpty ? risk.primaryContributors.first : loc.elevatedRiskDetected,
                          riskLevel: risk.level,
                          icon: icon,
                          value: risk.level == RiskLevel.critical ? loc.critical : risk.level == RiskLevel.high ? loc.high : loc.elevated,
                        ),
                      );
                    }).toList(),
                  );
                }
                if (state is HealthRiskInitial) {
                  return RiskStatusCard(
                    title: loc.noActiveRisks,
                    subtitle: loc.takeMeasurement,
                    riskLevel: RiskLevel.low,
                    icon: Icons.check_circle_outline,
                    value: '-',
                  );
                }
                if (state is HealthRiskError) {
                  return RiskStatusCard(
                    title: loc.error,
                    subtitle: state.message,
                    riskLevel: RiskLevel.low,
                    icon: Icons.error_outline,
                    value: '-',
                  );
                }
                if (state is HealthRiskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RiskStatusCard(
                  title: loc.noActiveRisks,
                  subtitle: loc.takeMeasurement,
                  riskLevel: RiskLevel.low,
                  icon: Icons.check_circle_outline,
                  value: '-',
                );
              },
            ),
            const SizedBox(height: SenvoSpacing.lg),
            FutureBuilder<EnvironmentalContext>(
              future: _envFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink(); // Hide if failed
                }
                
                final env = snapshot.data!;
                final temp = env.ambientTemperatureCelsius ?? 25.0;
                final humidity = env.humidityPercent ?? 50.0;
                final aqi = env.aqi ?? 50.0;
                
                RiskLevel heatRisk = RiskLevel.low;
                if (temp > 35) {
                  heatRisk = RiskLevel.critical;
                } else if (temp > 32) heatRisk = RiskLevel.high;
                else if (temp > 28) heatRisk = RiskLevel.elevated;

                return EnvironmentalBanner(
                  temperature: temp,
                  humidity: humidity,
                  aqi: aqi.toInt(),
                  heatStressRisk: heatRisk,
                );
              },
            ),
            const SizedBox(height: SenvoSpacing.lg),
            const HealthAdvisoryCard(
              advisoryText: 'Your heart rate is elevated and you had poor sleep last night. Given the high ambient temperature and moderate AQI, prioritize hydration and avoid strenuous activity outdoors for the next few hours.',
            ),
          ],
        ),
      ),
    ),
  );
}
}
