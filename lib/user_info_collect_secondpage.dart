import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/background_image_container.dart';
import 'package:fyp_recipe/user_info_collect_thirdpage.dart';

class UserInfoPage2 extends StatefulWidget {
  const UserInfoPage2({super.key});

  @override
  UserInfoPage2State createState() => UserInfoPage2State();
}

class UserInfoPage2State extends State<UserInfoPage2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize with default values to avoid null errors
  String _glucoseLevel = 'Normal';
  String _pressureLevel = 'Normal';
  String _cholesterolLevel = 'Normal';
  String _diabetes = 'No';

  Future<void> _saveHealthData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'blood_glucose_level': _glucoseLevel,
          'blood_pressure_level': _pressureLevel,
          'blood_cholesterol_level': _cholesterolLevel,
          'diabetes': _diabetes,
        }, SetOptions(merge: true));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserInfoPage3()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
    }
  }

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
            color: (groupValue == value) ? Colors.white : Colors.black,
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
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80),
                    Center(
                      child: Text(
                        'Health Condition',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 50),

                    // Blood Glucose Level
                    Text('Blood Glucose Level:', style: TextStyle(fontSize: 16, color: Colors.white)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildNeumorphicRadio('High', 'High', _glucoseLevel, (val) => _glucoseLevel = val)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Normal', 'Normal', _glucoseLevel, (val) => _glucoseLevel = val)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Low', 'Low', _glucoseLevel, (val) => _glucoseLevel = val)),
                      ],
                    ),

                    SizedBox(height: 40),

                    // Blood Pressure Level
                    Text('Blood Pressure Level:', style: TextStyle(fontSize: 16, color: Colors.white)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildNeumorphicRadio('High', 'High', _pressureLevel, (val) => _pressureLevel = val)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Normal', 'Normal', _pressureLevel, (val) => _pressureLevel = val)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Low', 'Low', _pressureLevel, (val) => _pressureLevel = val)),
                      ],
                    ),

                    SizedBox(height: 40),

                    // Blood Cholesterol Level
                    Text('Blood Cholesterol Level:', style: TextStyle(fontSize: 16, color: Colors.white)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildNeumorphicRadio('High', 'High', _cholesterolLevel, (val) => _cholesterolLevel = val)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('Normal', 'Normal', _cholesterolLevel, (val) => _cholesterolLevel = val)),
                      ],
                    ),

                    SizedBox(height: 40),

                    // Diabetes
                    Text('Do you have Diabetes?', style: TextStyle(fontSize: 16, color: Colors.white)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildNeumorphicRadio('Yes', 'Yes', _diabetes, (val) => _diabetes = val)),
                        SizedBox(width: 20),
                        Expanded(child: _buildNeumorphicRadio('No', 'No', _diabetes, (val) => _diabetes = val)),
                      ],
                    ),

                    SizedBox(height: 50),

                    // Save and Proceed Button
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          if (_glucoseLevel.isNotEmpty && _pressureLevel.isNotEmpty && _cholesterolLevel.isNotEmpty && _diabetes.isNotEmpty) {
                            _saveHealthData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please fill all fields')),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            // Gradient for the 3D look
                            gradient: LinearGradient(
                              colors: [Colors.greenAccent.shade200, Colors.greenAccent.shade400],
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

