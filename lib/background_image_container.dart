import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/uibackground.jpg'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.6), // Dark overlay with transparency
          ),
          child, // Content of each page
        ],
      ),
    );
  }
}
