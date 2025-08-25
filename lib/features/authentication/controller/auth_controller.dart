import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rebatur_machine_test/features/authentication/screen/login_page.dart';
import 'package:rebatur_machine_test/features/students/screen/student_listing.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/common/common_snack_bar.dart';
import '../repository/auth_repository.dart';


final authControllerProvider = NotifierProvider<AuthController, bool>(() => AuthController());

class AuthController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  // Register user
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    File? photo,
    required BuildContext context,
  }) async {
    state = true;

    final result = await _authRepository.registerUser(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      photo: photo,
    );

    Future.delayed(const Duration(seconds: 2), () {
      state = false;
    });

    result.fold(
          (failure) {
            print("${failure.message} kooooooooooooooooooooi");
            return snackBar(context, failure.message);

          },
          (response) {
        snackBar(context, 'Registration successful! Please login.');
        if (context.mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          });
        }
      },
    );
  }

  // Login user
  Future<void> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = true;

    final result = await _authRepository.loginUser(
      email: email,
      password: password,
    );

    Future.delayed(const Duration(seconds: 2), () {
      state = false;
    });

    result.fold(
          (failure) => snackBar(context, failure.message),
          (response) async {
        snackBar(context, 'Login successful!');

        // You can update user state here if you have a user provider
        // ref.read(userProvider.notifier).update((state) => userModel);

        if (context.mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) =>  StudentListingPage()),
                  (route) => false,
            );
          });
        }
      },
    );
  }

  // Check if user is logged in
  Future<bool> checkAuthStatus() async {
    return await _authRepository.isLoggedIn();
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _authRepository.getUserData();
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    return await _authRepository.getAuthToken();
  }

  // Logout user
  void logOut(BuildContext context) {
    _authRepository.logOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }
}