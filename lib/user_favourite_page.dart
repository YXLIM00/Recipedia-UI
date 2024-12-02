import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/user_recommended_recipe_details.dart';

class UserFavouritePage extends StatefulWidget {
  const UserFavouritePage({super.key});

  @override
  State<UserFavouritePage> createState() => _UserFavouritePageState();
}

class _UserFavouritePageState extends State<UserFavouritePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchSavedRecipes() async {
    try {
      // Get the current user.
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated.");

      // Retrieve the 'saved_recipes' from the user's document.
      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      final savedRecipes = List<String>.from(userDoc['saved_recipes'] ?? []);

      if (savedRecipes.isEmpty) return [];

      // Fetch recipes from the 'recipes' collection that match the saved recipe names.
      final recipesQuery = await _firestore
          .collection('recipes')
          .where('label', whereIn: savedRecipes)
          .get();

      return recipesQuery.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error fetching saved recipes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recipedia',
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthStateChange()),
                );
              }
            },
          ),
        ],
      ),
      body: BackgroundContainer(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchSavedRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading favourites.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No favourite recipes found.'));
            }
        
            final recipes = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display 2 items per row.
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 3 / 4, // Adjust the aspect ratio as needed.
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecommendedRecipeDetails(recipe: recipe),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12.0),
                            ),
                            child: Image.network(
                              recipe['image'], // URL of the recipe image.
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            recipe['label'], // Recipe name.
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 3),
    );
  }
}
