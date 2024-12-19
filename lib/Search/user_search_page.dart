import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/Share_Services/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/Recommendation/user_recommended_recipe_details.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final user = FirebaseAuth.instance.currentUser!;

  // Define the search terms for categories
  final List<String> foodCategories = ['chicken', 'fish', 'beef', 'rice'];

  // Fetch and group recipes by food category
  Future<Map<String, List<Map<String, dynamic>>>> fetchGroupedRecipes() async {
    try {
      final recipesCollection = FirebaseFirestore.instance.collection('recipes');
      final snapshot = await recipesCollection.get();

      final groupedRecipes = <String, List<Map<String, dynamic>>>{};

      snapshot.docs.map((doc) => doc.data()).forEach((recipe) {
        final ingredients = List<Map<String, dynamic>>.from(recipe['ingredients'] ?? []);

        // Check if any ingredient food matches the categories (case insensitive)
        bool matchesCategory = false;
        String matchedCategory = 'Other';

        for (var ingredient in ingredients) {
          if (ingredient['food'] != null &&
              foodCategories.any((category) => ingredient['food'].toLowerCase().contains(category))) {
            matchesCategory = true;
            matchedCategory = foodCategories.firstWhere(
                  (category) => ingredient['food'].toLowerCase().contains(category),
              orElse: () => 'Other',
            );
            break;
          }
        }

        // If the recipe matches the category, group it
        if (matchesCategory) {
          if (!groupedRecipes.containsKey(matchedCategory)) {
            groupedRecipes[matchedCategory] = [];
          }
          groupedRecipes[matchedCategory]!.add(recipe);
        } else {
          // If the recipe doesn't match any category, group it under 'Others'
          if (!groupedRecipes.containsKey('Others')) {
            groupedRecipes['Others'] = [];
          }
          groupedRecipes['Others']!.add(recipe);
        }
      });

      return groupedRecipes;
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipedia', style: TextStyle(color: Colors.white)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Center(
            child: Text(
              'All Recipes',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),

          // All Recipes Sections Card
          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: fetchGroupedRecipes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No recommended recipes found."));
                }

                final groupedRecipes = snapshot.data!;

                // Extract "Other" section separately
                final others = groupedRecipes['Other'];

                // Sort the remaining categories alphabetically
                final sortedCategories = groupedRecipes.keys
                    .where((category) => category != 'Other')
                    .toList()
                  ..sort();

                // Append "Other" section to the end if it exists
                if (others != null) {
                  sortedCategories.add('Other');
                }

                return ListView.builder(
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final category = sortedCategories[index];
                    final recipes = groupedRecipes[category]!;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Title
                            Text(
                              category[0].toUpperCase() + category.substring(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Horizontal Scrollable Recipes
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
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
                                      width: 200,
                                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey,
                                            offset: const Offset(2, 2),
                                            blurRadius: 4,
                                            spreadRadius: 2,
                                          ),
                                          const BoxShadow(
                                            color: Colors.grey,
                                            offset: Offset(-2, -2),
                                            blurRadius: 4,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                            child: Image.network(
                                              recipe['image'] ?? 'https://via.placeholder.com/150',
                                              height: 140,
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
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
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 1),
    );
  }
}
