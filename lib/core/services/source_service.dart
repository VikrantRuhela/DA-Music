import '../../domain/entities/value_objects.dart';

abstract class SourceService {
  Future<void> selectSource(Source source);
  Future<List<Source>> getAvailableSources();
}
