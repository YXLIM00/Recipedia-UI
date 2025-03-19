import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Share_Services/user_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMealplanPage extends StatefulWidget {
  const UserMealplanPage({super.key});

  @override
  UserMealplanPageState createState() => UserMealplanPageState();
}

class UserMealplanPageState extends State<UserMealplanPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();

  Map<String, List<Map<String, dynamic>>> mealPlan = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snacks': [],
  };

  double totalCalories = 0;
  double recommendedCaloriesIntake = 0;

  @override
  void initState() {
    super.initState();
    fetchUserRecommendedCalories();
    fetchSavedMealPlan();
  }

  void fetchUserRecommendedCalories() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      setState(() {
        recommendedCaloriesIntake = (userDoc['recommended_calories_intake'] ?? 0).toDouble();
      });
    }
  }

  void fetchSavedMealPlan() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final mealPlanDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('meal_plans')
            .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
            .get();

        if (mealPlanDoc.exists) {
          final data = mealPlanDoc.data();
          if (data != null && data['mealPlan'] != null) {
            Map<String, List<Map<String, dynamic>>> updatedMealPlan = {
              'Breakfast': [],
              'Lunch': [],
              'Dinner': [],
              'Snacks': [],
            };

            // Fetch recipe details for each meal type
            for (String mealType in updatedMealPlan.keys) {
              List<dynamic> recipes = data['mealPlan'][mealType] ?? [];
              for (var recipe in recipes) {
                String recipeLabel = recipe;  // Directly use recipe as a string
                // Fetch recipe details from the recipes collection
                var recipeDoc = await _firestore
                    .collection('recipes')
                    .where('label', isEqualTo: recipeLabel)
                    .get();

                if (recipeDoc.docs.isNotEmpty) {
                  var recipeData = recipeDoc.docs.first.data();
                  updatedMealPlan[mealType]!.add({
                    'label': recipeLabel,
                    'image': recipeData['image'] ?? 'https://via.placeholder.com/50',
                    'caloriesPerServing': (recipeData['caloriesPerServing'] ?? 0).toDouble(),
                  });
                }
              }
            }

            setState(() {
              mealPlan = updatedMealPlan;
            });
            calculateTotalCalories(); // Recalculate total calories
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching meal plan: $e")),
        );
      }
    }
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        // Clear the meal plan to show empty state while fetching data
        mealPlan = {
          'Breakfast': [],
          'Lunch': [],
          'Dinner': [],
          'Snacks': [],
        };
        totalCalories = 0; // Reset total calories as well
      });
      fetchSavedMealPlan(); // Fetch the saved meal plan for the newly selected date
    }
  }

  void calculateTotalCalories() {
    double sum = 0.0;
    mealPlan.forEach((_, recipes) {
      for (var recipe in recipes) {
        sum += (recipe['caloriesPerServing'] ?? 0).toDouble();
      }
    });
    setState(() {
      totalCalories = sum;
    });
  }

  Future<void> openRecipeSelector(String mealType) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final favoriteRecipes = List<String>.from(userDoc['saved_recipes'] ?? []);
      final recipesQuery = await _firestore
          .collection('recipes')
          .where('label', whereIn: favoriteRecipes)
          .get();

      List<Map<String, dynamic>> availableRecipes = recipesQuery.docs.map((doc) {
        return {
          'label': doc['label'] ?? 'Unnamed Recipe',
          'image': doc['image'] ?? 'https://via.placeholder.com/50',
          'caloriesPerServing': (doc['caloriesPerServing'] ?? 0).toDouble(),
        };
      }).toList();

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8), // Adds spacing at the top
              Expanded(
                child: ListView.builder(
                  itemCount: availableRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = availableRecipes[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          mealPlan[mealType] = (mealPlan[mealType] ?? [])..add(recipe);
                          calculateTotalCalories();
                        });
                        Navigator.pop(context);
                      },
                      child: buildRecipeCard(recipe, mealType, showDeleteButton: false),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );

    }
  }

  Widget buildRecipeCard(Map<String, dynamic> recipe, String mealType, {bool showDeleteButton = true}) {
    final label = recipe['label'] ?? 'Unnamed Recipe';
    final image = recipe['image'] ?? 'https://via.placeholder.com/50'; // Default image URL
    final calories = recipe['caloriesPerServing'] ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${calories.toStringAsFixed(1)} cal/serving",
                    style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                  ),
                ],
              ),
            ),
            if (showDeleteButton) // Conditionally show delete button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Deletion"),
                        content: const Text("Are you sure you want to remove this recipe from your meal plan?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(), // Cancel
                            child: const Text("Cancel", style: TextStyle(color: Colors.indigo),),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                mealPlan[mealType]?.remove(recipe);
                                calculateTotalCalories(); // Recalculate total calories
                              });
                              Navigator.of(context).pop(); // Close dialog after deletion
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

          ],
        ),
      ),
    );
  }

  void saveMealPlan() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        // Create a document for the selected date in the meal_plans subcollection
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('meal_plans')
            .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
            .set({
          'date': selectedDate.toIso8601String(),
          'mealPlan': {
            'Breakfast': mealPlan['Breakfast']?.map((recipe) => recipe['label']).toList() ?? [],
            'Lunch': mealPlan['Lunch']?.map((recipe) => recipe['label']).toList() ?? [],
            'Dinner': mealPlan['Dinner']?.map((recipe) => recipe['label']).toList() ?? [],
            'Snacks': mealPlan['Snacks']?.map((recipe) => recipe['label']).toList() ?? [],
          },
          'totalCalories': totalCalories,
        });

        // Show a success message in an AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Successful!'),
              content: const Text(
                "Meal Plan saved ✅",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving meal plan: $e")),
        );
      }
    } else {
      // Show a message if the user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in!")),
      );
    }
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                'Meal Plan',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),

            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: pickDate,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                // Display for each meal type
                for (String mealType in mealPlan.keys)
                  Card(
                    child: ListTile(
                      title: Text(
                        mealType,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => openRecipeSelector(mealType),
                      ),
                      subtitle: Column(
                        children: mealPlan[mealType]!
                            .map((recipe) => buildRecipeCard(recipe, mealType)) // Pass mealType here
                            .toList(),
                      ),
                    ),
                  )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Calories:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${totalCalories.toStringAsFixed(0)} cal",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4), // Adds spacing between the two rows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recommended Calories:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${recommendedCaloriesIntake.toStringAsFixed(0)} cal",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Neumorphism Save Button inside scrollable area
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        saveMealPlan();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // Gradient for the 3D look
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade200, Colors.indigo.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            // Adding shadows for a deeper 3D effect
                            BoxShadow(
                              color: Colors.grey.shade500,
                              offset: Offset(5, 5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.white,
                              offset: Offset(-5, -5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 3),
    );
  }
}
