import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_recommended_recipe_details.dart';
import 'package:fyp_recipe/auth_state_change.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  bool showRecommended = true; // Default to showing recommended recipes

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      showRecommended = true; // Reset to recommended recipes every time the page is entered
    });
  }

  Future<List<Map<String, dynamic>>> fetchRecipes({bool recommended = false}) async {
    try {
      final recipesCollection = FirebaseFirestore.instance.collection('recipes');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      // If filtering for recommended recipes and user data exists
      if (recommended && userDoc.exists) {
        final customDietLabels = List<String>.from(userDoc.data()?['custom_dietLabels'] ?? []);
        final customHealthLabels = List<String>.from(userDoc.data()?['custom_healthLabels'] ?? []);

        // Fetch all recipes
        final snapshot = await recipesCollection.get();

        // Filter recipes locally to match all custom labels
        return snapshot.docs.map((doc) => doc.data()).where((recipe) {
          final dietLabels = List<String>.from(recipe['dietLabels'] ?? []);
          final healthLabels = List<String>.from(recipe['healthLabels'] ?? []);

          // Ensure all custom diet and health labels are matched
          final matchesDietLabels = customDietLabels.every(dietLabels.contains);
          final matchesHealthLabels = customHealthLabels.every(healthLabels.contains);

          return matchesDietLabels && matchesHealthLabels;
        }).toList();
      } else {
        // Fetch all recipes if not filtering by recommended
        final snapshot = await recipesCollection.get();
        return snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between Recommended and All Recipes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => showRecommended = true),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Recommended Recipes",
                      style: TextStyle(
                        color: showRecommended ? Colors.greenAccent : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => showRecommended = false),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "All Recipes",
                      style: TextStyle(
                        color: !showRecommended ? Colors.greenAccent : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchRecipes(recommended: showRecommended),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No recipes found."));
                  }
                  final recipes = snapshot.data!;
                  return ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 3,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(
                                  recipe['image'] ?? 'https://via.placeholder.com/150', // Placeholder image
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 150);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  recipe['label'] ?? 'Unknown Recipe',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RecommendedRecipeDetails(recipe: recipe),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent[400],
                                  ),
                                  child: const Text("See Recipe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
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
      ),
    );
  }
}
