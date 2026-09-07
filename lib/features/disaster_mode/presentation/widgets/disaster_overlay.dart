import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/disaster_mode_bloc.dart';
import '../bloc/disaster_mode_state.dart';
import '../../domain/disaster_models.dart';
import '../../../emergency/presentation/bloc/emergency_bloc.dart';
import '../../../emergency/presentation/bloc/emergency_event.dart';
import '../../../emergency/domain/emergency_models.dart';

class DisasterOverlay extends StatelessWidget {
  const DisasterOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisasterModeBloc, DisasterModeStateBase>(
      builder: (context, state) {
        if (state is DisasterModeStatus) {
          if (state.state == DisasterModeState.active) {
            return _buildActiveOverlay(context, state.readiness);
          } else if (state.state == DisasterModeState.warning) {
            return _buildWarningBanner(context, state.readiness);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActiveOverlay(BuildContext context, EmergencyReadinessResult readiness) {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
            const SizedBox(height: 16),
            const Text(
              'DISASTER MODE ACTIVE',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Network connection lost. Operating in offline mode. Critical functions and emergency SMS are still available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildReadinessIndicators(readiness),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<EmergencyBloc>().add(
                  TriggerEmergency(alertType: EmergencyAlertType.manualEmergency),
                );
              },
              child: const Text('TRIGGER OFFLINE SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 48), // Padding for bottom
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, EmergencyReadinessResult readiness) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          color: Colors.orange.shade800,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Network unavailable. Operating offline.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              if (!readiness.isReadyForOfflineEmergency)
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessIndicators(EmergencyReadinessResult readiness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline Capabilities',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _indicator('SMS Dispatch', readiness.smsPermissionsGranted),
          _indicator('Local AI Models', readiness.localModelsAvailable),
          _indicator('Cached Location', readiness.locationCacheAge != null && readiness.locationCacheAge!.inHours < 12),
        ],
      ),
    );
  }

  Widget _indicator(String label, bool isReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isReady ? Icons.check_circle : Icons.cancel, color: isReady ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }
}
