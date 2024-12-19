import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:url_launcher/url_launcher.dart';

class AddRecipeDetailsPage extends StatefulWidget {
  final dynamic recipe;

  const AddRecipeDetailsPage({super.key, required this.recipe});

  @override
  State<AddRecipeDetailsPage> createState() => _AddRecipeDetailsPageState();
}

class _AddRecipeDetailsPageState extends State<AddRecipeDetailsPage> {
  bool isNutritionExpanded = false;
  bool isDietLabelsExpanded = false;
  bool isCautionsExpanded = false;
  bool isIngredientsExpanded = false;
  bool isRecipeUrlExpanded = false;

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
            'quantity': double.parse(value['quantity'].toStringAsFixed(1)), // Format to 1 decimal place first then convert back to double
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
            'quantity': double.parse(value['quantity'].toStringAsFixed(1)), // Format to 1 decimal place first then convert back to double
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
        'calories': double.parse(calories!.toStringAsFixed(1)),
        'caloriesPerServing': servings > 0 ? double.parse((calories / servings).toStringAsFixed(1)) : 'N/A',
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

      _showDialog(context, 'Success', 'Recipe added successfully');
    } catch (e) {
      _showDialog(context, 'Error', 'Failed to add recipe: $e');
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
          content: Text(message, style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold),),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String label = widget.recipe['label'] ?? 'No Title';
    final String image = widget.recipe['image'] ?? '';
    final int servings = (widget.recipe['yield'] ?? 1).toDouble().toInt();
    final double? calories = widget.recipe['calories']?.toDouble();
    final String caloriesPerServing = (servings > 0 && calories != null) ? '${double.parse((calories / servings).toStringAsFixed(1))} kcal per serving' : 'N/A';
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
          'Add Recipes',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: image.isNotEmpty
                  ? Image.network(image, height: 250, width: double.infinity, fit: BoxFit.cover)
                  : const Icon(Icons.broken_image, size: 100),
            ),
            const SizedBox(height: 40),

            // Nutrition Facts Section
            _buildExpandableSection('Nutrition Facts', isNutritionExpanded, () {
              setState(() {
                isNutritionExpanded = !isNutritionExpanded;
              });
            }, Column(
              children: [
                _buildNutritionalCard('Servings', '$servings servings'),
                _buildNutritionalCard('Calories', '${calories?.toStringAsFixed(0) ?? 'N/A'} kcal'),
                _buildNutritionalCard('Calories per Serving', caloriesPerServing),
                _buildNutritionalCard('Protein', '$protein g'),
                _buildNutritionalCard('Fat', '$fat g'),
                _buildNutritionalCard('Carbohydrates', '$carbs g'),
              ],
            )),

            // Diet Labels Section
            _buildExpandableSection('Diet Labels', isDietLabelsExpanded, () {
              setState(() {
                isDietLabelsExpanded = !isDietLabelsExpanded;
              });
            }, _buildTagsSection(dietLabels)),

            // Cautions Section
            _buildExpandableSection('Cautions', isCautionsExpanded, () {
              setState(() {
                isCautionsExpanded = !isCautionsExpanded;
              });
            }, _buildTagsSection(cautions)),

            // Ingredients Section
            _buildExpandableSection('Ingredients', isIngredientsExpanded, () {
              setState(() {
                isIngredientsExpanded = !isIngredientsExpanded;
              });
            }, Column(
              children: ingredientLines.map((ingredient) => _buildIngredientCard(ingredient)).toList(),
            )),

            // Recipe URL Section
            _buildExpandableSection('Cooking Instructions', isRecipeUrlExpanded, () {
              setState(() {
                isRecipeUrlExpanded = !isRecipeUrlExpanded;
              });
            }, _buildRecipeUrl(url)),

            // Add to Firestore Button
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: addRecipeToFirestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                  minimumSize: const Size(150, 50),
                ),
                child: const Text('Add Recipe', style: TextStyle(color: Colors.indigo, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title, bool isExpanded, VoidCallback onPressed, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.black,
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontSize: 20, color: Colors.white)),
            trailing: IconButton(
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.indigo,
              ),
              onPressed: onPressed,
            ),
          ),
          if (isExpanded) content,
        ],
      ),
    );
  }

  Widget _buildNutritionalCard(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Text(value, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Wrap(
      spacing: 8.0,
      children: tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(color: Colors.black)))).toList(),
    );
  }

  Widget _buildIngredientCard(String ingredient) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: ListTile(
        title: Text(ingredient, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildRecipeUrl(String url) {
    return url.isNotEmpty
        ? GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(url as Uri)) {
          await launchUrl(url as Uri);
        }
      },
      child: Card(
        color: Colors.black,
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        child: ListTile(
          title: Text('Click to view full recipe', style: const TextStyle(color: Colors.white)),
        ),
      ),
    )
        : const SizedBox();
  }
}
