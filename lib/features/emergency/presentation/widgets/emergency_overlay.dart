import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/senvo_theme.dart';
import '../../domain/emergency_models.dart';
import '../bloc/emergency_bloc.dart';
import '../bloc/emergency_event.dart';
import '../bloc/emergency_state.dart';

class EmergencyOverlayListener extends StatelessWidget {
  final Widget child;

  const EmergencyOverlayListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmergencyBloc, EmergencyState>(
      listener: (context, state) {
        if (state is EmergencyActive) {
          _showEmergencyDialog(context, state);
        }
      },
      child: child,
    );
  }

  void _showEmergencyDialog(BuildContext context, EmergencyActive state) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: _EmergencyDialogContent(state: state),
          ),
        );
      },
    );
  }
}

class _EmergencyDialogContent extends StatelessWidget {
  final EmergencyActive state;

  const _EmergencyDialogContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool isSending = state.smsStatus == null || state.smsStatus == SmsDispatchStatus.sent;
    
    return Scaffold(
      backgroundColor: context.themeColors.riskEmergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SenvoSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: SenvoSpacing.xl),
              Text(
                'EMERGENCY DETECTED',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: SenvoSpacing.md),
              Text(
                state.explanation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: SenvoSpacing.xxl),
              if (state.smsStatus != null) ...[
                _buildStatusIndicator(state.smsStatus!),
              ] else ...[
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: SenvoSpacing.md),
                const Text(
                  'Preparing Alert...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: context.themeColors.riskEmergency,
                  padding: const EdgeInsets.symmetric(vertical: SenvoSpacing.lg),
                ),
                onPressed: () {
                  context.read<EmergencyBloc>().add(CancelEmergency());
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text(
                  'CANCEL ALERT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(SmsDispatchStatus status) {
    IconData icon;
    String text;
    
    switch (status) {
      case SmsDispatchStatus.sent:
        icon = Icons.check_circle_outline;
        text = 'Alert Sent to Contacts';
        break;
      case SmsDispatchStatus.failed:
      case SmsDispatchStatus.permissionDenied:
      case SmsDispatchStatus.unsupported:
      case SmsDispatchStatus.noSim:
      case SmsDispatchStatus.serviceUnavailable:
        icon = Icons.error_outline;
        text = 'Failed to Send Alert';
        break;
      case SmsDispatchStatus.cancelled:
        icon = Icons.cancel_outlined;
        text = 'Alert Cancelled';
        break;
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: Colors.white),
        const SizedBox(height: SenvoSpacing.sm),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }
}
