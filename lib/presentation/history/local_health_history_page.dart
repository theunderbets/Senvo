import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/senvo_theme.dart';
import '../../features/vitals_history/presentation/bloc/history_bloc.dart';
import '../../features/vitals_history/presentation/bloc/history_state.dart';
import 'export_helper.dart';
import '../../features/vitals_history/presentation/bloc/history_event.dart';

class LocalHealthHistoryPage extends StatefulWidget {
  const LocalHealthHistoryPage({super.key});

  @override
  State<LocalHealthHistoryPage> createState() => _LocalHealthHistoryPageState();
}

class _LocalHealthHistoryPageState extends State<LocalHealthHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(LoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health History'),
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Export Data',
                onPressed: () {
                  if (state.records.isNotEmpty) {
                    ExportHelper.exportToCsv(state.records);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No data to export.')),
                    );
                  }
                },
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
                state.errorMessage ?? 'Error loading history',
                style: TextStyle(color: context.themeColors.riskEmergency),
              ),
            );
          }
          if (state.records.isEmpty) {
            return Center(
              child: Text(
                'No health history available.',
                style: TextStyle(color: context.themeColors.muted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(SenvoSpacing.md),
            itemCount: state.records.length,
            separatorBuilder: (context, index) => const SizedBox(height: SenvoSpacing.sm),
            itemBuilder: (context, index) {
              final scan = state.records[index];
              final dateStr = DateFormat('MMM d, y • h:mm a').format(scan.timestamp);
              
              // Simplistic risk mapping for UI purposes (backend risk engine gives precise risk per scan)
              bool isNormal = scan.signalQualityIndex >= 0.8 && scan.heartRateBpm > 50 && scan.heartRateBpm < 100;
              String stressLabel = isNormal ? 'Normal' : 'Elevated';
              Color labelColor = isNormal ? context.themeColors.riskNormal : context.themeColors.riskWatch;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(SenvoSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: labelColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stressLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: labelColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SenvoSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHistoryMetric(context, 'HR', '${scan.heartRateBpm.toInt()} bpm'),
                          _buildHistoryMetric(context, 'SpO₂', '${scan.spo2Percent.toInt()}%'),
                          _buildHistoryMetric(context, 'BP', '${scan.systolicBp.toInt()}/${scan.diastolicBp.toInt()}'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryMetric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.themeColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
