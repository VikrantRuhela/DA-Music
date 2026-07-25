import 'package:http/http.dart' as http;

void main() async {
  try {
    print('Sending search GET request...');
    final response = await http.get(Uri.parse('https://www.youtube.com/results?search_query=trending+Pop'));
    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');
  } catch (e) {
    print('Error: $e');
  }
}
