import 'sleep_models.dart';

abstract class SleepRepository {
  /// Stream of real-time sleep context updates.
  Stream<SleepContext> watchSleepContext();
  
  /// Get current or latest sleep context.
  Future<SleepContext> getCurrentSleepContext();
}
