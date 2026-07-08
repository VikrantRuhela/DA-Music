import '../../domain/entities/search_result.dart';

abstract class SearchService {
  Future<SearchResult> search(String query);
}
