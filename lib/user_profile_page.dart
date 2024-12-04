import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/auth_state_change.dart';
import 'package:fyp_recipe/user_bottom_nav_bar.dart';
import 'package:fyp_recipe/user_info_change_firstpage.dart';
import 'package:fyp_recipe/user_info_change_secondpage.dart';
import 'package:fyp_recipe/user_info_change_thirdpage.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;
  
  bool _isPersonalInfoExpanded = false;
  bool _isHealthInfoExpanded = false;
  bool _isDietaryInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data();
        });
      }
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
                'User Profile',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
        
        
            // Personal Information Section
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
                        const Text(
                          "Personal Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isPersonalInfoExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPersonalInfoExpanded =
                              !_isPersonalInfoExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isPersonalInfoExpanded) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Sex:  ${userData?['sex'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Age:  ${userData?['age'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Height:  ${userData?['height']?.toStringAsFixed(2) ?? 'Not available'} cm",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Weight:  ${userData?['weight']?.toStringAsFixed(2) ?? 'Not available'} kg",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
        
                      const SizedBox(height: 20),
                      // Go Update Button
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => UserChangeInfoPage1()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade200, Colors.indigo.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
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
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            child: Text(
                              'Go Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        
            // Health Information Section
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
                        const Text(
                          "Health Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isHealthInfoExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isHealthInfoExpanded =
                              !_isHealthInfoExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isHealthInfoExpanded) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Blood Glucose Level:  ${userData?['blood_glucose_level'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Blood Pressure Level:  ${userData?['blood_pressure_level'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Blood Cholesterol Level:  ${userData?['blood_cholesterol_level'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Diabetes:  ${userData?['diabetes'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
        
                      const SizedBox(height: 20),
                      // Go Update Button
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => UserChangeInfoPage2()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade200, Colors.indigo.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
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
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            child: Text(
                              'Go Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        
            // Dietary Information Section
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
                        const Text(
                          "Dietary Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isDietaryInfoExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isDietaryInfoExpanded =
                              !_isDietaryInfoExpanded; // Toggle expansion state
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isDietaryInfoExpanded) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Diet Purpose:  ${userData?['diet_purpose'] ?? 'Not available'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Allergies:  ${userData?['allergies_preferences'] != null && (userData?['allergies_preferences'] as List).isNotEmpty ? (userData?['allergies_preferences'] as List).join(', ') : 'Not available'}",
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
        
        
                      const SizedBox(height: 20),
                      // Go Update Button
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => UserChangeInfoPage3()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade200, Colors.indigo.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
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
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            child: Text(
                              'Go Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const UserBottomNavBar(currentIndex: 4),
    );
  }
}
