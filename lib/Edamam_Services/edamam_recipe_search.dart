import 'package:http/http.dart' as http;
import 'dart:convert';

class EdamamRecipeSearch {
  final String edamamAppId = 'ed37e8f6';
  final String edamamAppKey = '454e1049e30eb696918f8f9c984a8e6e';

  // Fetch recipes based on query and optional filters
  Future<List<dynamic>> edamamFetchRecipes(
      String query, {
        List<String> diets = const [],
        List<String> health = const [],
      }) async {
    final String baseUrl = 'https://api.edamam.com/api/recipes/v2';
    final String type = 'public';

    // Construct query parameters
    String dietQuery = diets.map((diet) => '&diet=$diet').join();
    String healthQuery = health.map((label) => '&health=$label').join();

    final String url =
        '$baseUrl?type=$type&q=$query&app_id=$edamamAppId&app_key=$edamamAppKey$dietQuery$healthQuery';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hits']
            .map((hit) => hit['recipe']) // Extract recipes from API response
            .toList();
      } else {
        throw Exception(
            'Failed to fetch recipes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recipes: $e');
    }
  }
}
