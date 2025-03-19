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
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Filter options
  final List<String> dietLabels = ['High-Protein', 'Low-Carb', 'Low-Fat'];
  final List<String> healthLabels = [
    'Dairy-Free', 'Egg-Free', 'Soy-Free', 'Gluten-Free', 'Pork-Free', 'Red-Meat-Free',
    'Fish-Free', 'Shellfish-Free', 'Peanut-Free', 'Tree-Nut-Free', 'Vegetarian',
    'Vegan', 'Alcohol-Free', 'Sugar-Conscious'
  ];

  List<String> selectedDietLabels = [];
  List<String> selectedHealthLabels = [];

  @override
  void initState() {
    super.initState();
    fetchGroupedRecipes();
  }

  // Grouped Recipes (updated after filters or search)
  Map<String, List<Map<String, dynamic>>> groupedRecipes = {};

  // Fetch and group recipes based on food categories
  Future<void> fetchGroupedRecipes() async {
    try {
      final recipesCollection = FirebaseFirestore.instance.collection('recipes');
      final snapshot = await recipesCollection.get();

      final newGroupedRecipes = <String, List<Map<String, dynamic>>>{};
      const foodCategories = ['chicken', 'beef', 'fish', 'rice'];

      for (var doc in snapshot.docs) {
        final recipe = doc.data();
        final recipeName = (recipe['label'] ?? '').toString().toLowerCase();
        final recipeDietLabels = List<String>.from(recipe['dietLabels'] ?? []);
        final recipeHealthLabels = List<String>.from(recipe['healthLabels'] ?? []);

        // Determine category based on ingredient keywords
        String matchedCategory = foodCategories.firstWhere(
              (category) => recipeName.contains(category),
          orElse: () => 'Others',
        );

        // Apply search and filter conditions
        final matchesSearchQuery = searchQuery.isEmpty || recipeName.contains(searchQuery.toLowerCase());
        final matchesDietLabels = selectedDietLabels.isEmpty || selectedDietLabels.every(recipeDietLabels.contains);
        final matchesHealthLabels = selectedHealthLabels.isEmpty || selectedHealthLabels.every(recipeHealthLabels.contains);

        if (matchesSearchQuery && matchesDietLabels && matchesHealthLabels) {
          newGroupedRecipes.putIfAbsent(matchedCategory, () => []);
          newGroupedRecipes[matchedCategory]!.add(recipe);
        }
      }

      setState(() {
        groupedRecipes = newGroupedRecipes;
      });
    } catch (e) {
      print('Failed to fetch recipes: $e');
    }
  }

  // Show Filter Dialog
  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Filter Recipes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diet Labels:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ...dietLabels.map((label) => CheckboxListTile(
                      title: Text(label),
                      value: selectedDietLabels.contains(label),
                      onChanged: (isSelected) {
                        setStateDialog(() {
                          isSelected! ? selectedDietLabels.add(label) : selectedDietLabels.remove(label);
                        });
                      },
                    )),
                    const SizedBox(height: 10),
                    const Text('Health Labels:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ...healthLabels.map((label) => CheckboxListTile(
                      title: Text(label),
                      value: selectedHealthLabels.contains(label),
                      onChanged: (isSelected) {
                        setStateDialog(() {
                          isSelected! ? selectedHealthLabels.add(label) : selectedHealthLabels.remove(label);
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    fetchGroupedRecipes(); // Refresh immediately after applying filters
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo
                    ),
                  ),
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'All Recipes',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),

            // Search Bar with Filter Icon
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  hintStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    onPressed: showFilterDialog,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.indigo, width: 3),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (query) {
                  setState(() => searchQuery = query);
                  fetchGroupedRecipes();
                },
              ),
            ),
            const SizedBox(height: 10),

            // Recipes List (Grouped with Horizontal Scroll)
            Expanded(
              child: groupedRecipes.isEmpty
                  ? const Center(child: Text("No recipes found."))
                  : ListView.builder(
                itemCount: groupedRecipes.keys.length,
                itemBuilder: (context, index) {
                  final category = groupedRecipes.keys.elementAt(index);
                  final recipes = groupedRecipes[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 20.0),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Horizontal Scroll View for Recipes
                      SizedBox(
                        height: 230, // Increase height slightly to fit the bigger image and text
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
                                width: 160,
                                margin: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0, bottom: 8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bigger Recipe Image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        recipe['image'],
                                        width: double.infinity,
                                        height: 140, // Increase image height for better focus
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Recipe Name (3 lines)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        recipe['label'],
                                        textAlign: TextAlign.center,
                                        maxLines: 3, // Allow 3 lines for long names
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5), // Adjust spacing
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const UserBottomNavBar(currentIndex: 1),
      ),
    );
  }

}


