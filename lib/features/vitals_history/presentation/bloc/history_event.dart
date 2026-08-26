sealed class HistoryEvent {
  const HistoryEvent();
}

class LoadHistory extends HistoryEvent {
  const LoadHistory();
}

class LoadMoreHistory extends HistoryEvent {
  const LoadMoreHistory();
}

class DeleteHistoryRecord extends HistoryEvent {
  const DeleteHistoryRecord(this.id);
  final String id;
}

class ClearHistory extends HistoryEvent {
  const ClearHistory();
}

class RefreshHistory extends HistoryEvent {
  const RefreshHistory();
}
