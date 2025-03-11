import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/Recommendation/user_info_collect_firstpage.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Recommendation/user_home_page.dart';
import 'package:fyp_recipe/Recommendation/user_info_collect_thirdpage.dart';

class UserInfoPage2 extends StatefulWidget {
  const UserInfoPage2({super.key});

  @override
  UserInfoPage2State createState() => UserInfoPage2State();
}

class UserInfoPage2State extends State<UserInfoPage2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize with default values to avoid null errors
  String _glucoseLevel = '';
  String _pressureLevel = '';
  String _cholesterolLevel = '';
  String _diabetes = '';

  Future<void> _saveHealthData() async {
    // List to hold missing fields
    List<String> missingFields = [];

    // Check for missing fields
    if (_glucoseLevel.isEmpty) missingFields.add('Blood Glucose Level');
    if (_pressureLevel.isEmpty) missingFields.add('Blood Pressure Level');
    if (_cholesterolLevel.isEmpty) missingFields.add('Blood Cholesterol Level');
    if (_diabetes.isEmpty) missingFields.add('Diabetes');

    // If there are missing fields, show an error message in AlertDialog
    if (missingFields.isNotEmpty) {
      String missingFieldsMessage = missingFields.join(', ');
      String errorMessage = 'Please fill the missing field(s): $missingFieldsMessage';

      // Show error dialog with the message
      _showErrorDialog(errorMessage);
      return; // Return early if validation fails
    }

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
          SnackBar(content: Text('Failed to save user data: $e')),
        );
      }
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Missing Value',
            style: TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.bold
            ),
          ),
          content: Text(errorMessage, style: TextStyle(color: Colors.black, fontSize: 16),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK', style: TextStyle(color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold),),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNeumorphicRadio(String label, String value, String groupValue, Function(String) onChanged) {
    return Container(
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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure label and radio button are spaced out
        children: [
          // Label Text
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Consistent text color
            ),
          ),
          // Radio Button
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: (String? newValue) {
              setState(() => onChanged(newValue!));
            },
            activeColor: Colors.indigo.shade400, // Circle changes color when selected
          ),
        ],
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

                SizedBox(height: 40),
                Center(
                  child: Text(
                    'Health Information',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),

                SizedBox(height: 40),
                // Blood Glucose Level
                Text('Blood Glucose Level:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNeumorphicRadio('High', 'High', _glucoseLevel, (val) => _glucoseLevel = val),
                    SizedBox(height: 20),
                    _buildNeumorphicRadio('Normal', 'Normal', _glucoseLevel, (val) => _glucoseLevel = val),
                    SizedBox(height: 20),
                    _buildNeumorphicRadio('Low', 'Low', _glucoseLevel, (val) => _glucoseLevel = val),
                  ],
                ),

                SizedBox(height: 40),
                // Blood Pressure Level
                Text('Blood Pressure Level:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNeumorphicRadio('High', 'High', _pressureLevel, (val) => _pressureLevel = val),
                    SizedBox(height: 20),
                    _buildNeumorphicRadio('Normal', 'Normal', _pressureLevel, (val) => _pressureLevel = val),
                    SizedBox(height: 20),
                    _buildNeumorphicRadio('Low', 'Low', _pressureLevel, (val) => _pressureLevel = val),
                  ],
                ),

                SizedBox(height: 40),

                // Blood Cholesterol Level
                Text('Blood Cholesterol Level:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
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
                Text('Do you have Diabetes?', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNeumorphicRadio('Yes', 'Yes', _diabetes, (val) => _diabetes = val)),
                    SizedBox(width: 20),
                    Expanded(child: _buildNeumorphicRadio('No', 'No', _diabetes, (val) => _diabetes = val)),
                  ],
                ),

                SizedBox(height: 50),

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
                          MaterialPageRoute(builder: (context) => UserInfoPage1()),
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
                        _saveHealthData();
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

