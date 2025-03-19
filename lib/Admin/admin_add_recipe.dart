import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_search.dart';
import 'package:fyp_recipe/Admin/admin_add_recipe_details.dart';

class AdminAddRecipe extends StatefulWidget {
  const AdminAddRecipe({super.key});

  @override
  AdminAddRecipeState createState() => AdminAddRecipeState();
}

class AdminAddRecipeState extends State<AdminAddRecipe> {
  final admin = FirebaseAuth.instance.currentUser!;
  List<dynamic> recipes = [];
  String searchQuery = "chicken"; // Default search term
  bool isLoading = true;

  // Hardcoded diet and health filters
  final List<String> availableDietLabels = [
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
  List<String> selectedDietLabels = [];
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
        diets: selectedDietLabels,
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
              backgroundColor: Colors.white,
              title: Text(
                'Filter Recipes',
                style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 26),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Diet Filter Checkboxes
                    Text('Diet Labels:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                    Column(
                      children: availableDietLabels.map((diet) {
                        return CheckboxListTile(
                          activeColor: Colors.indigo,
                          checkColor: Colors.white,
                          title: Text(diet, style: TextStyle(color: Colors.black)),
                          value: selectedDietLabels.contains(diet),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedDietLabels.add(diet);
                              } else {
                                selectedDietLabels.remove(diet);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Health Filter Checkboxes
                    Text('Allergies:', style: TextStyle(color: Colors.black, fontWeight:  FontWeight.bold, fontSize: 20)),
                    Column(
                      children: availableHealthLabels.map((label) {
                        return CheckboxListTile(
                          activeColor: Colors.indigo,
                          checkColor: Colors.white,
                          title: Text(label, style: TextStyle(color: Colors.black)),
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
                  child: Text('Apply', style: TextStyle(color: Colors.indigo)),
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
          'Recipedia',
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthStateChange()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Search for recipes',
                      hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      prefixIcon: Icon(Icons.search, color: Colors.white, size: 20,),
                      filled: true,
                      fillColor: Colors.grey,
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
                  icon: Icon(Icons.filter_alt_sharp, color: Colors.indigo, size: 26,),
                  onPressed: openFilterDialog,
                ),
              ],
            ),
          ),

          // Display recipes
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipes.isEmpty
                ? const Center(
              child: Text(
                'No recipes found',
                style: TextStyle(color: Colors.black),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two recipes per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                return RecipeCard(recipe: recipes[index]);
              },
            ),
          ),
        ],
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
      color: Colors.black,
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 3,
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
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Add Recipe', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),),
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
