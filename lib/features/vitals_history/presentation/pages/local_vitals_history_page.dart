import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/baseline_model.dart';
import '../../domain/entities/vital_record.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/history_state.dart';
class LocalVitalsHistoryPage extends StatefulWidget {
  const LocalVitalsHistoryPage({required this.repository, super.key});
  final VitalsRepository repository;

  @override
  State<LocalVitalsHistoryPage> createState() => _LocalVitalsHistoryPageState();
}

class _LocalVitalsHistoryPageState extends State<LocalVitalsHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const LoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local history'),
        actions: [
          IconButton(
            onPressed: () => _exportToCsv(context, context.read<HistoryBloc>().state.records),
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
          ),
          IconButton(
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear local history',
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading ||
              state.status == HistoryStatus.initial ||
              state.status == HistoryStatus.clearing) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HistoryStatus.error) {
            return Center(
              child: Text(state.errorMessage ?? 'Unable to load local history'),
            );
          }
          if (state.records.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<HistoryBloc>().add(const RefreshHistory()),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _PrivacyIndicator(),
                if (state.baseline != null)
                  BaselineSummaryCard(baseline: state.baseline!)
                else
                  const BaselineUnavailableCard(),
                const SizedBox(height: 20),
                const Text(
                  'Recent measurements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...state.records.map(
                  (record) => VitalHistoryCard(
                    record: record,
                    onDelete: () => context.read<HistoryBloc>().add(
                      DeleteHistoryRecord(record.id),
                    ),
                    onDetails: () => _showDetails(context, record),
                  ),
                ),
                if (state.hasMore)
                  TextButton(
                    onPressed: () => context.read<HistoryBloc>().add(
                      const LoadMoreHistory(),
                    ),
                    child: const Text('Load more'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear local history?'),
        content: const Text(
          'This permanently deletes all locally stored measurements from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<HistoryBloc>().add(const ClearHistory());
    }
  }

  Future<void> _exportToCsv(BuildContext context, List<VitalRecord> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No records to export')),
      );
      return;
    }

    try {
      final List<List<dynamic>> csvData = [
        ['Timestamp', 'Heart Rate (BPM)', 'SpO2 (%)', 'Systolic BP (mmHg)', 'Diastolic BP (mmHg)', 'Signal Quality']
      ];

      for (final r in records) {
        csvData.add([
          r.timestamp.toIso8601String(),
          r.heartRateBpm,
          r.spo2Percent,
          r.systolicBp,
          r.diastolicBp,
          r.signalQualityIndex,
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      
      final directory = await getTemporaryDirectory();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/senvo_history_$timestamp.csv');
      await file.writeAsString(csvString);

      if (context.mounted) {
        final result = await Share.shareXFiles([XFile(file.path)], text: 'Senvo Vitals History');
        
        if (result.status == ShareResultStatus.success && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully exported history'),
              backgroundColor: Color(0xff63d7b0),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  void _showDetails(BuildContext context, VitalRecord record) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Measurement details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              'HR  ${record.heartRateBpm.toStringAsFixed(0)} BPM   SpO2  ${record.spo2Percent.toStringAsFixed(1)} %',
            ),
            Text(
              'BP  ${record.systolicBp.toStringAsFixed(0)} / ${record.diastolicBp.toStringAsFixed(0)} mmHg',
            ),
            Text('SQI  ${record.signalQualityIndex.toStringAsFixed(2)}'),
            Text(
              'Frames  ${record.frameCount ?? 'Not recorded'}   Sampling rate  ${record.samplingRate?.toStringAsFixed(1) ?? 'Not recorded'} Hz',
            ),
            Text(
              'Algorithm  ${record.algorithmVersion}   Status  ${record.measurementStatus}',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyIndicator extends StatelessWidget {
  const _PrivacyIndicator();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(Icons.lock_outline, size: 18, color: Color(0xff63d7b0)),
        SizedBox(width: 8),
        Text(
          'Stored only on this device',
          style: TextStyle(color: Color(0xffa4b8b7)),
        ),
      ],
    ),
  );
}

class BaselineSummaryCard extends StatelessWidget {
  const BaselineSummaryCard({required this.baseline, super.key});
  final BaselineModel baseline;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff122426),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-DAY BASELINE',
          style: TextStyle(
            color: Color(0xff63d7b0),
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'HR  ${baseline.averageHeartRate.toStringAsFixed(0)} BPM   SpO2  ${baseline.averageSpo2.toStringAsFixed(1)} %',
        ),
        const SizedBox(height: 6),
        Text(
          'BP  ${baseline.averageSystolicBp.toStringAsFixed(0)} / ${baseline.averageDiastolicBp.toStringAsFixed(0)} mmHg   Samples  ${baseline.sampleCount}',
          style: const TextStyle(color: Color(0xffa4b8b7)),
        ),
      ],
    ),
  );
}

class BaselineUnavailableCard extends StatelessWidget {
  const BaselineUnavailableCard({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Text(
      '7-day baseline\nNot enough measurements yet. Complete more scans to establish your personal baseline.',
      style: TextStyle(color: Color(0xffa4b8b7), height: 1.4),
    ),
  );
}

class VitalHistoryCard extends StatelessWidget {
  const VitalHistoryCard({
    required this.record,
    required this.onDelete,
    required this.onDetails,
    super.key,
  });
  final VitalRecord record;
  final VoidCallback onDelete;
  final VoidCallback onDetails;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xff122426),
    child: ListTile(
      title: Text(TimeOfDay.fromDateTime(record.timestamp).format(context)),
      subtitle: Text(
        '${record.heartRateBpm.toStringAsFixed(0)} BPM    ${record.spo2Percent.toStringAsFixed(0)}%    ${record.systolicBp.toStringAsFixed(0)}/${record.diastolicBp.toStringAsFixed(0)} mmHg\nSignal quality: ${(record.signalQualityIndex * 100).round()}%',
      ),
      isThreeLine: true,
      onTap: onDetails,
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete measurement',
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 52, color: Color(0xff557371)),
          SizedBox(height: 16),
          Text(
            'No local measurements yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Complete your first Senvo scan to see your vitals history here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xffa4b8b7)),
          ),
        ],
      ),
    ),
  );
}
