import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Events (represents actions taken)
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthState extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
}

class RegisterRequested extends AuthEvent {
  final String username, email, password;
  RegisterRequested(this.username, this.email, this.password);
}

class PasswordResetRequested extends AuthEvent {
  final String email;
  PasswordResetRequested(this.email);
}

class LogoutRequested extends AuthEvent {}

// States (represents results to be displayed)
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String role;
  AuthAuthenticated(this.user, this.role);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// BLoC (listen to events, emit states)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthState>(_onCheckAuthState);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthState(CheckAuthState event, Emitter<AuthState> emit) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final role = await _getUserRole(user.uid);
      emit(AuthAuthenticated(user, role));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email, password: event.password,
      );
      final role = await _getUserRole(userCredential.user!.uid);
      emit(AuthAuthenticated(userCredential.user!, role));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': event.username,
        'email': event.email,
        'role': 'user',
        'saved_recipes': [],
      });

      emit(AuthAuthenticated(userCredential.user!, 'user'));

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        emit(AuthError('This email is already registered.'));
      } else if (e.code == 'weak-password') {
        emit(AuthError('The password is too weak.'));
      } else if (e.code == 'network-request-failed') {
        emit(AuthError('Please check your internet connection.'));
      } else {
        emit(AuthError(e.message ?? 'Registration failed.'));
      }

    } catch (e) {
      emit(AuthError('An unexpected error occurred. Please try again later.'));
    }
  }


  Future<void> _onPasswordResetRequested(PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: event.email);
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(AuthUnauthenticated());
  }

  Future<String> _getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc['role'] ?? 'user';
  }
}
