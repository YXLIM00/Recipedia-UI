import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_home_page.dart';
import 'package:fyp_recipe/user_info_collect_secondpage.dart';

class UserInfoPage1 extends StatefulWidget {
  const UserInfoPage1({super.key});

  @override
  UserInfoPage1State createState() => UserInfoPage1State();
}

class UserInfoPage1State extends State<UserInfoPage1> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedSex;
  double? _age;
  double? _height;
  double? _weight;
  String? _selectedActivityFactor;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final Map<String, double> activityFactors = {
    "Sedentary \n(little/no exercise)": 1.2,
    "Lightly Active \n(light exercise 1-3 days/week)": 1.375,
    "Moderately Active \n(moderate exercise 3-5 days/week)": 1.55,
    "Highly Active \n(heavy exercise 6-7 days/week)": 1.725,
    "Extremely Active \n(athlete training/physical job)": 1.9,
  };

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists &&
          userDoc['sex'] != null &&
          userDoc['age'] != null &&
          userDoc['height'] != null &&
          userDoc['weight'] != null &&
          userDoc['activity_factor'] != null) {
        // If user data is already present, navigate to UserHomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHomePage()),
        );

      }
    }
  }

  Future<void> _saveUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'sex': _selectedSex,
        'age': _age, // Save age as a double
        'height': _height,
        'weight': _weight,
        'activity_factor': activityFactors[_selectedActivityFactor],
      }, SetOptions(merge: true));

      // Navigate to the next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserInfoPage2()),
      );
    }
  }

  Widget _buildNeumorphicRadio(String label, String value) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSex = value), // Only sets _selectedSex
      child: Container(
        decoration: BoxDecoration(
          // Applying gradient for a more 3D look
          gradient: (_selectedSex == value)
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
            // Darker shadow for a deeper 3D effect
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: (_selectedSex == value) ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicTextField(TextEditingController controller, String hintText, bool isHeightField) {
    return StatefulBuilder(
      builder: (context, setState) {
        // Function to validate the input value
        bool isValidInput(String value) {
          final regex = RegExp(r'^\d+(\.\d{1,2})?$'); // Regex to allow only two decimal places
          final input = double.tryParse(value);
          if (input == null || !regex.hasMatch(value)) return false;
          if (isHeightField) {
            return input >= 20 && input <= 200; // Height validation range
          } else {
            return input >= 10 && input <= 200; // Weight validation range
          }
        }

        // Determine the current input validity
        bool isValid = isValidInput(controller.text);

        return Container(
          decoration: BoxDecoration(
            // Applying gradient for a more 3D look
            gradient: isValid
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
              // Darker shadow for a deeper 3D effect
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Limit to 2 decimal places
            ],
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.black),
              border: InputBorder.none,
            ),
            style: TextStyle(
              color: isValid ? Colors.white : Colors.black, // Change text color based on validity
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) {
              setState(() {}); // Trigger UI update for color change
              if (isHeightField) {
                _height = double.tryParse(value);
              } else {
                _weight = double.tryParse(value);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildNeumorphicAgeField() {
    return StatefulBuilder(
      builder: (context, setState) {
        // Function to validate the age input
        bool isValidInput(String value) {
          final input = int.tryParse(value);
          return input != null && input >= 1 && input <= 80;
        }

        bool isValid = isValidInput(_ageController.text);

        return Container(
          decoration: BoxDecoration(
            gradient: isValid
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2), // Limit to 2 digits
            ],
            decoration: InputDecoration(
              hintText: "eg. 18",
              hintStyle: TextStyle(color: Colors.black),
              border: InputBorder.none,
            ),
            style: TextStyle(
              color: isValid ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) {
              setState(() {}); // Trigger UI update for color change
              _age = double.tryParse(value);
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityFactorRadio(String label, String value) {
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityFactor = value), // Set the selected activity factor
      child: Container(
        decoration: BoxDecoration(
          // Gradient for a 3D look
          gradient: (_selectedActivityFactor == value)
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
            // Darker shadow for depth
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: (_selectedActivityFactor == value) ? Colors.white : Colors.black,
          ),
        ),
      ),
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
              onTap: () {
                // Unfocus the text field and hide the keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 80), // Add some space from the top
                          Center(
                            child: Text(
                              'Body Measurement',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(height: 50),
                          // Sex Selection
                          Text('Select your sex:', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildNeumorphicRadio('Male', 'Male')),
                              SizedBox(width: 20),
                              Expanded(child: _buildNeumorphicRadio('Female', 'Female')),
                            ],
                          ),

                          SizedBox(height: 40),
                          // Age Input
                          Text('Enter your age (1 to 80):', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(height: 10),
                          _buildNeumorphicAgeField(),


                          SizedBox(height: 40),
                          // Neumorphic Height Input
                          Text('Enter your height (cm):', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(height: 10),
                          _buildNeumorphicTextField(_heightController, "eg. 170.50", true),

                          SizedBox(height: 40),
                          // Neumorphic Weight Input
                          Text('Enter your weight (kg):', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(height: 10),
                          _buildNeumorphicTextField(_weightController, "eg. 60.55", false),

                          SizedBox(height: 40),
                          // Activity Factor Selection
                          Text('Select your activity level:', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch, // Full-width alignment
                            children: activityFactors.keys.map((key) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20), // Space between buttons
                                child: _buildActivityFactorRadio(key, key), // Reusing the function
                              );
                            }).toList(),
                          ),


                          SizedBox(height: 50),
                          // Save and Proceed Button
                          Align(
                            alignment: Alignment.bottomRight,
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedSex != null && _age != null && _height != null && _weight != null && _selectedActivityFactor != null) {
                                  _saveUserData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please fill all fields')),
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
                ],
              ),
            ),
          ),

          // Positioned "Skip" Button
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserHomePage()),
                );
              },
              child: Text('Skip', style: TextStyle(color: Colors.greenAccent[400], fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}