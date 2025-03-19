import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image.dart';

class RecipeImagePreloader {
  static Future<void> checkAndUpdateRecipeImages() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final QuerySnapshot recipesSnapshot = await firestore.collection('recipes').get();

    for (var recipeDoc in recipesSnapshot.docs) {
      final String recipeName = recipeDoc['label'] ?? 'Unnamed Recipe';
      final String currentImageUrl = recipeDoc['image'] ?? '';

      bool isImageBroken = false;

      try {
        final response = await http.get(Uri.parse(currentImageUrl));
        if (response.statusCode != 200) {
          isImageBroken = true;
        }
      } catch (e) {
        isImageBroken = true;
      }

      if (isImageBroken) {
        final String? newImageUrl = await RecipeImageService.fetchNewImageUrlFromEdamam(recipeName);
        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          await firestore.collection('recipes').doc(recipeDoc.id).update({'image': newImageUrl});
        }
      }
    }
  }
}
