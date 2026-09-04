import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/camera/camera_service.dart';
import '../bloc/ppg_scan_bloc.dart';
import '../bloc/ppg_scan_event.dart';
import '../bloc/ppg_scan_state.dart';
import '../widgets/roi_overlay.dart';
import '../widgets/waveform_widget.dart';
import 'vitals_summary_page.dart';
import '../../../vitals_history/data/repositories/vitals_repository_impl.dart';
import '../../../vitals_history/presentation/pages/local_vitals_history_page.dart';

class PpgScanPage extends StatelessWidget {
  const PpgScanPage({
    required this.cameraService,
    required this.vitalsRepository,
    super.key,
  });
  final CameraService cameraService;
  final VitalsRepositoryImpl vitalsRepository;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return BlocListener<PpgScanBloc, PpgScanState>(
      listener: (context, state) {
        if (state.status == ScanStatus.completed && state.result != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VitalsSummaryPage(
                result: state.result!,
                onScanAgain: () {
                  Navigator.of(context).pop();
                  context.read<PpgScanBloc>().add(const ResetScan());
                },
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              _header(context, colorScheme, theme),
              const SizedBox(height: 18),
              _preview(context, colorScheme),
              const SizedBox(height: 18),
              _signalPanel(context, colorScheme),
              const SizedBox(height: 18),
              _action(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme colorScheme, ThemeData theme) => Row(
    children: [
      Icon(Icons.eco_outlined, color: colorScheme.primary),
      const SizedBox(width: 8),
      Text(
        'Senvo',
        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const Spacer(),
      IconButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                LocalVitalsHistoryPage(repository: vitalsRepository),
          ),
        ),
        icon: const Icon(Icons.history),
        tooltip: 'Local history',
      ),
      const SizedBox(width: 4),
      Text(
        'PPG SCAN',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    ],
  );

  Widget _preview(BuildContext context, ColorScheme colorScheme) => BlocSelector<PpgScanBloc, PpgScanState, bool>(
    selector: (state) => state.torchEnabled,
    builder: (context, torchEnabled) => AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cameraService.isReady)
              CameraPreview(cameraService.controller!)
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 52,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7)],
                ),
              ),
            ),
            const RoiOverlay(),
            Positioned(
              left: 18,
              bottom: 18,
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: torchEnabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    torchEnabled ? 'Torch active' : 'Ready',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _signalPanel(BuildContext context, ColorScheme colorScheme) => BlocBuilder<PpgScanBloc, PpgScanState>(
    buildWhen: (previous, current) => 
        previous.waveformSamples != current.waveformSamples ||
        previous.signalQuality != current.signalQuality,
    builder: (context, state) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PPG SIGNAL',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          WaveformWidget(samples: state.waveformSamples),
          Row(
            children: [
              const Text('Signal quality'),
              const Spacer(),
              Text(
                state.signalQuality == 0
                    ? 'Waiting'
                    : state.signalQuality >= .75
                    ? 'GOOD'
                    : 'FAIR',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _action(BuildContext context, ColorScheme colorScheme) => BlocBuilder<PpgScanBloc, PpgScanState>(
    buildWhen: (previous, current) => 
        previous.status != current.status || 
        previous.errorMessage != current.errorMessage || 
        previous.elapsedTime != current.elapsedTime || 
        previous.progress != current.progress,
    builder: (context, state) {
      final active =
          state.status == ScanStatus.scanning ||
          state.status == ScanStatus.processing;
      final message =
          state.errorMessage ??
          (state.status == ScanStatus.insufficientSignal
              ? 'Signal quality too low. Keep your finger steady and cover the lens.'
              : 'Cover the rear camera and flash completely.');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state.status == ScanStatus.scanning
                    ? 'Scanning...'
                    : state.status == ScanStatus.processing
                    ? 'Processing...'
                    : 'Ready to scan',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${state.elapsedTime.toStringAsFixed(1)} / 10.0 s',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: active
                  ? null
                  : () => context.read<PpgScanBloc>().add(const BeginScan()),
              icon: Icon(
                state.status == ScanStatus.insufficientSignal
                    ? Icons.refresh
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                state.status == ScanStatus.insufficientSignal
                    ? 'Try again'
                    : 'Start 10-second scan',
              ),
            ),
          ),
        ],
      );
    },
  );
}
