import 'activity_models.dart';

abstract class ActivityRepository {
  /// Stream of real-time activity context.
  Stream<ActivityContext> watchActivityContext();
  
  /// Get current activity context.
  Future<ActivityContext> getCurrentActivityContext();

  /// Get current movement context.
  Future<MovementContext> getCurrentMovementContext();
}
