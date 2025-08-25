import 'dart:convert';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod/riverpod.dart';

// Create the provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class Failure {
  final String message;
  Failure(this.message);
}

class AuthRepository {
  // Your actual API base URL from Postman
  static const String baseUrl = 'https://rebaturtechnologies.com/machinetest2/public/api';

  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Register user - ALWAYS uses form-data as per API requirement
  Future<Either<Failure, Map<String, dynamic>>> registerUser({

    required String email,
    required String name,
    required String password,
    required String passwordConfirmation,
    File? photo,
  }) async {
    try {
      final String endpoint = '$baseUrl/register';

      print('🔗 API URL: $endpoint');
      print('📤 Request Data: {email: $email}');

      // Use multipart/form-data
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields.addAll({
        "name":name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      // Add file if provided
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
      }

      print('📤 Sending multipart/form-data request...');
      print('📤 Fields: ${request.fields}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        print("${response.body} hiiiiiiiiiiiiiiiiiii");
        return Left(Failure('API endpoint error. Please check your API URL.'));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Right(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Registration failed';
        return Left(Failure(errorMessage));
      }
    } catch (e) {
      return Left(Failure('Network error: $e'));
    }
  }


  // Login user - Uses form-data as per Postman collection
  Future<Either<Failure, Map<String, dynamic>>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final String endpoint = '$baseUrl/login';

      print('🔗 Login API URL: $endpoint');
      print('📤 Login Data: {email: $email}');

      // Use multipart/form-data as shown in Postman
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Add headers as per Postman collection
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json', // This is in your Postman but form-data overrides it
      });

      // Add form fields
      request.fields.addAll({
        'email': email,
        'password': password,
      });

      print('📤 Sending form-data login request...');
      print('📤 Fields: ${request.fields}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Login Response Status: ${response.statusCode}');
      print('📥 Login Response Body: ${response.body}');

      // Check if response is HTML
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        return Left(Failure('API endpoint error. Please check your API URL.'));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Save auth token and user data
        if (data.containsKey('token') || data.containsKey('access_token')) {
          final token = data['token'] ?? data['access_token'];
          await _saveAuthToken(token.toString());
        }

        if (data.containsKey('user')) {
          await _saveUserData(data['user']);
        }

        print('✅ Login successful');
        return Right(data);
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Login failed';
          return Left(Failure(errorMessage));
        } catch (e) {
          return Left(Failure('Login failed with status ${response.statusCode}'));
        }
      }

    } catch (e) {
      print('❌ Login Network Error: $e');
      return Left(Failure('Network error: Please check your internet connection'));
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  // Logout user
  Future<void> logOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  // Private helper methods
  Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('✅ Auth token saved');
    } catch (e) {
      print('❌ Error saving auth token: $e');
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
      print('✅ User data saved');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }
}