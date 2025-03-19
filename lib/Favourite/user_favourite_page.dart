import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Share_Services/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/Recommendation/user_recommended_recipe_details.dart';

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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthStateChange()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page Title
          SizedBox(height: 20),
          Center(
            child: Text(
              'Favourite Recipes',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
          
          // Favourite Recipes 
          SizedBox(height: 20),
          Expanded( // Use Expanded to ensure the GridView takes up available space.
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
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 16.0,
                    mainAxisExtent: 230, // Set fixed card height
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
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12.0),
                              ),
                              child: Image.network(
                                recipe['image'],
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                recipe['label'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
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
        ],
      ),

      bottomNavigationBar: const UserBottomNavBar(currentIndex: 2),
    );
  }

}
