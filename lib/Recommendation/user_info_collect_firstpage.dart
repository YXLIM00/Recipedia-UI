import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fyp_recipe/Recommendation/user_info_collect_secondpage.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Recommendation/user_home_page.dart';

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
    "Sedentary \n(little or no exercise)": 1.2,
    "Lightly Active \n(exercise 1-3 days/week)": 1.375,
    "Moderately Active \n(exercise 3-5 days/week)": 1.55,
    "Highly Active \n(exercise 6-7 days/week)": 1.725,
    "Extremely Active \n(athlete training)": 1.9,
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
          userDoc['activity_factor'] != null &&
          userDoc['blood_glucose_level'] != null &&
          userDoc['blood_pressure_level'] != null &&
          userDoc['blood_cholesterol_level'] != null &&
          userDoc['diabetes'] != null &&
          userDoc['diet_purpose'] != null) {
        // If user data is already present, navigate to UserHomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHomePage()),
        );

      }
    }
  }

  Future<void> _saveUserData() async {
    // List to hold missing fields
    List<String> missingFields = [];

    // Check for missing fields
    if (_selectedSex == null) missingFields.add('Sex');
    if (_age == null) missingFields.add('Age');
    if (_height == null) missingFields.add('Height');
    if (_weight == null) missingFields.add('Weight');
    if (_selectedActivityFactor == null) missingFields.add('Activity Factor');

    // If there are missing fields, show an error message
    if (missingFields.isNotEmpty) {
      String missingFieldsMessage = missingFields.join(', ');
      String errorMessage = 'Please fill the missing field(s): $missingFieldsMessage';
      _showErrorDialog(errorMessage);
      return; // Return early if validation fails
    }

    // Validate age, height, and weight input
    String? errorMessage = '';
    if (_age! < 1 || _age! > 120) {
      errorMessage = 'Please enter a valid age (1-120)';
    } else if (_height! < 20 || _height! > 200) {
      errorMessage = 'Please enter a valid height (20-200 cm)';
    } else if (_weight! < 10 || _weight! > 200) {
      errorMessage = 'Please enter a valid weight (10-200 kg)';
    }

    // If there is an error message, show it in an AlertDialog
    if (errorMessage.isNotEmpty) {
      _showErrorDialog(errorMessage);
      return; // Return early to prevent further execution
    }

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Save data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'sex': _selectedSex,
          'age': _age, // Save age as a double
          'height': _height,
          'weight': _weight,
          'activity_factor': activityFactors[_selectedActivityFactor],
        }, SetOptions(merge: true));

        // Navigate to the next page after saving data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserInfoPage2()),
        );
      }
    } catch (e) {
      // Handle any errors during the save operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user data: $e')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Missing or Invalid Value',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold
          ),
        ),
        content: Text(message, style: TextStyle(color: Colors.black, fontSize: 16),),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('OK', style: TextStyle(color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicRadio(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Place text and radio apart
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Text color remains constant
            ),
          ),
          Radio<String>(
            value: value,
            groupValue: _selectedSex,
            onChanged: (String? newValue) {
              setState(() => _selectedSex = newValue!);
            },
            activeColor: Colors.indigo.shade400, // Change only the radio button's color
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFactorRadio(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align text and radio
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Text color remains constant
              ),
            ),
          ),
          Radio<String>(
            value: value,
            groupValue: _selectedActivityFactor,
            onChanged: (String? newValue) {
              setState(() => _selectedActivityFactor = newValue!);
            },
            activeColor: Colors.indigo.shade400, // Change only the radio button's color
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicAgeField() {
    return StatefulBuilder(
      builder: (context, setState) {
        String errorMessage = ''; // Store the error message

        // Function to validate the age input (between 1 and 120 and not empty)
        bool isValidInput(String value) {
          if (value.isEmpty) {
            errorMessage = 'Age cannot be empty!'; // Set error for empty input
            return false;
          }
          // Check if the value starts with 0 (and is not 0 itself)
          if (value.startsWith('0') && value != '0') {
            errorMessage = 'Please enter a valid age! (no leading zeros)';
            return false;
          }

          final input = int.tryParse(value);
          if (input == null || input < 1 || input > 120) {
            errorMessage = 'Please enter a valid age! (1-120)';
            return false;
          }

          errorMessage = ''; // Clear error message if valid
          return true;
        }

        bool isValid = isValidInput(_ageController.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: isValid
                    ? LinearGradient(
                  colors: [Colors.indigo.shade200, Colors.indigo.shade400],
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
                  LengthLimitingTextInputFormatter(3), // Allowing up to 3 digits (for age 120)
                ],
                decoration: InputDecoration(
                  hintText: "eg. 18",
                  hintStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: isValid ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger UI update for color change
                  _age = double.tryParse(value);
                },
              ),
            ),
            // Error message displayed below the TextField, outside the container
            if (!isValid) // Show error message if input is not valid
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.redAccent[400], fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNeumorphicTextField(TextEditingController controller, String hintText, bool isHeightField) {
    return StatefulBuilder(
      builder: (context, setState) {
        String errorMessage = ''; // Variable to store the error message

        // Function to validate the input value
        bool isValidInput(String value) {
          if (value.isEmpty) {
            errorMessage = isHeightField
                ? 'Height cannot be empty!'  // Custom message for height
                : 'Weight cannot be empty!';  // Custom message for weight
            return false;
          }

          // Regex to allow valid numbers with up to two decimal places but no leading zeroes unless it's '0'
          final regex = RegExp(r'^(?!0\d)\d+(\.\d{1,2})?$'); // No leading zeros unless the value is '0'
          final input = double.tryParse(value);
          if (input == null || !regex.hasMatch(value)) {
            errorMessage = 'Please enter a valid number with up to two decimal places and no leading zero.';
            return false;
          }
          if (isHeightField) {
            if (input < 20 || input > 200) {
              errorMessage = 'Height should be between 20 and 200 cm.';
              return false;
            }
          } else {
            if (input < 10 || input > 200) {
              errorMessage = 'Weight should be between 10 and 200 kg.';
              return false;
            }
          }

          errorMessage = ''; // Clear error message if input is valid
          return true;
        }

        // Determine the current input validity
        bool isValid = isValidInput(controller.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                // Applying gradient for a more 3D look
                gradient: isValid
                    ? LinearGradient(
                  colors: [Colors.indigo.shade200, Colors.indigo.shade400],
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
                  hintStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: isValid ? Colors.white : Colors.black, // Change text color based on validity
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
            ),
            // Error message displayed below the TextField, outside the container
            if (!isValid) // Show error message if input is not valid
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.redAccent[400], fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
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
          GestureDetector(
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


                        // Page Title
                        SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Personal Information',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),


                        // Sex Selection
                        SizedBox(height: 40),
                        Text('Select your sex:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space evenly between items
                          children: [
                            Expanded(child: _buildNeumorphicRadio('Male', 'Male')),
                            SizedBox(width: 20), // Space between the two options
                            Expanded(child: _buildNeumorphicRadio('Female', 'Female')),
                          ],
                        ),


                        // Age Input
                        SizedBox(height: 40),
                        Text('Enter your age (1 to 120):', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                        SizedBox(height: 10),
                        _buildNeumorphicAgeField(),


                        // Height Input
                        SizedBox(height: 40),
                        Text('Enter your height (cm):', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                        SizedBox(height: 10),
                        _buildNeumorphicTextField(_heightController, "eg. 170.50", true),


                        // Weight Input
                        SizedBox(height: 40),
                        Text('Enter your weight (kg):', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                        SizedBox(height: 10),
                        _buildNeumorphicTextField(_weightController, "eg. 60.55", false),


                        // Activity Factor Selection
                        SizedBox(height: 40),
                        Text('Select your activity level:', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w900)),
                        SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, // Align items to take full width
                          children: activityFactors.keys.map((key) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20.0), // Space between buttons
                              child: _buildActivityFactorRadio(key, key), // Pass label and value
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 40),
                        // Save and Proceed Button
                        Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            onTap: () {
                              _saveUserData();
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
                                'Save & Proceed',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}