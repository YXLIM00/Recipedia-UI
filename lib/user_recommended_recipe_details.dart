import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'auth_state_change.dart';
import 'package:url_launcher/url_launcher.dart';


class RecommendedRecipeDetails extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecommendedRecipeDetails({super.key, required this.recipe});

  @override
  State<RecommendedRecipeDetails> createState() =>
      _RecommendedRecipeDetailsState();
}

class _RecommendedRecipeDetailsState extends State<RecommendedRecipeDetails> {
  final user = FirebaseAuth.instance.currentUser!;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final savedRecipes = List<String>.from(userDoc.data()?['saved_recipes'] ?? []);
      setState(() {
        isFavorite = savedRecipes.contains(widget.recipe['label']);
      });
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();
      final savedRecipes = List<String>.from(userSnapshot.data()?['saved_recipes'] ?? []);

      if (isFavorite) {
        // Remove from favorites
        savedRecipes.remove(widget.recipe['label']);
      } else {
        // Add to favorites
        if (!savedRecipes.contains(widget.recipe['label'])) {
          savedRecipes.add(widget.recipe['label']);
        }
      }

      await userDoc.update({'saved_recipes': savedRecipes});

      setState(() {
        isFavorite = !isFavorite;
      });

      final message = isFavorite ? 'Recipe added to favorites!' : 'Recipe removed from favorites!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('Error toggling favorite status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

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
                  MaterialPageRoute(
                      builder: (context) => const AuthStateChange()),
                );
              }
            },
          ),
        ],
      ),
      body: BackgroundContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  recipe['image'],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Recipe Name
              // Recipe Name with Favorite Icon
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe['label'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white, // Base color for neumorphism
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white, // Highlight color
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2), // Shadow color
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 20),

              // Calories Section
              _buildSectionTitle("Calories"),
              _buildContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKeyValueColumn("Total Calories", recipe['calories']),
                        _buildKeyValueColumn(
                            "Calories Per Serving", recipe['caloriesPerServing']),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nutrients Section
              _buildSectionTitle("Nutrients"),
              _buildContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKeyValueColumn(
                          "Carbs",
                          "${recipe['totalNutrients']['CHOCDF']['quantity']} ${recipe['totalNutrients']['CHOCDF']['unit']}",
                        ),
                        _buildKeyValueColumn(
                          "Protein",
                          "${recipe['totalNutrients']['PROCNT']['quantity']} ${recipe['totalNutrients']['PROCNT']['unit']}",
                        ),
                        _buildKeyValueColumn(
                          "Fat",
                          "${recipe['totalNutrients']['FAT']['quantity']} ${recipe['totalNutrients']['FAT']['unit']}",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Diet Labels Section
              _buildSectionTitle("Diet Labels"),
              _buildWrapChips(recipe['dietLabels']),
              const SizedBox(height: 20),

              // Health Labels Section
              _buildSectionTitle("Health Labels"),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: recipe['healthLabels'].map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          item,
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Ingredients Section
              _buildSectionTitle("Ingredients"),
              _buildContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List<Widget>.generate(
                        recipe['ingredientLines'].length,
                            (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            "- ${recipe['ingredientLines'][index]}",
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Cooking Instructions Section
              _buildSectionTitle("Cooking Instructions"),
              _buildContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final String url = recipe['url'];
                        if (url.isNotEmpty) {
                          final Uri uri = Uri.parse(url.trim());
                          try {
                            if (uri.scheme == 'http' || uri.scheme == 'https') {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not launch $url')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Invalid URL scheme: $url')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No URL available')),
                          );
                        }
                      },
                      child: Text(
                        recipe['url'],
                        style: TextStyle(
                          color: Colors.blueAccent[700],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.greenAccent[400],
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }

  Widget _buildKeyValueColumn(String key, dynamic value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: TextStyle(
                color: Colors.green[700], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            value.toString(),
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWrapChips(List<dynamic> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(
            item,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
