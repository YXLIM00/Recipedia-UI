import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_recipe/Recommendation/user_info_collect_firstpage.dart';
import 'package:fyp_recipe/User_Registration/page_toggle.dart';
import 'package:fyp_recipe/Admin/admin_homepage.dart';

class AuthStateChange extends StatelessWidget {
  const AuthStateChange({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      print('Fetching role for user: $uid'); // Print UID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final role = data?['role'] as String?;
        if (role != null) {
          print('User role found: $role');
          return role;
        } else {
          print('Role field is missing in the document');
        }
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching role: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            User user = snapshot.data!;
            print('Current User UID: ${user.uid}'); // Print the current user's UID

            // Fetch user role using FutureBuilder
            return FutureBuilder<String?>(
              future: getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final role = roleSnapshot.data;
                if (role == 'admin') {
                  return const AdminHomePage(); // Navigate to AdminHomePage
                } else if (role == 'user') {
                  return const UserInfoPage1(); // Navigate to UserHomePage
                } else {
                  return const Center(child: Text('Error: Role not recognized'));
                }
              },
            );
          } else {
            return const PageToggle(); // User is not logged in
          }
        },
      ),
    );
  }
}
