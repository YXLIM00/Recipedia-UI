import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/background_image_container.dart';
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
          backgroundColor: Colors.green,
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
        ? '${(calories / servings).toStringAsFixed(0)} kcal per serving'
        : 'N/A';
    final List<String> dietLabels = List<String>.from(recipeData?['dietLabels'] ?? []);
    final List<String> cautions = List<String>.from(recipeData?['cautions'] ?? []);
    final String recipeUrl = recipeData?['url'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Recipe',
          style: TextStyle(color: Colors.greenAccent[400]),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent[400]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthStateChange()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: BackgroundContainer(
        child: GestureDetector(
          onTap: () {
            // Unfocus the text field and hide the keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Name
                Text(
                  recipeName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
                // Display Nutrition Facts using _buildNutritionalCard
                const Text('Nutrition Facts:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                _buildNutritionalCard('Servings', '$servings servings'),
                _buildNutritionalCard('Calories', '${calories?.toStringAsFixed(0) ?? 'N/A'} kcal'),
                _buildNutritionalCard('Calories per Serving', caloriesPerServing),

                // Diet Labels
                const SizedBox(height: 30),
                _buildTagsSection('Diet Labels', dietLabels),

                // Cautions
                const SizedBox(height: 30),
                _buildTagsSection('Cautions', cautions),

                // Cooking Instructions
                const SizedBox(height: 30),
                const Text(
                  'Cooking Instructions:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                _buildRecipeUrl(recipeUrl),

                // Editable Ingredients
                const SizedBox(height: 30),
                const Text(
                  'Edit Ingredients:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients (one per line)',
                    labelStyle: TextStyle(color: Colors.greenAccent, fontSize: 20), // Label color
                    hintText: 'Enter each ingredient on a new line',
                    hintStyle: TextStyle(color: Colors.grey), // Hint color for better visibility
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.greenAccent,
                        width: 4, // Increase the width to make it bold
                      ),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white), // Text color inside TextField
                  maxLines: 10,
                ),


                const SizedBox(height: 30),
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
                      style: TextStyle(fontSize: 20, color: Colors.greenAccent[400]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionalCard(String title, String value) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(String title, List<String> tags) {
    if (tags.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.grey[800])).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecipeUrl(String url) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GestureDetector(
          onTap: () async {
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            }
          },
          child: Text(
            url,
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
