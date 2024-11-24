import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/edamam_recipe_search.dart';
import 'package:fyp_recipe/admin_add_recipe_details.dart';

class AdminAddRecipe extends StatefulWidget {
  const AdminAddRecipe({super.key});

  @override
  AdminAddRecipeState createState() => AdminAddRecipeState();
}

class AdminAddRecipeState extends State<AdminAddRecipe> {
  final admin = FirebaseAuth.instance.currentUser!;
  List<dynamic> recipes = [];
  String searchQuery = "e"; // Default search term
  bool isLoading = true;

  // Hardcoded diet and health filters
  final List<String> availableDiets = [
    'balanced',
    'high-protein',
    'high-fiber',
    'low-fat',
    'low-carb',
    'low-sodium',
  ];

  final List<String> availableHealthLabels = [
    'dairy-free',
    'egg-free',
    'soy-free',
    'gluten-free',
    'pork-free',
    'red-meat-free',
    'fish-free',
    'shellfish-free',
    'peanut-free',
    'tree-nut-free',
    'vegetarian',
    'vegan',
    'alcohol-free',
    'sugar-conscious',
  ];

  // Selected filters
  List<String> selectedDiets = [];
  List<String> selectedHealthLabels = [];

  @override
  void initState() {
    super.initState();
    getRecipes();
  }

  void getRecipes() async {
    EdamamRecipeSearch recipeService = EdamamRecipeSearch();
    try {
      // Pass diet and health filters to the API method
      List<dynamic> fetchedRecipes = await recipeService.edamamFetchRecipes(
        searchQuery,
        diets: selectedDiets,
        health: selectedHealthLabels,
      );
      setState(() {
        recipes = fetchedRecipes;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipes: ${e.toString()}')),
        );
      }
    }
  }

  // Method to open the filter dialog
  void openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Filter Recipes',
                style: TextStyle(color: Colors.greenAccent[400], fontWeight: FontWeight.bold, fontSize: 24),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Diet Filter Checkboxes
                    Text('Diet Preferences:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    Column(
                      children: availableDiets.map((diet) {
                        return CheckboxListTile(
                          activeColor: Colors.greenAccent[400],
                          checkColor: Colors.black,
                          title: Text(diet, style: TextStyle(color: Colors.white)),
                          value: selectedDiets.contains(diet),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedDiets.add(diet);
                              } else {
                                selectedDiets.remove(diet);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Health Filter Checkboxes
                    Text('Allergies & Preferences:', style: TextStyle(color: Colors.white, fontWeight:  FontWeight.bold, fontSize: 20)),
                    Column(
                      children: availableHealthLabels.map((label) {
                        return CheckboxListTile(
                          activeColor: Colors.greenAccent[400],
                          checkColor: Colors.black,
                          title: Text(label, style: TextStyle(color: Colors.white)),
                          value: selectedHealthLabels.contains(label),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedHealthLabels.add(label);
                              } else {
                                selectedHealthLabels.remove(label);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() => isLoading = true);
                    getRecipes();
                  },
                  child: Text('Apply', style: TextStyle(color: Colors.greenAccent[400])),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Recipes',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search for recipes',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.grey[800],
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        setState(() {
                          searchQuery = value;
                          isLoading = true;
                        });
                        getRecipes();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.greenAccent[400]),
                    onPressed: openFilterDialog,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : recipes.isEmpty
                  ? const Center(
                child: Text(
                  'No recipes found',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two recipes per row
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  return RecipeCard(recipe: recipes[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final dynamic recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final String label = recipe['label'] ?? 'Unknown Recipe';
    final String imageUrl = recipe['image'] ?? '';

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              )
                  : const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Add Recipe', style: TextStyle(color: Colors.greenAccent[400], fontWeight: FontWeight.bold),),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddRecipeDetailsPage(recipe: recipe),
                    ),
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
