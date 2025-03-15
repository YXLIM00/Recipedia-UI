import 'package:flutter/material.dart';
import 'package:fyp_recipe/Edamam_Services/edamam_recipe_image_update.dart';
import 'package:fyp_recipe/Share_Services/background_image_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_recipe/User_Registration/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage; //create function to toggle pages
  const RegisterPage({super.key, required this.showLoginPage}); //create the constructor that required function above

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //email & password & confirm password text controller
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Validation messages
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  @override
  void dispose(){
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    RecipeImagePreloader.checkAndUpdateRecipeImages();
  }


  bool validateUsername(String username) {
    if (username.isEmpty) {
      setState(() {
        usernameError = "Username cannot be empty!";
      });
      return false;
    } else if (username.length < 4) {
      setState(() {
        usernameError = "Username must be at least 4 characters long!";
      });
      return false;
    } else if (username.length > 40) {
      setState(() {
        usernameError = "Username cannot exceed 40 characters!";
      });
      return false;
    }
    setState(() {
      usernameError = null;
    });
    return true;
  }


  Future<bool> validateEmail(String email) async {
    if (email.isEmpty) {
      setState(() {
        emailError = "Email cannot be empty!";
      });
      return false;
    }

    // Check total length of the email
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
            "- Letters (a - z, A - Z)\n"
            "- Numbers (0 - 9)\n"
            "- Special characters (. _ % + -)";
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


  bool validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      setState(() {
        confirmPasswordError = "Confirm password cannot be empty!";
      });
      return false;
    } else if (confirmPassword != passwordController.text) {
      setState(() {
        confirmPasswordError = "Passwords do not match!";
      });
      return false;
    } else if (confirmPassword.length > 40) { // Add length validation
      setState(() {
        confirmPasswordError = "Password cannot exceed 40 characters!";
      });
      return false;
    }

    setState(() {
      confirmPasswordError = null;
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
                      //Welcome!
                      const SizedBox(height: 50.0),
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                        ),
                      ),
      
                      //Register your details below
                      const SizedBox(height: 10.0),
                      const Text(
                        'Register your details below',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
      
                      // Username TextField
                      _buildTextField(
                        label: 'Username',
                        controller: usernameController,
                        errorText: usernameError,
                        validator: validateUsername,
                      ),
                      // Email TextField
                      _buildTextField(
                        label: 'Email',
                        controller: emailController,
                        errorText: emailError,
                        validator: validateEmail,
                      ),
                      // Password TextField
                      _buildTextField(
                        label: 'Password',
                        controller: passwordController,
                        errorText: passwordError,
                        validator: validatePassword,
                        isObscure: true,
                      ),
                      // Confirm Password TextField
                      _buildTextField(
                        label: 'Confirm Password',
                        controller: confirmPasswordController,
                        errorText: confirmPasswordError,
                        validator: validateConfirmPassword,
                        isObscure: true,
                      ),
      
                      //Register Button
                      const SizedBox(height: 40.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GestureDetector(
                          onTap: () {
                            final isValidUsername = validateUsername(usernameController.text.trim());
                            final isValidEmail = emailError == null;
                            final isValidPassword = validatePassword(passwordController.text.trim());
                            final isValidConfirmPassword = validateConfirmPassword(confirmPasswordController.text.trim());
      
                            if (isValidUsername && isValidEmail && isValidPassword && isValidConfirmPassword) {
                              context.read<AuthBloc>().add(
                                RegisterRequested(
                                  usernameController.text.trim(),
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
                                  'Register',
                                  style: TextStyle(
                                    color:  Colors.black,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
      
                      //Already a member? Login Now
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already a member?  ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.showLoginPage,
                            child: Text(
                              'Login Now',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? errorText,
    required Function(String) validator,
    bool isObscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: errorText == null ? Colors.black : Colors.red,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: TextField(
                controller: controller,
                obscureText: isObscure,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: label,
                  hintStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                  counterText: "", // Removes the character counter display
                ),
                maxLength: 40,
                onChanged: validator,
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                errorText,
                style: TextStyle(color: Colors.redAccent[400], fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

}


