import 'package:equatable/equatable.dart';

enum DisasterModeState {
  safe,
  warning, // Network loss + some risk, not critical yet
  active   // Full offline disaster mode
}

class EmergencyReadinessResult extends Equatable {
  final bool hasNetwork;
  final bool smsPermissionsGranted;
  final Duration? locationCacheAge;
  final bool localModelsAvailable;
  
  const EmergencyReadinessResult({
    required this.hasNetwork,
    required this.smsPermissionsGranted,
    this.locationCacheAge,
    required this.localModelsAvailable,
  });

  bool get isReadyForOfflineEmergency => 
      smsPermissionsGranted && 
      localModelsAvailable && 
      (locationCacheAge == null || locationCacheAge!.inHours < 12);

  @override
  List<Object?> get props => [
        hasNetwork,
        smsPermissionsGranted,
        locationCacheAge,
        localModelsAvailable,
      ];
}

class EmergencyTrigger extends Equatable {
  final String triggerId;
  final String triggerSource; // e.g., 'FallDetection', 'ManualSOS', 'HighRiskOffline'
  final DateTime timestamp;
  final double severity; // 0.0 to 1.0

  const EmergencyTrigger({
    required this.triggerId,
    required this.triggerSource,
    required this.timestamp,
    required this.severity,
  });

  @override
  List<Object?> get props => [triggerId, triggerSource, timestamp, severity];
}
