import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'disaster_models.dart';
import '../../emergency/domain/emergency_models.dart';

abstract interface class DisasterModeService {
  Future<EmergencyReadinessResult> checkReadiness();
  Future<DisasterModeState> evaluateDisasterState(bool hasNetwork, double currentRiskScore);
}

class DisasterModeServiceImpl implements DisasterModeService {
  final LocationService locationService;
  
  DisasterModeServiceImpl({required this.locationService});

  @override
  Future<EmergencyReadinessResult> checkReadiness() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasNetwork = !connectivityResult.contains(ConnectivityResult.none);
    
    final smsStatus = await Permission.sms.status;
    final smsPermissionsGranted = smsStatus.isGranted;

    final location = await locationService.getCachedLocation();
    final locationCacheAge = location != null 
        ? DateTime.now().difference(location.capturedAt)
        : null;

    return EmergencyReadinessResult(
      hasNetwork: hasNetwork,
      smsPermissionsGranted: smsPermissionsGranted,
      locationCacheAge: locationCacheAge,
      localModelsAvailable: true, // Assuming TFLite models are bundled
    );
  }

  @override
  Future<DisasterModeState> evaluateDisasterState(bool hasNetwork, double currentRiskScore) async {
    if (!hasNetwork) {
      if (currentRiskScore > 75) {
        return DisasterModeState.active;
      }
      return DisasterModeState.warning;
    }
    return DisasterModeState.safe;
  }
}
