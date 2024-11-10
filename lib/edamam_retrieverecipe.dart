import 'dart:convert';
import 'package:http/http.dart' as http;

class EdamamRecipeSearch {
  final String edamamAppId = 'ed37e8f6';
  final String edamamAppKey = '454e1049e30eb696918f8f9c984a8e6e	';

  Future<List<dynamic>> edamamFetchRecipes(String query) async {
    final response = await http.get(
      Uri.parse(
          'https://api.edamam.com/api/recipes/v2?type=public&q=$query&app_id=$edamamAppId&app_key=$edamamAppKey'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('hits')) {
        // Filter recipes that contain both ingredients and instructions
        List<dynamic> filteredRecipes = data['hits']
            .map((hit) => hit['recipe'])
            .where((recipe) =>
        recipe.containsKey('ingredientLines') &&
            recipe['ingredientLines'] != null &&
            recipe['ingredientLines'].isNotEmpty &&
            recipe.containsKey('url') && // Recipe instructions URL
            recipe['url'] != null)
            .toList();

        return filteredRecipes;
      } else {
        throw Exception('No recipes found');
      }
    } else {
      throw Exception('Failed to load recipes: ${response.reasonPhrase}');
    }
  }
}