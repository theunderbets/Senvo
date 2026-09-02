import 'dart:async';

import '../activity/activity_models.dart';
import '../activity/activity_repository.dart';
import '../sleep/sleep_models.dart';
import '../sleep/sleep_repository.dart';
import '../../features/health_risk/domain/repositories/health_risk_repository.dart';
import '../../features/health_risk/domain/entities/health_risk_record.dart';

class MockActivityRepository implements ActivityRepository {
  @override
  Stream<ActivityContext> watchActivityContext() {
    return Stream.empty();
  }

  @override
  Future<ActivityContext> getCurrentActivityContext() async {
    return const ActivityContext(
      state: ActivityState.resting,
      intensity: 0.2,
      activeDuration: Duration.zero,
      sedentaryDuration: Duration(hours: 1),
    );
  }

  @override
  Future<MovementContext> getCurrentMovementContext() async {
    return MovementContext(
      movementScore: 0.1,
      activeDuration: Duration.zero,
      sedentaryDuration: const Duration(hours: 1),
      measuredAt: DateTime.now(),
    );
  }
}

class MockSleepRepository implements SleepRepository {
  @override
  Stream<SleepContext> watchSleepContext() {
    return Stream.empty();
  }

  @override
  Future<SleepContext> getCurrentSleepContext() async {
    final now = DateTime.now();
    return SleepContext(
      sleepDuration: const Duration(hours: 7),
      sleepQuality: 0.8,
      sleepStart: now.subtract(const Duration(hours: 7)),
      sleepEnd: now,
    );
  }
}

class MockHealthRiskRepository implements HealthRiskRepository {
  final List<HealthRiskRecord> _records = [];

  @override
  Future<void> saveRiskRecord(HealthRiskRecord record) async {
    _records.add(record);
  }

  @override
  Future<List<HealthRiskRecord>> getRiskRecords({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    return _records.toList();
  }

  @override
  Future<HealthRiskRecord?> getLatestRiskRecord() async {
    if (_records.isEmpty) return null;
    return _records.last;
  }

  @override
  Future<void> clearRiskRecords() async {
    _records.clear();
  }
}
