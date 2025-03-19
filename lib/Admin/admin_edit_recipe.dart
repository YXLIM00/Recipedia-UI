import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Admin/admin_edit_recipe_details.dart';
import 'package:http/http.dart' as http;

class AdminEditRecipe extends StatefulWidget {
  const AdminEditRecipe({super.key});

  @override
  AdminEditRecipeState createState() => AdminEditRecipeState();
}

class AdminEditRecipeState extends State<AdminEditRecipe> {
  final admin = FirebaseAuth.instance.currentUser!;
  List<QueryDocumentSnapshot> recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipesFromFirestore();
  }

  // Fetch recipes from Firestore
  Future<void> fetchRecipesFromFirestore() async {
    setState(() => isLoading = true);
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('label') // Fetch recipes in alphabetical order
          .get();

      setState(() {
        recipes = querySnapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipes: ${e.toString()}')),
        );
      }
    }
  }

  // Retrieve recipe image from Edamam if current image is broken
  Future<void> updateRecipeImage(QueryDocumentSnapshot recipeDoc) async {
    final String recipeName = recipeDoc['label'] ?? 'Unnamed Recipe';
    final String currentImageUrl = recipeDoc['image'] ?? '';

    // Check if the current image URL is valid
    bool isImageBroken = false;

    try {
      final response = await http.get(Uri.parse(currentImageUrl));
      if (response.statusCode != 200) {
        isImageBroken = true;
      }
    } catch (e) {
      isImageBroken = true;
    }

    // If the image is broken, fetch a new one from Edamam
    if (isImageBroken) {
      final String? newImageUrl = await RecipeImageService.fetchNewImageUrlFromEdamam(recipeName);
      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        // Update Firestore with the new image URL
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(recipeDoc.id)
            .update({'image': newImageUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated broken image from Edamam API')),
        );

        // Refresh the recipes list
        fetchRecipesFromFirestore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Recipes',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthStateChange()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
          ? const Center(child: Text('No recipes found', style: TextStyle(color: Colors.white)))
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(
            recipe: recipes[index],
            updateImage: () => updateRecipeImage(recipes[index]),
          );
        },
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final QueryDocumentSnapshot recipe;
  final VoidCallback updateImage;

  const RecipeCard({super.key, required this.recipe, required this.updateImage});

  @override
  Widget build(BuildContext context) {
    final String label = recipe['label'] ?? 'Unknown Recipe';
    final String imageUrl = recipe['image'] ?? '';

    return Card(
      color: Colors.black,
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Trigger updateRecipeImage if the image is broken
                    updateImage();
                    return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                  },
                )
                    : const Icon(Icons.broken_image, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRecipeDetailsPage(recipeId: recipe.id), // Correct usage
                    ),
                  );
                },

                child: Text('Edit Recipe', style: TextStyle(color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
