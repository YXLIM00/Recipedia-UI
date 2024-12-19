import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../User_Registration/auth_state_change.dart';
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

  final Map<String, bool> sectionExpanded = {
    "Calories": false,
    "Nutrients": false,
    "Diet Labels": false,
    "Health Labels": false,
    "Ingredients": false,
    "Cooking Instructions": false,
  };

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
        savedRecipes.remove(widget.recipe['label']);
      } else {
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
        title: const Text(
          'Recipedia',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              child: Image.network(
                recipe['image'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Recipe Name with Favorite Icon
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        recipe['label'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        softWrap: true,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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

            SizedBox(height: 20),
            // Expandable Sections
            _buildExpandableSection(
              title: "Calories",
              content: _buildCaloriesContent(recipe),
            ),
            SizedBox(height: 20),
            _buildExpandableSection(
              title: "Nutrients",
              content: _buildNutrientsContent(recipe),
            ),
            SizedBox(height: 20),
            _buildExpandableSection(
              title: "Diet Labels",
              content: _buildWrapChips(recipe['dietLabels']),
            ),
            SizedBox(height: 20),
            _buildExpandableSection(
              title: "Health Labels",
              content: _buildWrapChips(recipe['healthLabels']),
            ),
            SizedBox(height: 20),
            _buildExpandableSection(
              title: "Ingredients",
              content: _buildIngredientsContent(recipe),
            ),
            SizedBox(height: 20),
            _buildExpandableSection(
              title: "Cooking Instructions",
              content: _buildCookingInstructions(recipe),
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({required String title, required Widget content}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              sectionExpanded[title]! ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            onTap: () {
              setState(() {
                sectionExpanded[title] = !sectionExpanded[title]!;
              });
            },
          ),
          if (sectionExpanded[title]!)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildCaloriesContent(Map<String, dynamic> recipe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildKeyValueColumn("Total Calories", recipe['calories']),
        _buildKeyValueColumn("Calories Per Serving", recipe['caloriesPerServing']),
      ],
    );
  }

  Widget _buildNutrientsContent(Map<String, dynamic> recipe) {
    return Row(
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
    );
  }

  Widget _buildIngredientsContent(Map<String, dynamic> recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(
        recipe['ingredientLines'].length,
            (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text("- ${recipe['ingredientLines'][index]}"),
        ),
      ),
    );
  }

  Widget _buildCookingInstructions(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () async {
        final String url = recipe['url'];
        if (url.isNotEmpty) {
          final Uri uri = Uri.parse(url.trim());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Text(
        recipe['url'],
        style: const TextStyle(color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildWrapChips(List<dynamic> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Chip(
              label: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildKeyValueColumn(String key, dynamic value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value.toString()),
        ],
      ),
    );
  }
}
