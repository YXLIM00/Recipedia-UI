import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeImageService {
  static Future<String?> fetchNewImageUrlFromEdamam(String recipeName) async {
    try {
      final String appId = 'ed37e8f6';
      final String appKey = '454e1049e30eb696918f8f9c984a8e6e';

      // Construct the API call with the recipe name
      final response = await http.get(
        Uri.parse(
          'https://api.edamam.com/search?q=$recipeName&app_id=$appId&app_key=$appKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if any recipes are returned
        if (data['hits'] != null && data['hits'].isNotEmpty) {
          // Search for the best match in the returned recipes
          for (var hit in data['hits']) {
            final recipe = hit['recipe'];
            final String label = recipe['label']?.toString() ?? '';

            // Check if the label matches the original recipe name
            if (label.toLowerCase().contains(recipeName.toLowerCase())) {
              final String newImageUrl = recipe['image'] ?? '';
              if (newImageUrl.isNotEmpty) {
                return newImageUrl;
              }
            }
          }
          // If no exact match is found, return the image of the first hit
          return data['hits'][0]['recipe']['image'];
        } else {
          print('No recipes found for $recipeName');
        }
      } else {
        print('Failed to fetch data from Edamam API. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching new image: $e');
    }

    // Return null if no image is found
    return null;
  }
}
