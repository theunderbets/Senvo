import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/senvo_theme.dart';
import 'widgets/baseline_comparison_card.dart';
import '../history/local_health_history_page.dart';
import '../../features/vitals_history/presentation/bloc/history_bloc.dart';
import '../../features/vitals_history/presentation/bloc/history_state.dart';
import '../../features/vitals_history/presentation/bloc/history_event.dart';

class VitalsPage extends StatefulWidget {
  const VitalsPage({super.key});

  @override
  State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(LoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vitals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LocalHealthHistoryPage(),
                ),
              );
            },
          )
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading || state.status == HistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HistoryStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Error loading vitals',
                style: TextStyle(color: context.themeColors.riskEmergency),
              ),
            );
          }
          if (state.records.isEmpty) {
            return Center(
              child: Text(
                'No vitals data available. Please take a scan.',
                style: TextStyle(color: context.themeColors.muted),
              ),
            );
          }

          final latest = state.records.first;
          final baseline = state.baseline;

          return ListView(
            padding: const EdgeInsets.all(SenvoSpacing.md),
            children: [
              Text(
                'Baseline Analysis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: SenvoSpacing.sm),
              Text(
                baseline != null 
                  ? 'Your current vitals compared against your 7-day rolling average (based on ${baseline.sampleCount} scans).'
                  : 'Your current vitals (baseline not available yet).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.themeColors.muted,
                ),
              ),
              const SizedBox(height: SenvoSpacing.lg),
              
              BaselineComparisonCard(
                title: 'Resting Heart Rate',
                currentValue: latest.heartRateBpm,
                baselineValue: baseline?.averageHeartRate ?? latest.heartRateBpm,
                unit: 'bpm',
                icon: Icons.favorite,
                isHigherWorse: true,
              ),
              const SizedBox(height: SenvoSpacing.md),
              
              BaselineComparisonCard(
                title: 'Blood Oxygen (SpO₂)',
                currentValue: latest.spo2Percent,
                baselineValue: baseline?.averageSpo2 ?? latest.spo2Percent,
                unit: '%',
                icon: Icons.air,
                isHigherWorse: false,
              ),
              const SizedBox(height: SenvoSpacing.md),
              
              BaselineComparisonCard(
                title: 'Systolic Blood Pressure',
                currentValue: latest.systolicBp,
                baselineValue: baseline?.averageSystolicBp ?? latest.systolicBp,
                unit: 'mmHg',
                icon: Icons.monitor_heart,
                isHigherWorse: true,
              ),
              const SizedBox(height: SenvoSpacing.md),

              BaselineComparisonCard(
                title: 'Diastolic Blood Pressure',
                currentValue: latest.diastolicBp,
                baselineValue: baseline?.averageDiastolicBp ?? latest.diastolicBp,
                unit: 'mmHg',
                icon: Icons.monitor_heart,
                isHigherWorse: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
