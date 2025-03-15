import 'package:flutter/material.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image_update.dart';
import 'package:fyp_recipe/Share_Services/background_image_container.dart';
import 'package:fyp_recipe/User_Registration/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_recipe/User_Registration/forgot_password.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage; //create function to toggle pages
  const LoginPage({super.key, required this.showRegisterPage}); //create the constructor that required function above

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //email & password text controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Validation messages
  String? emailError;
  String? passwordError;

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    RecipeImagePreloader.checkAndUpdateRecipeImages();
  }


  bool validateEmail(String email) {
    // Check if empty
    if (email.isEmpty) {
      setState(() {
        emailError = "Email cannot be empty!";
      });
      return false;
    }

    // Check the total length of the email
    if (email.length < 14) {
      setState(() {
        emailError = "Email must be at least 14 characters long!";
      });
      return false;
    } else if (email.length > 40) {
      setState(() {
        emailError = "Email cannot exceed 40 characters!";
      });
      return false;
    }

    // Validate email format, including domain and extension
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() {
        emailError = "Enter a valid email address! \n(eg. username@gmail.com)";
      });
      return false;
    }


    // Extract the part before the '@'
    String localPart = email.split('@')[0];

    // Validate the local part of the email
    if (localPart.length < 4) {
      setState(() {
        emailError = "The part before '@' must be at least 4 characters long!";
      });
      return false;
    } else if (localPart.length > 20) {
      setState(() {
        emailError = "The part before '@' cannot exceed 20 characters!";
      });
      return false;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+$').hasMatch(localPart)) {
      setState(() {
        emailError = "The part before '@' can only contain:\n"
            "- Letters (a -z, A - Z)\n"
            "- Numbers (0 - 9)\n"
            "- Special characters (., _, %, +, -)";
      });
      return false;
    }

    // If all validations pass
    setState(() {
      emailError = null;
    });
    return true;
  }

  bool validatePassword(String password) {
    if (password.isEmpty) {
      setState(() {
        passwordError = "Password cannot be empty!";
      });
      return false;
    }

    // Validate total length of the password
    if (password.length < 8) {
      setState(() {
        passwordError = "Password must be at least 8 characters!";
      });
      return false;
    } else if (password.length > 40) {
      setState(() {
        passwordError = "Password cannot exceed 40 characters!";
      });
      return false;
    }

    // Validate password format
    if (!RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@!%*?&])[A-Za-z\d@!%*?&]+$')
        .hasMatch(password)) {
      setState(() {
        passwordError = "Password must contain:\n"
            "- At least one uppercase letter (A - Z)\n"
            "- At least one lowercase letter (a - z)\n"
            "- At least one number (0 - 9)\n"
            "- At least one allowed special character\n  (@, !, %, *, ?, &)";
      });
      return false;
    }

    setState(() {
      passwordError = null;
    });
    return true;
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: BackgroundContainer(
          child: SafeArea(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Unfocus the text field and hide the keyboard when tapping outside
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Recipedia
                      const SizedBox(height: 50.0),
                      const Text(
                        'Recipedia',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                        ),
                      ),

                      //Cook Easy, Eat Healthy
                      const SizedBox(height: 10.0),
                      const Text(
                        'Cook Easy, Eat Healthy',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),

                      // Email TextField
                      const SizedBox(height: 50.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: emailError == null ? Colors.black : Colors.red,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Email',
                                    hintStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                                    counterText: "", // Removes the character counter display
                                  ),
                                  maxLength: 40, // Set maximum length
                                  onChanged: (value) => validateEmail(value),
                                ),
                              ),
                            ),
                            if (emailError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Text(
                                  emailError!,
                                  style: TextStyle(color: Colors.redAccent[400], fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Password TextField
                      const SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: passwordError == null ? Colors.black : Colors.red,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Password',
                                    hintStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                                    counterText: "", // Removes the character counter display
                                  ),
                                  maxLength: 40, // Set maximum length
                                  onChanged: (value) => validatePassword(value),
                                ),
                              ),
                            ),
                            if (passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Text(
                                  passwordError!,
                                  style: TextStyle(color: Colors.redAccent[400], fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),

                      //Forgot Password
                      const SizedBox(height: 10.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.cyanAccent,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //Login Button
                      const SizedBox(height: 40.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GestureDetector(
                          onTap: () {
                            final isValidEmail = validateEmail(emailController.text.trim());
                            final isValidPassword = validatePassword(passwordController.text.trim());

                            if (isValidEmail && isValidPassword) {
                              context.read<AuthBloc>().add(
                                LoginRequested(
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                ),
                              );
                            }
                          },

                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color:  Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      //Not a member yet? Register Now
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Not a member yet?  ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.showRegisterPage,
                            child: Text(
                              'Register Now',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.cyanAccent,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
