import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rebatur_machine_test/core/local_variable.dart';
import 'package:rebatur_machine_test/features/authentication/screen/user_registration.dart';

import '../../../core/custom_widget/custom_textform_field.dart';
import '../../../core/theme/color_constant.dart';
import '../controller/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstant.blue,
            ColorConstant.red,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _validateInputs() {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return false;
    }

    return true;
  }

  void _handleLogin() {
    if (!_validateInputs()) return;

    // Call the loginUser function from AuthController
    ref.read(authControllerProvider.notifier).loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      context: context,
    );
  }

  void _handleClear() {
    emailController.clear();
    passwordController.clear();
  }

  void _navigateToRegistration() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage(),)); // Adjust route name as needed
    // Or use: Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegistrationPage()));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: ColorConstant.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: height*0.45,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
            
                        // Email TextField
                        CustomTextField(
                          controller: emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
            
                        // Password TextField with visibility toggle
                        CustomTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          isPassword: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
            
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
            
                // Login and Clear Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        text: 'Login',
                        color: ColorConstant.blue,
                        onPressed: _handleLogin,
                        isLoading: isLoading,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildButton(
                        text: 'Clear',
                        color: ColorConstant.red,
                        onPressed: _handleClear,
                        isLoading: false,
                      ),
                    ),
                  ],
                ),
            
                const SizedBox(height: 20),
            
                // Registration Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToRegistration,
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstant.blue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
            
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}