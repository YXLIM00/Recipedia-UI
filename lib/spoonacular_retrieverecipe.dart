import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularRecipeSearch {
  final String spoonacularApiKey = '894adf19ac144608b0e11b0cb9a5e3f9';

  Future<List<dynamic>> spoonacularFetchRecipes(String query) async {
    final response = await http.get(
      Uri.parse(
          'https://api.spoonacular.com/recipes/complexSearch?query=$query&addRecipeInformation=true&apiKey=$spoonacularApiKey'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['results']; // Spoonacular API stores recipes in 'results'
    } else {
      throw Exception('Failed to load recipes: ${response.reasonPhrase}');
    }
  }
}
