import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/edamam_retrieverecipe.dart';
import 'package:fyp_recipe/view_recipe_details.dart';

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

  @override
  void initState() {
    super.initState();
    getRecipes();
  }

  void getRecipes() async {
    EdamamRecipeSearch recipeService = EdamamRecipeSearch();
    try {
      List<dynamic> fetchedRecipes = await recipeService.edamamFetchRecipes(searchQuery);
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                    borderRadius: BorderRadius.circular(10), // Adjust this value for roundness
                    borderSide: BorderSide.none, // Removes the border line
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
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
                  childAspectRatio: 0.8, // Adjust the height-to-width ratio as needed
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
    // Extracting the recipe name and image URL
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
            // Recipe Name with fixed height for consistency
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
            // Recipe Image
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
            // View Recipe Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Navigate to RecipeDetailsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsPage(recipe: recipe),
                    ),
                  );
                },
                child: const Text('View Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}







