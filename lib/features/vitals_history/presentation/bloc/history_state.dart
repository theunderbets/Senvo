import 'package:equatable/equatable.dart';
import '../../domain/entities/baseline_model.dart';
import '../../domain/entities/vital_record.dart';

enum HistoryStatus { initial, loading, loaded, empty, clearing, error }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.records = const [],
    this.baseline,
    this.errorMessage,
    this.hasMore = true,
  });
  final HistoryStatus status;
  final List<VitalRecord> records;
  final BaselineModel? baseline;
  final String? errorMessage;
  final bool hasMore;
  HistoryState copyWith({
    HistoryStatus? status,
    List<VitalRecord>? records,
    BaselineModel? baseline,
    String? errorMessage,
    bool? hasMore,
  }) => HistoryState(
    status: status ?? this.status,
    records: records ?? this.records,
    baseline: baseline ?? this.baseline,
    errorMessage: errorMessage ?? this.errorMessage,
    hasMore: hasMore ?? this.hasMore,
  );
  @override
  List<Object?> get props => [status, records, baseline, errorMessage, hasMore];
}
