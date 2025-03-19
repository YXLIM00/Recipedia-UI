import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
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


  // Function to delete a recipe with a confirmation dialog and success message in an AlertDialog
  Future<void> deleteRecipe(String docId) async {
    // Show a confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
          content: const Text('Are you sure you want to delete this recipe?', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss dialog with "Cancel"
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold),),
            ),
          ],
        );
      },
    );

    // If the user confirmed, delete the recipe
    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('recipes').doc(docId).delete();

        // Show success message in an AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
              content: const Text('Recipe deleted successfully', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                    fetchRecipesFromFirestore(); // Refresh the list after deletion
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // If deletion fails, show an error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
              content: Text('Failed to delete recipe: ${e.toString()}', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delete Recipes',
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
          ? const Center(
        child: Text(
          'No recipes found',
          style: TextStyle(color: Colors.black),
        ),
      )
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
            onDelete: () => deleteRecipe(recipes[index].id),
          );
        },
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
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onDelete,
                child: const Text(
                  'Delete Recipe',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


