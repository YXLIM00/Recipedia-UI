import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/user_recommended_recipe_details.dart';
import 'package:fyp_recipe/auth_state_change.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final user = FirebaseAuth.instance.currentUser!;
  bool showRecommended = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      showRecommended = true;
    });
  }

  Future<List<Map<String, dynamic>>> fetchRecipes({bool recommended = false}) async {
    try {
      final recipesCollection = FirebaseFirestore.instance.collection('recipes');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (recommended && userDoc.exists) {
        final customDietLabels = List<String>.from(userDoc.data()?['custom_dietLabels'] ?? []);
        final customHealthLabels = List<String>.from(userDoc.data()?['custom_healthLabels'] ?? []);

        final snapshot = await recipesCollection.get();

        return snapshot.docs.map((doc) => doc.data()).where((recipe) {
          final dietLabels = List<String>.from(recipe['dietLabels'] ?? []);
          final healthLabels = List<String>.from(recipe['healthLabels'] ?? []);

          final matchesDietLabels = customDietLabels.every(dietLabels.contains);
          final matchesHealthLabels = customHealthLabels.every(healthLabels.contains);

          return matchesDietLabels && matchesHealthLabels;
        }).toList();
      } else {
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
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RecommendedRecipeDetails(recipe: recipe),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white70,
                                  offset: const Offset(4, 4),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(
                                  color: Colors.white70,
                                  offset: Offset(-4, -4),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image.network(
                                    recipe['image'] ?? 'https://via.placeholder.com/150',
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
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
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 1),
    );
  }
}
