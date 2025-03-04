import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:fyp_recipe/Share_Services/user_bottom_nav_bar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;

  final Map<String, double> activityFactors = {
    "Sedentary \n(little or no exercise)": 1.2,
    "Lightly Active \n(exercise 1-3 days/week)": 1.375,
    "Moderately Active \n(exercise 3-5 days/week)": 1.55,
    "Highly Active \n(exercise 6-7 days/week)": 1.725,
    "Extremely Active \n(athlete training/heavy physical job)": 1.9,
  };
  
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

  void _showGenderSelectionDialog(BuildContext context) {
    String? selectedGender = userData?['sex']; // Store the current value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Gender"),
              content: SizedBox(
                height: 120, // Increase height to provide space for dropdown
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedGender,
                        isExpanded: true,
                        items: ["Male", "Female"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGender = newValue; // Update selected value
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 50,
                          width: double.infinity,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200, // Allow dropdown to expand fully downward
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), // Close dialog
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedGender != null) {
                      await _updateUserGender(selectedGender!);
                      Navigator.pop(dialogContext); // Close dialog
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _updateUserGender(String newGender) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'sex': newGender,
      });
      setState(() {
        userData?['sex'] = newGender; // Update local UI state
      });
    }
  }

  void _showAgeInputDialog(BuildContext context) {
    TextEditingController ageController = TextEditingController(
      text: userData?['age']?.toString() ?? '',
    );

    String errorMessage = ''; // Initialize the error message state

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Enter Your Age"),
              content: SizedBox(
                height: 120, // Increased height to fit multiline error message
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number, // Only allow number input
                      decoration: InputDecoration(
                        hintText: "Enter your age",
                      ),
                    ),
                    const SizedBox(height: 8), // Add some space between text field and error
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                        maxLines: null, // Allow unlimited lines
                        overflow: TextOverflow.visible, // Ensure full display of the message
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), // Close dialog
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    String ageInput = ageController.text.trim();

                    // Validation for empty input
                    if (ageInput.isEmpty) {
                      setState(() {
                        errorMessage = "Age cannot be empty!\nPlease enter a valid age without any decimal places. (eg. 18)";
                      });
                    }
                    // Validation for non-integer input
                    else if (!RegExp(r'^\d+$').hasMatch(ageInput)) {
                      setState(() {
                        errorMessage = "Please enter a valid whole number for age. (eg. 18)";
                      });
                    }
                    // Validation for age range
                    else {
                      int age = int.parse(ageInput);
                      if (age < 1 || age > 120) {
                        setState(() {
                          errorMessage = "Please enter an age between 1 and 120.";
                        });
                      } else {
                        // Valid age input
                        await _updateUserAge(age);
                        Navigator.pop(dialogContext); // Close dialog after successful update
                      }
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _updateUserAge(int newAge) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'age': newAge,
      });
      setState(() {
        userData?['age'] = newAge; // Update local UI state
      });
    }
  }

  void _showHeightInputDialog(BuildContext context) {
    TextEditingController heightController = TextEditingController(
      text: userData?['height']?.toString() ?? '',
    );

    String errorMessage = ''; // Initialize the error message state

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Enter Your Height (cm)"),
              content: SizedBox(
                height: 120, // Increased height for better space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimals
                      decoration: InputDecoration(
                        hintText: "Enter your height (e.g., 170.5)",
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                        maxLines: null, // Allow unlimited lines
                        overflow: TextOverflow.visible, // Ensure full message display
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), // Close dialog
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    String heightInput = heightController.text.trim();

                    // Validation for empty input
                    if (heightInput.isEmpty) {
                      setState(() {
                        errorMessage = "Height cannot be empty!\nPlease enter a valid height in centimeters. (e.g., 170.5)";
                      });
                    }
                    // Validation for non-decimal input (allow up to 2 decimal places)
                    else if (!RegExp(r'^\d{1,3}(\.\d{1,2})?$').hasMatch(heightInput)) {
                      setState(() {
                        errorMessage = "Please enter a valid height with up to 2 decimal places. (e.g., 170.5)";
                      });
                    }
                    // Validation for height range
                    else {
                      double height = double.parse(heightInput);
                      if (height < 50 || height > 220) {
                        setState(() {
                          errorMessage = "Please enter a height between 50.00 cm and 220.00 cm.";
                        });
                      } else {
                        // Valid height input
                        await _updateUserHeight(height);
                        Navigator.pop(dialogContext); // Close dialog after successful update
                      }
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _updateUserHeight(double newHeight) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'height': newHeight,
      });
      setState(() {
        userData?['height'] = newHeight; // Update local UI state
      });
    }
  }

  void _showWeightInputDialog(BuildContext context) {
    TextEditingController weightController = TextEditingController(
      text: userData?['weight']?.toString() ?? '',
    );

    String errorMessage = ''; // Initialize the error message state

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Enter Your Weight (kg)"),
              content: SizedBox(
                height: 120, // Increased height for better space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimals
                      decoration: InputDecoration(
                        hintText: "Enter your weight (e.g., 70.5)",
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                        maxLines: null, // Allow unlimited lines
                        overflow: TextOverflow.visible, // Ensure full message display
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), // Close dialog
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    String weightInput = weightController.text.trim();

                    // Validation for empty input
                    if (weightInput.isEmpty) {
                      setState(() {
                        errorMessage = "Weight cannot be empty!\nPlease enter a valid weight in kilograms. (e.g., 70.5)";
                      });
                    }
                    // Validation for non-decimal input (allow up to 2 decimal places)
                    else if (!RegExp(r'^\d{1,3}(\.\d{1,2})?$').hasMatch(weightInput)) {
                      setState(() {
                        errorMessage = "Please enter a valid weight with up to 2 decimal places. (e.g., 70.5)";
                      });
                    }
                    // Validation for weight range
                    else {
                      double weight = double.parse(weightInput);
                      if (weight < 20 || weight > 250) {
                        setState(() {
                          errorMessage = "Please enter a weight between 20.00 kg and 250.00 kg.";
                        });
                      } else {
                        // Valid weight input
                        await _updateUserWeight(weight);
                        Navigator.pop(dialogContext); // Close dialog after successful update
                      }
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _updateUserWeight(double newWeight) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'weight': newWeight,
      });
      setState(() {
        userData?['weight'] = newWeight; // Update local UI state
      });
    }
  }

  String _getActivityFactorDescription(double? factor) {
    if (factor == null) return "Not available"; // Handle null case

    return activityFactors.entries
        .firstWhere(
          (entry) => entry.value == factor,
      orElse: () => MapEntry("Unknown", 0.0),
    )
        .key; // Return the description
  }
  void _showActivityFactorSelectionDialog(BuildContext context) {
    String? selectedDescription = activityFactors.entries
        .firstWhere(
          (entry) => entry.value == userData?['activity_factor'],
      orElse: () => MapEntry("Sedentary \n(little/no exercise)", 1.2),
    )
        .key;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Activity Factor"),
              content: SizedBox(
                height: 200, // Increased height for better dropdown visibility
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedDescription,
                        isExpanded: true,
                        items: activityFactors.keys.map((String description) {
                          return DropdownMenuItem<String>(
                            value: description,
                            child: Container(
                              width: double.infinity, // Ensures full-width wrapping
                              child: Text(
                                description,
                                softWrap: true, // Enables line breaks
                                maxLines: 3, // Adjust to allow full display
                                overflow: TextOverflow.visible, // Prevents truncation
                                style: TextStyle(fontSize: 14), // Adjust font size if needed
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newDescription) {
                          setState(() {
                            selectedDescription = newDescription;
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 50,
                          width: double.infinity,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 250, // Increased dropdown height
                        ),
                        menuItemStyleData: MenuItemStyleData(
                          height: 60, // Allow more space for each item
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedDescription != null) {
                      double selectedFactor = activityFactors[selectedDescription]!;
                      await _updateUserActivityFactor(selectedFactor);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _updateUserActivityFactor(double newFactor) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'activity_factor': newFactor, // Store the numerical value
      });
      setState(() {
        userData?['activity_factor'] = newFactor; // Update local UI state
      });
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
            // Page Title
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
                    // Personal Information Text
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
                      //Sex Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Sex:  ${userData?['sex'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showGenderSelectionDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      //Age Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Age:  ${userData?['age'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showAgeInputDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      //Height Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Height:  ${userData?['height'] ?? 'Not available'} cm",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showHeightInputDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      //Weight Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Weight:  ${userData?['weight'] ?? 'Not available'} kg",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showWeightInputDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      // Activity Factor Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Activity Factor: ${_getActivityFactorDescription(userData?['activity_factor'])}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showActivityFactorSelectionDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
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
