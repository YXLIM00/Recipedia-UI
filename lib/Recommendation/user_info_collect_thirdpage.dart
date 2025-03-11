import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/Recommendation/user_info_collect_secondpage.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Recommendation/user_home_page.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class UserInfoPage3 extends StatefulWidget {
  const UserInfoPage3({super.key});

  @override
  UserInfoPage3State createState() => UserInfoPage3State();
}

class UserInfoPage3State extends State<UserInfoPage3> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedRadioValue = ''; // To track the selected radio button

  // List to store selected allergies
  List<String> _selectedAllergies = [];

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

  // Method to update selected radio value
  void _onRadioChanged(String value) {
    setState(() {
      _selectedRadioValue = value;
    });
  }

  // Method to handle multi-select combo box changes
  void _onAllergyConfirm(List<String> selectedValues) {
    setState(() {
      _selectedAllergies = selectedValues;
    });
  }

  // Function to save data to Firestore
  Future<void> _saveDietData() async {
    if (_selectedRadioValue.isEmpty) {
      // Show an AlertDialog if the diet purpose is not filled
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing Value'),
            content: const Text('Please fill the missing field(s): Diet Purpose'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Exit early to prevent further execution
    }

    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'diet_purpose': _selectedRadioValue, // Store as a single string
          'allergies': _selectedAllergies, // Store as an array
        }, SetOptions(merge: true));

        // Navigate to the next page after saving data
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // No color change for the container
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Place the radio button and label on opposite sides
        children: [
          // Label Text on the left
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black, // Text color stays consistent
            ),
          ),
          // Radio Button circle on the right side
          Radio<String>(
            value: value,
            groupValue: groupValue, // Make sure groupValue is passed correctly
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue); // Update state when radio button is pressed
              }
            },
            activeColor: Colors.indigo.shade400, // Circle changes color when selected
          ),
        ],
      ),
    );
  }



  // Method to build multi-select dropdown (ComboBox)
  Widget _buildAllergyMultiSelect() {
    return MultiSelectDialogField(
      items: _allergyOptions
          .map((allergy) => MultiSelectItem<String>(allergy, allergy))
          .toList(),
      title: Text("Allergies:", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
      selectedColor: Colors.indigo,
      buttonText: Text(" Choose Here", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      decoration: BoxDecoration(
        color: Colors.white, // No color change for the container
        borderRadius: BorderRadius.circular(10),
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
      onConfirm: (values) {
        _onAllergyConfirm(values.cast<String>());
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Skip" Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Align 'Skip' text to the right
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const UserHomePage()),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration:  TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.solid, // Solid underline
                          decorationColor: Colors.indigo, // Indigo color for the underline
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Dietary Information',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Diet Purpose
                Text('Diet Purpose:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNeumorphicRadio('Maintain Health', 'Maintain Health', _selectedRadioValue, _onRadioChanged),
                    const SizedBox(height: 20),
                    _buildNeumorphicRadio('Gain Muscle', 'Gain Muscle', _selectedRadioValue, _onRadioChanged),
                    const SizedBox(height: 20),
                    _buildNeumorphicRadio('Lose Weight', 'Lose Weight', _selectedRadioValue, _onRadioChanged),
                  ],
                ),

                const SizedBox(height: 40),
                // Allergies
                Text('Allergies:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _buildAllergyMultiSelect(),
                  ],
                ),

                const SizedBox(height: 50),
                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () {
                        // Navigate back to UserInfoPage1
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => UserInfoPage2()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Default background color
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
                          'Back',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),

                    // Save & Proceed Button
                    GestureDetector(
                      onTap: () {
                        _saveDietData();
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
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        child: Text(
                          'Save & Proceed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
