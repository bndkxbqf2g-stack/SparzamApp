class SequentialWriteQueue {
  Future<void> _pending = Future<void>.value();

  Future<void> get pending => _pending;

  Future<void> add(Future<void> Function() operation) {
    final next = _pending
        .catchError((Object _) {})
        .then((_) => operation());
    _pending = next;
    return next;
  }
}
