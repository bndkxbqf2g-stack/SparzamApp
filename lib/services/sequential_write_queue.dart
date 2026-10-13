import 'sequential_operation_queue.dart';

class SequentialWriteQueue extends SequentialOperationQueue {
  Future<void> add(Future<void> Function() operation) => schedule(operation);
}
