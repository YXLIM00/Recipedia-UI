import 'package:flutter/material.dart';
import 'package:fyp_recipe/User_Registration/login.dart';
import 'package:fyp_recipe/User_Registration/register.dart';

class PageToggle extends StatefulWidget {
  const PageToggle({super.key});

  @override
  State<PageToggle> createState() => _PageToggleState();
}

class _PageToggleState extends State<PageToggle> {
  //initially show the login page
  bool showLoginPage = true;

  void toggleScreen(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(showLoginPage){
      return LoginPage(showRegisterPage: toggleScreen);
    }
    else{
      return RegisterPage(showLoginPage: toggleScreen);
    }
  }
}
