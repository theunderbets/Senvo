class LocalDatabaseException implements Exception {
  const LocalDatabaseException(this.message);
  final String message;
  @override
  String toString() => message;
}
