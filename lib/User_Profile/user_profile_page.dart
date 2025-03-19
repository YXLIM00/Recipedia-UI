import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_recipe/User_Profile/payment_page.dart';
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

  // List of available allergies preferences
  final List<String> allergyOptions = [
    "Dairy-Free",
    "Gluten-Free",
    "Red-Meat-Free",
    "Pork-Free",
    "Fish-Free",
    "Shellfish-Free",
    "Celery-Free",
    "Peanut-Free",
    "Vegetarian",
    "Vegan",
    "Alcohol-Free",
  ];

  bool _isPersonalInfoExpanded = false;
  bool _isHealthInfoExpanded = false;
  bool _isDietaryInfoExpanded = false;
  bool _isPremiumFeaturesExpanded = false;

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

  //---------------------Personal Information Section---------------------------

  // Gender
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

  //Age
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

  //Height
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

  //Weight
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

  //Activity Factor
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

  //---------------------Personal Information Section---------------------------


  //---------------------Health Information Section-----------------------------

  //Blood Glucose Level
  void _showBloodGlucoseLevelDialog(BuildContext context) {
    String? selectedLevel = userData?['blood_glucose_level']; // Store the current value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Blood Glucose Level"),
              content: SizedBox(
                height: 120, // Space for dropdown
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedLevel,
                        isExpanded: true,
                        items: ["High", "Normal", "Low"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLevel = newValue;
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
                    if (selectedLevel != null) {
                      await _updateBloodGlucoseLevel(selectedLevel!);
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
  Future<void> _updateBloodGlucoseLevel(String newLevel) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'blood_glucose_level': newLevel,
      });
      setState(() {
        userData?['blood_glucose_level'] = newLevel; // Update local UI state
      });
    }
  }

  //Blood Pressure Level
  void _showBloodPressureLevelDialog(BuildContext context) {
    String? selectedLevel = userData?['blood_pressure_level']; // Store current value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Blood Pressure Level"),
              content: SizedBox(
                height: 120, // Space for dropdown
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedLevel,
                        isExpanded: true,
                        items: ["High", "Normal", "Low"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLevel = newValue;
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
                    if (selectedLevel != null) {
                      await _updateBloodPressureLevel(selectedLevel!);
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
  Future<void> _updateBloodPressureLevel(String newLevel) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'blood_pressure_level': newLevel,
      });
      setState(() {
        userData?['blood_pressure_level'] = newLevel; // Update local UI state
      });
    }
  }

  //Blood Cholesterol Level
  void _showBloodCholesterolLevelDialog(BuildContext context) {
    String? selectedLevel = userData?['blood_cholesterol_level']; // Store current value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Blood Cholesterol Level"),
              content: SizedBox(
                height: 120, // Space for dropdown
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedLevel,
                        isExpanded: true,
                        items: ["High", "Normal"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLevel = newValue;
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
                    if (selectedLevel != null) {
                      await _updateBloodCholesterolLevel(selectedLevel!);
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
  Future<void> _updateBloodCholesterolLevel(String newLevel) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'blood_cholesterol_level': newLevel,
      });
      setState(() {
        userData?['blood_cholesterol_level'] = newLevel; // Update local UI state
      });
    }
  }

  //Diabetes
  void _showDiabetesDialog(BuildContext context) {
    String? selectedDiabetes = userData?['diabetes']; // Store current value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Diabetes Status"),
              content: SizedBox(
                height: 120, // Space for dropdown
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedDiabetes,
                        isExpanded: true,
                        items: ["Yes", "No"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedDiabetes = newValue;
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
                    if (selectedDiabetes != null) {
                      await _updateDiabetesStatus(selectedDiabetes!);
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
  Future<void> _updateDiabetesStatus(String newStatus) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'diabetes': newStatus,
      });
      setState(() {
        userData?['diabetes'] = newStatus; // Update local UI state
      });
    }
  }

  //---------------------Health Information Section-----------------------------


  //---------------------Dietary Information Section----------------------------

  //Diet Purpose
  void _showDietPurposeDialog(BuildContext context) {
    String? selectedPurpose = userData?['diet_purpose']; // Store current value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Diet Purpose"),
              content: SizedBox(
                height: 120, // Space for dropdown
                child: Column(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedPurpose,
                        isExpanded: true,
                        items: ["Maintain Health", "Gain Muscle", "Lose Weight"]
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPurpose = newValue;
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
                    if (selectedPurpose != null) {
                      await _updateDietPurpose(selectedPurpose!);
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
  Future<void> _updateDietPurpose(String newPurpose) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'diet_purpose': newPurpose,
      });
      setState(() {
        userData?['diet_purpose'] = newPurpose; // Update local UI state
      });
    }
  }

  //Allergies
  void _showAllergiesDialog(BuildContext context) {
    List<String> selectedAllergies = List<String>.from(userData?['allergies'] ?? []);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select Allergies"),
              content: SingleChildScrollView(
                child: Column(
                  children: allergyOptions.map((String allergy) {
                    return CheckboxListTile(
                      title: Text(allergy),
                      value: selectedAllergies.contains(allergy),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedAllergies.add(allergy);
                          } else {
                            selectedAllergies.remove(allergy);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), // Close dialog
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    await _updateUserAllergies(selectedAllergies);
                    Navigator.pop(dialogContext); // Close dialog
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
  Future<void> _updateUserAllergies(List<String> newAllergies) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'allergies': newAllergies,
      });
      setState(() {
        userData?['allergies'] = newAllergies; // Update local UI state
      });
    }
  }

  //---------------------Dietary Information Section----------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
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
                    // Personal Information Section Title
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
            SizedBox(height: 10),
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
                    // Health Information Section Title
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

                      // Blood Glucose Level Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Blood Glucose Level:  ${userData?['blood_glucose_level'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showBloodGlucoseLevelDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      // Blood Pressure Level Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Blood Pressure Level:  ${userData?['blood_pressure_level'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showBloodPressureLevelDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      // Blood Cholesterol Level Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Blood Cholesterol Level:  ${userData?['blood_cholesterol_level'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showBloodCholesterolLevelDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      // Diabetes Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Diabetes:  ${userData?['diabetes'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showDiabetesDialog(context);
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
        
            // Dietary Information Section
            SizedBox(height: 10),
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
                    // Dietary Information Section Title
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

                      // Diet Purpose Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Diet Purpose:  ${userData?['diet_purpose'] ?? 'Not available'}",
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              _showDietPurposeDialog(context);
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),

                      // Allergies Display & Edit
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align everything at the top
                        children: [
                          // "Allergies:" Text (Keeps it aligned with first tag)
                          Padding(
                            padding: EdgeInsets.only(top: 10.0), // Slightly adjust to align with the first tag
                            child: Text(
                              "Allergies:",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),

                          const SizedBox(width: 10), // Add small spacing between text and tags

                          // Wrap for Allergy Tags (Ensures they start from the first line)
                          Expanded(
                            child: Wrap(
                              spacing: 2.0, // Space between tags
                              runSpacing: 2.0, // Space between lines
                              children: [
                                if (userData?['allergies'] != null && (userData!['allergies'] as List).isNotEmpty)
                                  ...(userData!['allergies'] as List).map<Widget>((allergy) {
                                    return Chip(
                                      label: Text(allergy, style: TextStyle(color: Colors.white)), // Text color
                                      backgroundColor: Colors.redAccent[400], // Background color
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20), // Rounded corners
                                        side: BorderSide(color: Colors.red, width: 2), // Border color & thickness
                                      ),
                                    );

                                  }).toList()
                                else
                                  Text("None", style: TextStyle(fontSize: 16, color: Colors.black)),
                              ],
                            ),
                          ),

                          // Edit Button (Keeps it aligned with first row)
                          IconButton(
                            onPressed: () {
                              _showAllergiesDialog(context);
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

            // Premium Features Section
            SizedBox(height: 10),
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
                    // Section Title with Dropdown Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Premium Features 👑",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isPremiumFeaturesExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.indigo[400],
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPremiumFeaturesExpanded = !_isPremiumFeaturesExpanded;
                            });
                          },
                        ),
                      ],
                    ),

                    // Expanded Content
                    if (_isPremiumFeaturesExpanded) ...[
                      const SizedBox(height: 10),

                      // Premium Features List
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ListTile(
                            leading: Icon(Icons.lock_open_outlined, color: Colors.amber,),
                            title: Text("Dynamic UI with Animations"),
                          ),
                          ListTile(
                            leading: Icon(Icons.lock_open_outlined, color: Colors.amber,),
                            title: Text("Weekly Health Report Generation"),
                          ),
                          ListTile(
                            leading: Icon(Icons.lock_open_outlined, color: Colors.amber,),
                            title: Text("Priority Access to New Recipes"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Unlock Now Button
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentPage(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              // Gradient for the 3D look
                              gradient: LinearGradient(
                                colors: [Colors.amber.shade200, Colors.amber.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                // Adding shadows for a deeper 3D effect
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
                              'Unlock Now!',
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
