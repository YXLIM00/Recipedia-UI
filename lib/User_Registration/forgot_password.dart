import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/Share_Services/background_image_container.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  //email text controller
  final emailController = TextEditingController();
  String? emailError;

  //dispose controller
  @override
  void dispose(){
    emailController.dispose();
    super.dispose();
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

  Future passwordReset() async{
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      showDialog(
        context: context, builder: (context){
          return AlertDialog(
            content: Text("✅ Reset password link sent successfully! \n  Please check your email"),
          );
        }
      );//showDialog
    }
    on FirebaseAuthException catch (e){
     print(e);
     showDialog(
       context: context, builder: (context){
         return AlertDialog(
            content: Text(e.message.toString()),
         );
       }
     );//showDialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
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
                    //Forgot Password?
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),

                    //Guide Message
                    SizedBox(height: 50.0),
                    Text(
                      'We will send a reset password link to your email below:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    //Email Textfield
                    SizedBox(height: 10.0),
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

                    //Send Link Button
                    const SizedBox(height: 40.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: GestureDetector(
                        onTap: passwordReset, //call login function above
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'Send Link',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
