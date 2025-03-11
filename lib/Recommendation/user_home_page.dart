import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image_update.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Share_Services/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/Recommendation/user_dietary_recommendation.dart';
import 'package:fyp_recipe/Recommendation/user_recommended_recipes_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  late String userId;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Track if the section is expanded
  bool _isDailyCaloriesExpanded = false;
  bool _isDietLabelsExpanded = false;
  bool _isHealthLabelsExpanded = false;
  bool _isHealthyExpanded = false;
  bool _isHarmfulExpanded = false;
  bool _isSafetyExpanded = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    loadDietaryRecommendations();
    RecipeImagePreloader.checkAndUpdateRecipeImages();
  }

  Future<void> loadDietaryRecommendations() async {
    try {
      // Run calculations and label customization
      final recommendation = UserDietaryRecommendation(userId: userId);
      await recommendation.calculateAndStoreData();
      await recommendation.customizeLabels();

      // Fetch the updated user data
      final userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        setState(() {
          userData = userSnapshot.data();
          isLoading = false;
        });
      } else {
        throw Exception("User data not found.");
      }
    } catch (e) {
      print("Error loading recommendations: $e");
    }
  }

  Widget buildNeumorphicButton({required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade200, Colors.indigo.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),// Light background for the button
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade500,
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white,
              offset: const Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Dietary Recommendation',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),


            // Daily Calories Intake Section
            SizedBox(height: 40),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Arrow Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Daily Calories Intake",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isDailyCaloriesExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isDailyCaloriesExpanded = !_isDailyCaloriesExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isDailyCaloriesExpanded) ...[
                      const SizedBox(height: 20),

                      // Displaying "BMI", "Status", and "Calories" on the same line
                      Row(
                        children: [
                          Expanded(child: Text("BMI", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,)),
                          SizedBox(width: 5),
                          Expanded(child: Text("Status", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,)),
                          SizedBox(width: 5),
                          Expanded(child: Text("Calories", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Displaying the values of 'current_bmi', 'current_bmi_status', and 'recommended_calories_intake'
                      Row(
                        children: [
                          Expanded(child: Text(userData?['current_bmi']?.toStringAsFixed(2) ?? '', style: TextStyle(fontSize: 16), textAlign: TextAlign.center,)),
                          SizedBox(width: 5),
                          Expanded(child: Text(userData?['current_bmi_status'] ?? '', style: TextStyle(fontSize: 16), textAlign: TextAlign.center,)),
                          SizedBox(width: 5),
                          Expanded(child: Text(userData?['recommended_calories_intake']?.toStringAsFixed(2) ?? '', style: TextStyle(fontSize: 16), textAlign: TextAlign.center,)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Recipes with Diet Labels Section
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Arrow Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recipes with Diet Labels",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isDietLabelsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isDietLabelsExpanded = !_isDietLabelsExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isDietLabelsExpanded) ...[
                      const SizedBox(height: 10),
                      // Display diet labels list
                      if (userData?['custom_dietLabels']?.isNotEmpty ?? false) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (userData!['custom_dietLabels'] as List<dynamic>)
                              .map((label) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: Text(
                              "- $label",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ] else
                        const Text(
                          "No diet labels to take note.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Recipes with Health Labels Section
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Arrow Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recipes with Health Labels",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isHealthLabelsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isHealthLabelsExpanded = !_isHealthLabelsExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isHealthLabelsExpanded) ...[
                      const SizedBox(height: 10),
                      // Display health labels list
                      if (userData?['custom_healthLabels']?.isNotEmpty ?? false) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (userData!['custom_healthLabels'] as List<dynamic>)
                              .map((label) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: Text(
                              "- $label",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ] else
                        const Text(
                          "No health labels to take note.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Healthy Food Section
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Arrow Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Healthy Food",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isHealthyExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isHealthyExpanded = !_isHealthyExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isHealthyExpanded) ...[
                      const SizedBox(height: 10),
                      // Display healthy food list
                      if (userData?['custom_helpful_food']?.isNotEmpty ?? false) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (userData!['custom_helpful_food'] as List<dynamic>)
                              .map((label) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: Text(
                              "- $label",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ] else
                        const Text(
                          "No particular food that is helpful for your health.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Harmful Food Section
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Arrow Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Harmful Food",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isHarmfulExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isHarmfulExpanded = !_isHarmfulExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isHarmfulExpanded) ...[
                      const SizedBox(height: 10),
                      // Display harmful food list
                      if (userData?['custom_harmful_food']?.isNotEmpty ?? false) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (userData!['custom_harmful_food'] as List<dynamic>)
                              .map((label) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: Text(
                              "- $label",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ] else
                        const Text(
                          "No particular food that is harmful for your health.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Safety Advices Section
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Arrow Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Safety Advices",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isSafetyExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSafetyExpanded = !_isSafetyExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isSafetyExpanded) ...[
                      const SizedBox(height: 10),
                      // Display safety advice list
                      if (userData?['custom_cautions']?.isNotEmpty ?? false) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (userData!['custom_cautions'] as List<dynamic>)
                              .map((label) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: Text(
                              "- $label",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ] else
                        const Text(
                          "No particular safety advices based on your health.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // See Recipe Recommendations Button
            const SizedBox(height: 40),
            buildNeumorphicButton(
              label: "See Recipe Recommendations",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserRecommendedRecipesPage()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 0),
    );
  }
}
