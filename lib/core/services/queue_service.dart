import '../../domain/entities/song.dart';
import '../../domain/entities/queue.dart';

abstract class QueueService {
  Stream<Queue> get queueStream;
  Future<void> insertNext(Song song);
  Future<void> move(int oldIndex, int newIndex);
  Future<void> remove(int index);
  Future<void> clear();
}
