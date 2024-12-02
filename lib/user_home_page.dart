import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/user_dietary_recommendation.dart';
import 'package:fyp_recipe/user_search_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  late String userId;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    loadDietaryRecommendations();
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

  Widget buildNeumorphicCard(String title, dynamic content, {bool isList = false}) {
    if (content == null || (isList && content is! Iterable)) {
      return const SizedBox.shrink(); // Return an empty widget if content is invalid
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white, // Light background for the card
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            const BoxShadow(
              color: Colors.white, // Light shadow on top-left
              offset: Offset(-4, -4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.grey.shade500, // Dark shadow on bottom-right
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (isList && content is Iterable)
              ...content
                  .map((item) => Text("~ $item", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87))),
            if (!isList) Text(content.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }


  Widget buildNeumorphicButton({required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent.shade200, Colors.greenAccent.shade400],
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
      body: BackgroundContainer(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text(
                  'Dietary Recommendation 😊',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 50),
              buildNeumorphicCard(
                "Your current BMI value:",
                userData?['current_bmi']?.toStringAsFixed(2),
              ),
              buildNeumorphicCard(
                "Your current BMI status:",
                userData?['current_bmi_status'],
              ),
              buildNeumorphicCard(
                "Recommended Total Calories Intake/Day (calories):",
                userData?['recommended_calories_intake']?.toStringAsFixed(2),
              ),
              if (userData?['custom_dietLabels']?.isNotEmpty ?? false)
                buildNeumorphicCard(
                  "Recommended recipes with Diet Labels:",
                  userData?['custom_dietLabels'], // Pass the list directly
                  isList: true,
                ),
              if (userData?['custom_healthLabels']?.isNotEmpty ?? false)
                buildNeumorphicCard(
                  "Recommended recipes with Health Labels:",
                  userData?['custom_healthLabels'],
                  isList: true,
                ),
              if (userData?['custom_harmful_food']?.isNotEmpty ?? false)
                buildNeumorphicCard(
                  "Food HARMFUL for your health condition:",
                  userData?['custom_harmful_food'],
                  isList: true,
                ),
              if (userData?['custom_helpful_food']?.isNotEmpty ?? false)
                buildNeumorphicCard(
                  "Food HELPFUL for your health condition:",
                  userData?['custom_helpful_food'],
                  isList: true,
                ),
              if (userData?['custom_cautions']?.isNotEmpty ?? false)
                buildNeumorphicCard(
                  "Caution Advices:",
                  userData?['custom_cautions'],
                  isList: true,
                ),
              const SizedBox(height: 20),
              buildNeumorphicButton(
                label: "See Recipe Recommendations",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserSearchPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 0),
    );
  }
}
