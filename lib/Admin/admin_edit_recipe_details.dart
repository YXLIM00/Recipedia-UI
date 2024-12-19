import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:url_launcher/url_launcher.dart';

class EditRecipeDetailsPage extends StatefulWidget {
  final String recipeId;

  const EditRecipeDetailsPage({super.key, required this.recipeId});

  @override
  State<EditRecipeDetailsPage> createState() => _EditRecipeDetailsPageState();
}

class _EditRecipeDetailsPageState extends State<EditRecipeDetailsPage> {
  final TextEditingController ingredientsController = TextEditingController();

  Map<String, dynamic>? recipeData;
  bool isLoading = true;
  bool isNutritionalExpanded = false;
  bool isDietLabelsExpanded = false;
  bool isCautionsExpanded = false;
  bool isIngredientsExpanded = false;
  bool isInstructionsExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchRecipeFromFirestore();
  }

  @override
  void dispose() {
    ingredientsController.dispose();
    super.dispose();
  }

  Future<void> fetchRecipeFromFirestore() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (snapshot.exists) {
        setState(() {
          recipeData = snapshot.data() as Map<String, dynamic>?;

          ingredientsController.text =
              (recipeData?['ingredientLines'] as List<dynamic>?)?.join('\n') ?? '';

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipe: $e')),
      );
    }
  }

  Future<void> updateRecipeInFirestore() async {
    final List<String> updatedIngredients = ingredientsController.text
        .trim()
        .split('\n')
        .map((ingredient) => ingredient.trim())
        .toList();

    try {
      await FirebaseFirestore.instance.collection('recipes').doc(widget.recipeId).update({
        'ingredientLines': updatedIngredients,
      });

      // Display success message without navigating away
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingredients updated successfully'),
          backgroundColor: Colors.indigo,
          duration: Duration(seconds: 2), // Optional: Auto-dismiss the SnackBar after 2 seconds
        ),
      );

      // Optionally, re-fetch the recipe to reflect updates immediately
      await fetchRecipeFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ingredients: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String recipeName = recipeData?['label'] ?? 'No Title';
    final String imageUrl = recipeData?['image'] ?? '';
    final int servings = (recipeData?['servings'] ?? 1).toDouble().toInt();
    final double? calories = recipeData?['calories']?.toDouble();
    final String caloriesPerServing = (servings > 0 && calories != null)
        ? '${(calories / servings).toStringAsFixed(0)} kcal'
        : 'N/A';
    final List<String> dietLabels = List<String>.from(recipeData?['dietLabels'] ?? []);
    final List<String> cautions = List<String>.from(recipeData?['cautions'] ?? []);
    final String recipeUrl = recipeData?['url'] ?? '';

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
      body: GestureDetector(
        onTap: () {
          // Unfocus the text field and hide the keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Name
              Text(
                recipeName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover)
                    : const Icon(Icons.broken_image, size: 100),
              ),
              const SizedBox(height: 30),

              // Nutritional Facts Section
              _buildExpandableCard(
                title: 'Nutrition Facts',
                isExpanded: isNutritionalExpanded,
                onTap: () {
                  setState(() {
                    isNutritionalExpanded = !isNutritionalExpanded;
                  });
                },
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNutritionalCard('Servings', '$servings servings'),
                    _buildNutritionalCard('Calories', '${calories?.toStringAsFixed(0) ?? 'N/A'} kcal'),
                    _buildNutritionalCard('Calories per Serving', caloriesPerServing),
                  ],
                ),
              ),

              // Diet Labels Section
              _buildExpandableCard(
                title: 'Diet Labels',
                isExpanded: isDietLabelsExpanded,
                onTap: () {
                  setState(() {
                    isDietLabelsExpanded = !isDietLabelsExpanded;
                  });
                },
                content: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: dietLabels.map((label) {
                    return Chip(
                      label: Text(label, style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
                      backgroundColor: Colors.white,
                    );
                  }).toList(),
                ),
              ),

              // Cautions Section
              _buildExpandableCard(
                title: 'Cautions',
                isExpanded: isCautionsExpanded,
                onTap: () {
                  setState(() {
                    isCautionsExpanded = !isCautionsExpanded;
                  });
                },
                content: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: cautions.map((caution) {
                    return Chip(
                      label: Text(caution),
                      backgroundColor: Colors.red,
                    );
                  }).toList(),
                ),
              ),

              // Ingredients Section
              _buildExpandableCard(
                title: 'Edit Ingredients',
                isExpanded: isIngredientsExpanded,
                onTap: () {
                  setState(() {
                    isIngredientsExpanded = !isIngredientsExpanded;
                  });
                },
                content: Column(
                  children: [
                    TextField(
                      controller: ingredientsController,
                      decoration: const InputDecoration(
                        labelText: 'Ingredients (one per line)',
                        labelStyle: TextStyle(color: Colors.indigo, fontSize: 20), // Label color
                        hintText: 'Enter each ingredient on a new line',
                        hintStyle: TextStyle(color: Colors.grey), // Hint color for better visibility
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.indigo,
                            width: 4, // Increase the width to make it bold
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white), // Text color inside TextField
                      maxLines: 10,
                    ),
                  ],
                ),
              ),

              // Cooking Instructions Section
              _buildExpandableCard(
                title: 'Cooking Instructions',
                isExpanded: isInstructionsExpanded,
                onTap: () {
                  setState(() {
                    isInstructionsExpanded = !isInstructionsExpanded;
                  });
                },
                content: ElevatedButton(
                  onPressed: () {
                    if (recipeUrl.isNotEmpty) {
                      _launchUrl(recipeUrl);
                    }
                  },
                  child: const Text('View Recipe Online'),
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: updateRecipeInFirestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                  ),
                  child: Text(
                    'Edit Recipe',
                    style: TextStyle(fontSize: 20, color: Colors.indigo),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.indigo,
            ),
            onTap: onTap,
          ),
          if (isExpanded) Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
