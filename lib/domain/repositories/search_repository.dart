import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<SearchResult> search(String query);
}
