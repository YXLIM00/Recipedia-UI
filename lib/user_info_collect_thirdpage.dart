import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_home_page.dart';

class UserInfoPage3 extends StatefulWidget {
  const UserInfoPage3({super.key});

  @override
  UserInfoPage3State createState() => UserInfoPage3State();
}

class UserInfoPage3State extends State<UserInfoPage3> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize with default values
  String _dietPurpose = 'Maintain Health';

  // List of available allergies preferences
  final List<String> _allergyOptions = [
    'Dairy-Free',
    'Gluten-Free',
    'Red-Meat-Free',
    'Pork-Free',
    'Fish-Free',
    'Shellfish-Free',
    'Celery-Free',
    'Peanut-Free',
    'Vegetarian',
    'Vegan',
    'Alcohol-Free',
  ];

  // List to store selected allergies
  final List<String> _selectedAllergies = [];

  // Function to save data to Firestore
  Future<void> _saveDietData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'diet_purpose': _dietPurpose, // Store as a single string
          'allergies_preferences': _selectedAllergies, // Store as an array
        }, SetOptions(merge: true));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
    }
  }


  // Method to build neumorphic-style radio buttons
  Widget _buildNeumorphicRadio(String label, String value, String groupValue, Function(String) onChanged) {
    return GestureDetector(
      onTap: () => setState(() => onChanged(value)),
      child: Container(
        decoration: BoxDecoration(
          gradient: (groupValue == value)
              ? LinearGradient(
            colors: [Colors.greenAccent.shade200, Colors.greenAccent.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [Colors.white, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: (groupValue == value) ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // Method to build checkboxes
  Widget _buildAllergyCheckbox(String label) {
    return CheckboxListTile(
      title: Text(
        label,
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      value: _selectedAllergies.contains(label),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedAllergies.add(label);
          } else {
            _selectedAllergies.remove(label);
          }
        });
      },
      activeColor: Colors.greenAccent,
      checkColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          BackgroundContainer(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(
                        'Dietary Preferences',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Diet Purpose
                    Text('Diet Purpose:', style: TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildNeumorphicRadio('Maintain Health', 'Maintain Health', _dietPurpose, (val) => _dietPurpose = val)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Gain Muscle', 'Gain Muscle', _dietPurpose, (val) => _dietPurpose = val)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Lose Weight', 'Lose Weight', _dietPurpose, (val) => _dietPurpose = val)),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Allergies Preferences
                    Text('Allergies Preferences:', style: TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 10),
                    Column(
                      children: _allergyOptions.map((option) => _buildAllergyCheckbox(option)).toList(),
                    ),

                    const SizedBox(height: 50),

                    // Save and Proceed Button
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          if (_dietPurpose.isNotEmpty) {
                            _saveDietData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields')),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.greenAccent.shade200, Colors.greenAccent.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          child: const Text(
                            'Save & Proceed',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
