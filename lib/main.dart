import 'package:flutter/material.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image_update.dart';
import 'package:fyp_recipe/User_Registration/auth_state_change.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_recipe/User_Registration/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  RecipeImagePreloader.checkAndUpdateRecipeImages();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(CheckAuthState()),
        ),
        // Add other BLoCs here in the future if needed
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Poppins'),
        home: const AuthStateChange(),
      ),
    );
  }
}
