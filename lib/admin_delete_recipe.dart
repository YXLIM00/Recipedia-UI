import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/edamam_recipe_image.dart';
import 'package:http/http.dart' as http;

class AdminDeleteRecipe extends StatefulWidget {
  const AdminDeleteRecipe({super.key});

  @override
  AdminDeleteRecipeState createState() => AdminDeleteRecipeState();
}

class AdminDeleteRecipeState extends State<AdminDeleteRecipe> {
  final admin = FirebaseAuth.instance.currentUser!;
  List<dynamic> recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipesFromFirestore();
  }

  // Fetch recipes from Firestore
  Future<void> fetchRecipesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('label') // Assuming there's a 'label' field for sorting
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


  // Function to delete a recipe
  Future<void> deleteRecipe(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('recipes').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe deleted successfully')),
      );
      fetchRecipesFromFirestore(); // Refresh the list after deletion
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recipe: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delete Recipes',
          style: TextStyle(color: Colors.greenAccent[400]),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent[400]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.greenAccent[400],
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
      body: BackgroundContainer(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : recipes.isEmpty
            ? const Center(
          child: Text(
            'No recipes found',
            style: TextStyle(color: Colors.white),
          ),
        )
            : GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            return RecipeCard(
              recipe: recipes[index],
              onDelete: () => deleteRecipe(recipes[index].id),
            );
          },
        ),
      ),
    );
  }
}


class RecipeCard extends StatelessWidget {
  final QueryDocumentSnapshot recipe;
  final VoidCallback onDelete;

  const RecipeCard({super.key, required this.recipe, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Extracting Firestore recipe fields
    final String label = recipe['label'] ?? 'Unknown Recipe';
    final String imageUrl = recipe['image'] ?? '';

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 2,
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
                    // Call updateRecipeImage() if the image is broken
                    final adminDeleteRecipeState = context.findAncestorStateOfType<AdminDeleteRecipeState>();
                    adminDeleteRecipeState?.updateRecipeImage(recipe);
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
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onDelete,
                child: const Text(
                  'Delete Recipe',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


