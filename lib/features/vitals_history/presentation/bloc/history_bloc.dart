import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/vitals_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this.repository) : super(const HistoryState()) {
    on<LoadHistory>(_load);
    on<RefreshHistory>(_load);
    on<LoadMoreHistory>(_loadMore);
    on<DeleteHistoryRecord>(_delete);
    on<ClearHistory>(_clear);
  }
  final VitalsRepository repository;
  static const pageSize = 30;
  Future<void> _load(HistoryEvent event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(status: HistoryStatus.loading, errorMessage: null));
    try {
      final records = await repository.getAllRecords(limit: pageSize);
      final baseline = await repository.getRollingBaseline();
      emit(
        state.copyWith(
          status: records.isEmpty ? HistoryStatus.empty : HistoryStatus.loaded,
          records: records,
          baseline: baseline,
          hasMore: records.length == pageSize,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HistoryStatus.error,
          errorMessage: 'Local history could not be loaded.',
        ),
      );
    }
  }

  Future<void> _loadMore(
    LoadMoreHistory event,
    Emitter<HistoryState> emit,
  ) async {
    if (!state.hasMore || state.status != HistoryStatus.loaded) return;
    try {
      final more = await repository.getAllRecords(
        limit: pageSize,
        offset: state.records.length,
      );
      emit(
        state.copyWith(
          records: [...state.records, ...more],
          hasMore: more.length == pageSize,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(errorMessage: 'More local history could not be loaded.'),
      );
    }
  }

  Future<void> _delete(
    DeleteHistoryRecord event,
    Emitter<HistoryState> emit,
  ) async {
    await repository.deleteRecord(event.id);
    add(const RefreshHistory());
  }

  Future<void> _clear(ClearHistory event, Emitter<HistoryState> emit) async {
    emit(state.copyWith(status: HistoryStatus.clearing));
    try {
      await repository.clearAllRecords();
      emit(const HistoryState(status: HistoryStatus.empty, hasMore: false));
    } catch (_) {
      emit(
        state.copyWith(
          status: HistoryStatus.error,
          errorMessage: 'Local history could not be cleared.',
        ),
      );
    }
  }
}
