import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/failure.dart';
import '../../../model/student_model.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) => StudentRepository());

class StudentRepository {
  static const String baseUrl = 'https://rebaturtechnologies.com/machinetest2/public/api';

  // Get auth token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get all students
  Future<Either<Failure, List<Student>>> getStudents() async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Assuming the API returns students in a 'data' field
        final List<dynamic> studentsJson = responseData['data'] ?? responseData['students'] ?? [];

        final List<Student> students = studentsJson
            .map((json) => Student.fromJson(json))
            .toList();

        return Right(students);
      } else if (response.statusCode == 401) {
        return Left(Failure('Unauthorized. Please login again.'));
      } else {
        final errorData = json.decode(response.body);
        return Left(Failure(errorData['message'] ?? 'Failed to fetch students'));
      }
    } catch (e) {
      return Left(Failure('Network error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<String>>> getClasses() async {
    try {
      print('StudentRepository: Starting getClasses API call');

      final String? authToken = await _getAuthToken();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/classes'),
        headers: headers,
      );

      print('StudentRepository: API Response Status: ${response.statusCode}');
      print('StudentRepository: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> classesData = data['data'];

          final List<String> classes = classesData.map((classItem) {
            return classItem['name'].toString();
          }).toList();

          print('StudentRepository: Successfully parsed ${classes.length} classes');
          return Right(classes);
        } else {
          print('StudentRepository: API returned success=false or null data');
          return Left(Failure('Failed to fetch classes: Invalid response format'));
        }
      } else if (response.statusCode == 401) {
        print('StudentRepository: Unauthorized - Token might be expired or invalid');
        return Left(Failure('Authentication failed. Please login again.'));
      } else {
        print('StudentRepository: API returned status code: ${response.statusCode}');
        return Left(Failure('Failed to fetch classes: HTTP ${response.statusCode}'));
      }
    } catch (e) {
      print('StudentRepository: Exception in getClasses: $e');
      return Left(Failure('Failed to fetch classes: $e'));
    }
  }

  // Get single student by ID
  Future<Either<Failure, Student>> getStudent(int id) async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Student student = Student.fromJson(responseData['data'] ?? responseData);

        return Right(student);
      } else if (response.statusCode == 401) {
        return Left(Failure('Unauthorized. Please login again.'));
      } else if (response.statusCode == 404) {
        return Left(Failure('Student not found'));
      } else {
        final errorData = json.decode(response.body);
        return Left(Failure(errorData['message'] ?? 'Failed to fetch student'));
      }
    } catch (e) {
      return Left(Failure('Network error: ${e.toString()}'));
    }
  }

  // Create new student with subjects and photo
  Future<Either<Failure, Student>> createStudent({
    required String name,
    required String phone,
    required String className,
    required List<String> subjects,
    File? photo,
  }) async {
    try {
      final token = await _getAuthToken();

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/students'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['class'] = className;

      // Add subjects as indexed array
      for (int i = 0; i < subjects.length; i++) {
        request.fields['subjects[$i]'] = subjects[i];
      }

      // Add photo if provided
      if (photo != null) {
        var photoFile = await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          filename: 'student_photo.jpg',
        );
        request.files.add(photoFile);
      }

      print('StudentRepository: Sending request with fields: ${request.fields}');
      print('StudentRepository: Files count: ${request.files.length}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('StudentRepository: Response status: ${response.statusCode}');
      print('StudentRepository: Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Student student = Student.fromJson(responseData['data'] ?? responseData);

        return Right(student);
      } else if (response.statusCode == 401) {
        return Left(Failure('Unauthorized. Please login again.'));
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        final errors = errorData['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first as List;
          return Left(Failure(firstError.first.toString()));
        }
        return Left(Failure('Validation failed'));
      } else {
        final errorData = json.decode(response.body);
        return Left(Failure(errorData['message'] ?? 'Failed to create student'));
      }
    } catch (e) {
      print('StudentRepository: Exception in createStudent: $e');
      return Left(Failure('Network error: ${e.toString()}'));
    }
  }

  // Update student with multipart form data (supporting photo upload)
  Future<Either<Failure, Student>> updateStudent({
    required int id,
    required String name,
    required String phone,
    required String className,
    required List<String> subjects,
    File? photo,
  }) async {
    try {
      final token = await _getAuthToken();

      print('StudentRepository: Starting updateStudent for ID: $id');
      print('StudentRepository: Name: $name, Phone: $phone, Class: $className');
      print('StudentRepository: Subjects: $subjects');
      print('StudentRepository: Photo: ${photo?.path}');

      // Create multipart request using the correct endpoint
      var request = http.MultipartRequest(
        'POST', // Most APIs use POST for file uploads even for updates
        Uri.parse('$baseUrl/update_student/$id'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['class'] = className;

      // Add subjects as indexed array
      for (int i = 0; i < subjects.length; i++) {
        request.fields['subjects[$i]'] = subjects[i];
      }

      // Add photo if provided
      if (photo != null) {
        var photoFile = await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          filename: 'student_photo_updated.jpg',
        );
        request.files.add(photoFile);
      }

      print('StudentRepository: Sending update request with fields: ${request.fields}');
      print('StudentRepository: Files count: ${request.files.length}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('StudentRepository: Update response status: ${response.statusCode}');
      print('StudentRepository: Update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Student student = Student.fromJson(responseData['data'] ?? responseData);

        return Right(student);
      } else if (response.statusCode == 401) {
        return Left(Failure('Unauthorized. Please login again.'));
      } else if (response.statusCode == 404) {
        return Left(Failure('Student not found'));
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        final errors = errorData['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first as List;
          return Left(Failure(firstError.first.toString()));
        }
        return Left(Failure('Validation failed'));
      } else {
        final errorData = json.decode(response.body);
        return Left(Failure(errorData['message'] ?? 'Failed to update student'));
      }
    } catch (e) {
      print('StudentRepository: Exception in updateStudent: $e');
      return Left(Failure('Network error: ${e.toString()}'));
    }
  }

  // Delete student using the correct endpoint
  Future<Either<Failure, bool>> deleteStudent(int id) async {
    try {
      final token = await _getAuthToken();

      print('StudentRepository: Starting deleteStudent for ID: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/delete_student/$id'), // Using the correct endpoint
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('StudentRepository: Delete response status: ${response.statusCode}');
      print('StudentRepository: Delete response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      } else if (response.statusCode == 401) {
        return Left(Failure('Unauthorized. Please login again.'));
      } else if (response.statusCode == 404) {
        return Left(Failure('Student not found'));
      } else {
        try {
          final errorData = json.decode(response.body);
          return Left(Failure(errorData['message'] ?? 'Failed to delete student'));
        } catch (e) {
          return Left(Failure('Failed to delete student: HTTP ${response.statusCode}'));
        }
      }
    } catch (e) {
      print('StudentRepository: Exception in deleteStudent: $e');
      return Left(Failure('Network error: ${e.toString()}'));
    }
  }
}