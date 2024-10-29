import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/background_image_container.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  //email text controller
  final emailController = TextEditingController();

  //dispose controller
  @override
  void dispose(){
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async{
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      showDialog(
        context: context, builder: (context){
          return AlertDialog(
            content: Text("Reset password link sent successfully! Please check your email"),
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
        iconTheme: IconThemeData(color: Colors.greenAccent[400]),
      ),
      body: BackgroundContainer(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Forgot Password?
              SizedBox(height: 50.0),
              Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              //Guide Message
              SizedBox(height: 15.0),
              Text(
                'Enter your email and we will send you a reset password link',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              //Email Textfield
              SizedBox(height: 15.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Email',
                      ),
                    ),
                  ),
                ),
              ),

              //Reset Password Button
              SizedBox(height: 15.0),
              MaterialButton(
                onPressed: passwordReset,
                child: Text(
                  'Reset Password'
                ),
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
