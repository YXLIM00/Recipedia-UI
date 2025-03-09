import 'package:cloud_firestore/cloud_firestore.dart';

class UserDietaryRecommendation {
  final String userId;

  UserDietaryRecommendation({required this.userId});

  Future<void> calculateAndStoreData() async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Fetch user data
      final userDoc = await userRef.get();
      if (!userDoc.exists) throw Exception("User document not found for userId: $userId");

      final userData = userDoc.data()!;
      final double weight = userData['weight']?.toDouble() ?? 0.0;
      final double height = userData['height']?.toDouble() ?? 0.0;
      final int age = userData['age']?.toInt() ?? 0;
      final String sex = userData['sex'] ?? '';
      final double activityFactor = userData['activity_factor']?.toDouble() ?? 1.0;

      if (weight <= 0 || height <= 0 || age <= 0 || sex.isEmpty) {
        throw Exception("Invalid or missing user data for calculations");
      }

      // Calculate BMR, TDEE, and BMI
      double bmr = sex.toLowerCase() == 'male'
          ? (10 * weight) + (6.25 * height) - (5 * age) + 5
          : (10 * weight) + (6.25 * height) - (5 * age) - 161;
      double tdee = bmr * activityFactor;
      double bmi = weight / ((height / 100) * (height / 100));

      // Adjust TDEE based on BMI
      String bmiStatus;
      if (bmi < 18.5) {
        bmiStatus = "Underweight";
        tdee += 300;
      } else if (bmi >= 18.5 && bmi <= 24.9) {
        bmiStatus = "Healthy Weight";
      } else if (bmi >= 25.0 && bmi <= 29.9) {
        bmiStatus = "Overweight";
        tdee -= 300;
      } else {
        bmiStatus = "Obesity";
        tdee -= 600;
      }

      // Round and update Firestore
      await userRef.update({
        'recommended_calories_intake': double.parse(tdee.toStringAsFixed(2)),
        'current_bmi': double.parse(bmi.toStringAsFixed(2)),
        'current_bmi_status': bmiStatus,
      });

      print('Dietary recommendation successfully updated for user $userId');
    } catch (e) {
      print('Error updating dietary recommendation: $e');
    }
  }

  Future<void> customizeLabels() async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Fetch user data
      final userDoc = await userRef.get();
      if (!userDoc.exists) throw Exception("User document not found for userId: $userId");

      final userData = userDoc.data()!;
      final String bloodGlucose = userData['blood_glucose_level'] ?? 'normal';
      final String bloodPressure = userData['blood_pressure_level'] ?? 'normal';
      final String bloodCholesterol = userData['blood_cholesterol_level'] ?? 'normal';
      final String diabetes = userData['diabetes'] ?? 'no';
      final String dietPurpose = userData['diet_purpose'] ?? '';
      final List<String> allergiesPreferences =
      List<String>.from(userData['allergies_preferences'] ?? []);

      List<String> customDietLabels = [];
      List<String> customHealthLabels = [];
      List<String> customHarmfulFood = [];
      List<String> customHelpfulFood = [];
      List<String> customCautions = [];

      // Add labels based on conditions
      if (bloodGlucose.toLowerCase() == "high" || bloodGlucose.toLowerCase() == "low") {
        customDietLabels.add("Low-Carb");
        customHealthLabels.addAll(["Alcohol-Free", "Sugar-Conscious"]);
        customHarmfulFood.addAll([
          "Refined Carbs \n(white bread, white rice, pasta made of flour, breakfast cereals)",
          "Fried Food \n(generally fast food)",
          "Processed Meats \n(ham, bacon, sausage, lunch meat)",
          "Sugary Beverages and Snacks \n(including fruit juice)",
          "Sweetened Products"
        ]);
        customHelpfulFood.addAll([
          "Whole Grains \n(wheat bread, brown rice, wheat pasta, oats)",
          "Lean Proteins \n(fish, chicken, tofu)",
          "Fruits and Vegetables"
        ]);
      }
      if(bloodGlucose.toLowerCase() == "low"){
        customCautions.addAll([
          "Eat small meals/snacks every 3 hours.",
          "Always prepare fast-acting carbohydrates (eg. honey sticks, glucose tablets/gels) in case hypoglycemia symptoms occurs."
        ]);
      }


      if (bloodPressure.toLowerCase() == "high") {
        customDietLabels.add("Low-Sodium");
        customHealthLabels.addAll(["Alcohol-Free", "Sugar-Conscious", "Dairy-Free", "Red-Meat-Free"]);
        customHarmfulFood.addAll([
          "Fried Food \n(generally fast food)",
          "Processed Meats \n(ham, bacon, sausage, lunch meat)",
          "Saturated Oil \n(palm oil, coconut oil, butter, margarine)",
          "Sugary Beverages and Snacks \n(including fruit juice)",
          "Sweetened Products",
          "Caffeine"
        ]);
        customHelpfulFood.addAll([
          "Whole Grains \n(wheat bread, brown rice, wheat pasta, oats)",
          "Lean Proteins \n(fish, chicken, tofu)",
          "Plant Oils \n(olive oil, canola oil, flaxseed oil, sunflower oil)",
          "Fruits and Vegetables"
        ]);
      } else if (bloodPressure.toLowerCase() == "low") {
        customDietLabels.add("Low-Carb");
        customHealthLabels.addAll(["Alcohol-Free", "Sugar-Conscious"]);
        customHarmfulFood.addAll([
          "Refined Carbs \n(white bread, white rice, pasta made of flour, breakfast cereals)",
          "Sugary Beverages and Snacks \n(including fruit juice)",
          "Sweetened Products",
          "Caffeine"
        ]);
        customHelpfulFood.addAll([
          "Whole Grains \n(wheat bread, brown rice, wheat pasta, oats)",
          "Lean Proteins \n(fish, chicken, tofu)",
          "Fruits and Vegetables",
        ]);
        customCautions.addAll([
          "Eat small meals/snacks every 3 hours.",
          "Avoid large meals to prevent sudden drop of blood pressure.",
          "Avoid sudden standing up or sudden postural change.",
          "Avoid standing still for a long period of time."
        ]);
      }


      if (bloodCholesterol.toLowerCase() == "high") {
        customDietLabels.add("High-Fiber");
        customHealthLabels.addAll(["Dairy-Free", "Egg-Free", "Red-Meat-Free", "Shellfish-Free"]);
        customHarmfulFood.addAll([
          "Fried Food \n(generally fast food)",
          "Organ Meats \n(heart, liver, kidney)",
          "Processed Meats \n(ham, bacon, sausage, lunch meat)",
          "Snacks Desserts \n(baked goods, cookies, cakes, ice cream)",
          "Saturated Oil \n(palm oil, coconut oil, butter, margarine)"
        ]);
        customHelpfulFood.addAll([
          "Whole Grains \n(wheat bread, brown rice, wheat pasta, oats)",
          "Oily Fish with Healthy Fat \n(salmon, sardines, mackerel, tuna)",
          "Fruits and Vegetables \n(berries, avocados)",
          "Nuts \n(almonds, walnuts, chia seeds)",
          "Plant Oils \n(olive oil, canola oil, flaxseed oil, sunflower oil)"
        ]);
      }


      if (diabetes.toLowerCase() == "yes") {
        customDietLabels.addAll(["Low-Carb", "Low-Sodium"]);
        customHealthLabels.addAll(["Dairy-Free", "Egg-Free", "Gluten-Free", "Red-Meat-Free", "Pork-Free", "Alcohol-Free", "Sugar-Conscious"]);
        customHarmfulFood.addAll([
          "Refined Carbs \n(white bread, white rice, pasta made of flour, breakfast cereals)",
          "Fried Food \n(generally fast food)",
          "Processed Meats \n(ham, bacon, sausage, lunch meat)",
          "Sugary Beverages and Snacks \n(including fruit juice)",
          "Sweetened Products"
        ]);
        customHelpfulFood.addAll([
          "Whole Grains \n(wheat bread, brown rice, wheat pasta, oats)",
          "Lean Proteins \n(fish, chicken, tofu)",
          "Fruits and Vegetables"
        ]);
      }


      if (dietPurpose.toLowerCase() == "maintain health" &&
          bloodGlucose.toLowerCase() == "normal" &&
          bloodPressure.toLowerCase() == "normal" &&
          bloodCholesterol.toLowerCase() == "normal" &&
          diabetes.toLowerCase() == "no") {
        customDietLabels.add("Balanced");
      } else if (dietPurpose.toLowerCase() == "gain muscle") {
        customDietLabels.add("High-Protein");
      } else if (dietPurpose.toLowerCase() == "lose weight") {
        customDietLabels.addAll(["High-Protein", "High-Fiber", "Low-Carb"]);
      }

      // Add allergies/preferences to health labels
      customHealthLabels.addAll(allergiesPreferences);

      // Ensure no duplicates
      customDietLabels = customDietLabels.toSet().toList();
      customHealthLabels = customHealthLabels.toSet().toList();
      customHarmfulFood = customHarmfulFood.toSet().toList();
      customHelpfulFood = customHelpfulFood.toSet().toList();
      customCautions = customCautions.toSet().toList();

      // Update Firestore
      await userRef.update({
        'custom_dietLabels': customDietLabels,
        'custom_healthLabels': customHealthLabels,
        'custom_harmful_food': customHarmfulFood,
        'custom_helpful_food': customHelpfulFood,
        'custom_cautions': customCautions,
      });

      print('Custom labels successfully updated for user $userId');
    } catch (e) {
      print('Error updating custom labels: $e');
    }
  }
}
