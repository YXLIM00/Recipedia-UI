import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:url_launcher/url_launcher.dart';

class AddRecipeDetailsPage extends StatefulWidget {
  final dynamic recipe;

  const AddRecipeDetailsPage({super.key, required this.recipe});

  @override
  State<AddRecipeDetailsPage> createState() => _AddRecipeDetailsPageState();
}

class _AddRecipeDetailsPageState extends State<AddRecipeDetailsPage> {
  Future<void> addRecipeToFirestore() async {
    final String label = widget.recipe['label'] ?? 'Unnamed Recipe';
    final String image = widget.recipe['image'] ?? '';
    final int servings = (widget.recipe['yield'] ?? 1).toDouble().toInt();
    final double? calories = widget.recipe['calories']?.toDouble();
    final dynamic totalNutrients = widget.recipe['totalNutrients'] ?? {};
    final dynamic totalDaily = widget.recipe['totalDaily'] ?? {};
    final List<dynamic> dietLabels = widget.recipe['dietLabels'];
    final List<dynamic> healthLabels = widget.recipe['healthLabels'] ?? [];
    final List<dynamic> cautions = widget.recipe['cautions'] ?? [];
    final List<dynamic> ingredientLines = widget.recipe['ingredientLines'] ?? [];
    final List<dynamic> detailedIngredients = widget.recipe['ingredients'] ?? [];
    final String source = widget.recipe['source'] ?? 'Unknown Source';
    final String url = widget.recipe['url'] ?? '';
    final int totalTime = widget.recipe['totalTime']?.toInt() ?? 0;

    // Convert double values in totalNutrients and totalDaily
    Map<String, dynamic> formattedTotalNutrients = {};
    Map<String, dynamic> formattedTotalDaily = {};

    if (totalNutrients is Map<String, dynamic>) {
      totalNutrients.forEach((key, value) {
        if (value is Map<String, dynamic> && value['quantity'] is double) {
          formattedTotalNutrients[key] = {
            ...value,
            'quantity': value['quantity'].toStringAsFixed(1), // Format to 1 decimal place
          };
        } else {
          formattedTotalNutrients[key] = value;
        }
      });
    }

    if (totalDaily is Map<String, dynamic>) {
      totalDaily.forEach((key, value) {
        if (value is Map<String, dynamic> && value['quantity'] is double) {
          formattedTotalDaily[key] = {
            ...value,
            'quantity': value['quantity'].toStringAsFixed(1), // Format to 1 decimal place
          };
        } else {
          formattedTotalDaily[key] = value;
        }
      });
    }


    try {
      await FirebaseFirestore.instance.collection('recipes').doc(label).set({
        'label': label,
        'image': image,
        'yield': servings,
        'calories': calories?.toStringAsFixed(1),
        'caloriesPerServing': servings > 0 && calories != null ? (calories / servings).toStringAsFixed(1): 'N/A',
        'totalNutrients': formattedTotalNutrients,
        'totalDaily': formattedTotalDaily,
        'dietLabels': dietLabels,
        'healthLabels': healthLabels,
        'cautions': cautions,
        'ingredientLines': ingredientLines,
        'ingredients': detailedIngredients,
        'source': source,
        'url': url,
        'totalTime': totalTime,

      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe added to Firestore successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String label = widget.recipe['label'] ?? 'No Title';
    final String image = widget.recipe['image'] ?? '';
    final int servings = (widget.recipe['yield'] ?? 1).toDouble().toInt();
    final double? calories = widget.recipe['calories']?.toDouble();
    final String caloriesPerServing = (servings > 0 && calories != null) ? '${(calories / servings).toStringAsFixed(0)} kcal per serving' : 'N/A';
    final String protein = widget.recipe['totalNutrients']?['PROCNT']?['quantity']?.toStringAsFixed(1) ?? 'N/A';
    final String fat = widget.recipe['totalNutrients']?['FAT']?['quantity']?.toStringAsFixed(1) ?? 'N/A';
    final String carbs = widget.recipe['totalNutrients']?['CHOCDF']?['quantity']?.toStringAsFixed(1) ?? 'N/A';
    final List<String> dietLabels = List<String>.from(widget.recipe['dietLabels'] ?? []);
    final List<String> cautions = List<String>.from(widget.recipe['cautions'] ?? []);
    final List<String> ingredientLines = List<String>.from(widget.recipe['ingredientLines'] ?? []);
    final String url = widget.recipe['url'] ?? '';

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
              if (mounted) { // Ensure the widget is still in the tree before navigating
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthStateChange()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: BackgroundContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: image.isNotEmpty
                    ? Image.network(image, height: 250, width: double.infinity, fit: BoxFit.cover)
                    : const Icon(Icons.broken_image, size: 100),
              ),
              const SizedBox(height: 30),

              // Nutrition Facts Section
              const SizedBox(height: 30),
              const Text('Nutrition Facts:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              _buildNutritionalCard('Servings', '$servings servings'),
              _buildNutritionalCard('Calories', '${calories?.toStringAsFixed(0) ?? 'N/A'} kcal'),
              _buildNutritionalCard('Calories per Serving', caloriesPerServing),
              _buildNutritionalCard('Protein', '$protein g'),
              _buildNutritionalCard('Fat', '$fat g'),
              _buildNutritionalCard('Carbohydrates', '$carbs g'),

              // Diet Labels Section
              const SizedBox(height: 30),
              _buildTagsSection('Diet Labels', dietLabels),

              // Cautions Section
              const SizedBox(height: 30),
              _buildTagsSection('Cautions', cautions),

              // Ingredients Section
              const SizedBox(height: 30),
              const Text('Ingredients:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ...ingredientLines.map((ingredient) => _buildIngredientCard(ingredient)),

              // Recipe URL Section
              const SizedBox(height: 30),
              const Text(
                'Cooking Instructions:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              _buildRecipeUrl(url),

              // Add to Firestore Button
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: addRecipeToFirestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Increase padding
                    minimumSize: const Size(150, 50), // Set minimum width and height
                  ),
                  child: Text(
                    'Add Recipe',
                    style: TextStyle(
                      fontSize: 20, // Increase text size
                      color: Colors.greenAccent[400],
                      fontWeight: FontWeight.bold, // Optional: make the text bold
                    ),
                  ),
                ),
              )

            ],
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
        _buildSectionTitle(title),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.grey[800])).toList(),
        ),
      ],
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      '$title:',
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }


  Widget _buildIngredientCard(String ingredient) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          ingredient,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }


  Widget _buildRecipeUrl(String url) {
    if (url.isEmpty) {
      return Card(
        color: Colors.grey[800],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'No URL available',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Make sure the URL is trimmed and properly parsed as a Uri
    final Uri uri = Uri.parse(url.trim());

    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GestureDetector(
          onTap: () async {
            try {
              if (uri.scheme != 'http' && uri.scheme != 'https') {
                throw 'Invalid URL scheme: $url';
              }

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                throw 'Could not launch $url';
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
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
