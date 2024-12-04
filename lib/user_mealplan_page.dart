import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/user_bottom_nav_bar.dart';
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
            setState(() {
              // Update the mealPlan map
              mealPlan = {
                'Breakfast': List<Map<String, dynamic>>.from(data['mealPlan']['Breakfast'] ?? []),
                'Lunch': List<Map<String, dynamic>>.from(data['mealPlan']['Lunch'] ?? []),
                'Dinner': List<Map<String, dynamic>>.from(data['mealPlan']['Dinner'] ?? []),
                'Snacks': List<Map<String, dynamic>>.from(data['mealPlan']['Snacks'] ?? []),
              };
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



  void fetchUserRecommendedCalories() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      setState(() {
        recommendedCaloriesIntake = (userDoc['recommended_calories_intake'] ?? 0).toDouble();
      });
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
          return ListView.builder(
            itemCount: availableRecipes.length,
            itemBuilder: (context, index) {
              final recipe = availableRecipes[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    mealPlan[mealType] = (mealPlan[mealType] ?? [])..add(recipe);
                    calculateTotalCalories(); // Recalculate total calories after adding
                  });
                  Navigator.pop(context); // Close the pop-up
                },
                child: buildRecipeCard(recipe, mealType, showDeleteButton: false), // Hide delete button here
              );
            },
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
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                image,
                width: 50,
                height: 50,
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${calories.toStringAsFixed(1)} cal",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (showDeleteButton) // Conditionally show delete button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    mealPlan[mealType]?.remove(recipe);
                    calculateTotalCalories(); // Recalculate total calories
                  });
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
            'Breakfast': mealPlan['Breakfast'] ?? [],
            'Lunch': mealPlan['Lunch'] ?? [],
            'Dinner': mealPlan['Dinner'] ?? [],
            'Snacks': mealPlan['Snacks'] ?? [],
          },
          'totalCalories': totalCalories,
        });
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Meal Plan saved successfully!")),
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
        SnackBar(content: Text("User not logged in!")),
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo[400]),
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: saveMealPlan,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Save Meal Plan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          const UserBottomNavBar(currentIndex: 3),
        ],
      ),
    );
  }
}
