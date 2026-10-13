/// Serializes local asynchronous reads and writes while keeping the queue
/// usable after one operation fails.
///
/// The returned future still exposes the operation's own error to its caller;
/// only the internal successor chain is error-isolated so later operations
/// can continue.
class SequentialOperationQueue {
  Future<void> _pending = Future<void>.value();

  Future<void> get pending => _pending;

  Future<T> schedule<T>(Future<T> Function() operation) {
    final next = _pending.catchError((Object _) {}).then((_) => operation());
    _pending = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
