import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_recipe/Recommendation/user_info_collect_firstpage.dart';
import 'package:fyp_recipe/User_Registration/page_toggle.dart';
import 'package:fyp_recipe/Admin/admin_homepage.dart';
import 'auth_bloc.dart';

class AuthStateChange extends StatelessWidget {
  const AuthStateChange({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger CheckAuthState when this page builds
    context.read<AuthBloc>().add(CheckAuthState());

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AuthAuthenticated) {
              if (state.role == 'admin') {
                return const AdminHomePage();
              } else if (state.role == 'user') {
                return const UserInfoPage1();
              } else {
                return const Center(child: Text('Error: Role not recognized'));
              }
            } else if (state is AuthUnauthenticated) {
              return const PageToggle();
            }
            // Show an error if an unexpected state occurs
            return const Center(child: Text('Unexpected State'));
          },
        ),
      ),
    );
  }
}

