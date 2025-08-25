import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/common/common_snack_bar.dart';
import '../../../model/student_model.dart';
import '../repository/student_repository.dart';

// Provider for loading state
final studentControllerProvider = NotifierProvider<StudentController, bool>(() => StudentController());

// Provider for students list
final studentsProvider = NotifierProvider<StudentsNotifier, List<Student>>(() => StudentsNotifier());

// Provider for classes list
final classesProvider = NotifierProvider<ClassesNotifier, List<String>>(() => ClassesNotifier());

class StudentController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  StudentRepository get _studentRepository => ref.read(studentRepositoryProvider);

  // Get all students
  Future<void> getStudents(BuildContext context) async {
    print('StudentController: Starting getStudents');
    state = true;

    final result = await _studentRepository.getStudents();

    state = false;
    print('StudentController: Finished API call');

    result.fold(
          (failure) {
        print('StudentController: Error - ${failure.message}');
        snackBar(context, failure.message);
      },
          (students) {
        print('StudentController: Success - Received ${students.length} students');
        // Update the students list in the provider
        ref.read(studentsProvider.notifier).updateStudents(students);

        // Show a message if no students found
        if (students.isEmpty) {
          snackBar(context, 'No students found. The database appears to be empty.');
        }
      },
    );
  }

  // Get single student
  Future<Student?> getStudent(int id, BuildContext context) async {
    state = true;

    final result = await _studentRepository.getStudent(id);

    state = false;

    return result.fold(
          (failure) {
        snackBar(context, failure.message);
        return null;
      },
          (student) => student,
    );
  }

  // Create new student with subjects and photo
  Future<void> createStudent({
    required String name,
    required String phone,
    required String className,
    required List<String> subjects,
    File? photo,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    print('StudentController: Starting createStudent');
    print('StudentController: Name: $name');
    print('StudentController: Phone: $phone');
    print('StudentController: Class: $className');
    print('StudentController: Subjects: $subjects');
    print('StudentController: Photo: ${photo?.path}');

    state = true;

    final result = await _studentRepository.createStudent(
      name: name,
      phone: phone,
      className: className,
      subjects: subjects,
      photo: photo,
    );

    state = false;

    result.fold(
          (failure) {
        print('StudentController: Error creating student - ${failure.message}');
        snackBar(context, failure.message);
      },
          (student) {
        print('StudentController: Student created successfully');
        snackBar(context, 'Student created successfully!');

        // Add the new student to the list
        ref.read(studentsProvider.notifier).addStudent(student);

        // Call success callback if provided
        onSuccess?.call();

        // Navigate back
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  // Update student with subjects and photo
  Future<void> updateStudent({
    required int id,
    required String name,
    required String phone,
    required String className,
    required String email,

    required String course,
    required List<String> subjects,

    File? photo,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    print('StudentController: Starting updateStudent for ID: $id');
    print('StudentController: Name: $name');
    print('StudentController: Phone: $phone');
    print('StudentController: Class: $className');
    print('StudentController: Subjects: $subjects');
    print('StudentController: Photo: ${photo?.path}');

    state = true;

    final result = await _studentRepository.updateStudent(
      id: id,
      name: name,
      phone: phone,
      className: className,
      subjects: subjects,
      photo: photo,
    );

    state = false;

    result.fold(
          (failure) {
        print('StudentController: Error updating student - ${failure.message}');
        snackBar(context, failure.message);
      },
          (student) {
        print('StudentController: Student updated successfully');
        snackBar(context, 'Student updated successfully!');

        // Update the student in the list
        ref.read(studentsProvider.notifier).updateStudent(student);

        // Call success callback if provided
        onSuccess?.call();

        // Navigate back
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  // Delete student
  Future<void> deleteStudent({
    required int id,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    print('StudentController: Starting deleteStudent for ID: $id');
    state = true;

    final result = await _studentRepository.deleteStudent(id);

    state = false;

    result.fold(
          (failure) {
        print('StudentController: Error deleting student - ${failure.message}');
        snackBar(context, failure.message);
      },
          (success) {
        print('StudentController: Student deleted successfully');
        snackBar(context, 'Student deleted successfully!');

        // Remove the student from the list
        ref.read(studentsProvider.notifier).removeStudent(id);

        // Call success callback if provided
        onSuccess?.call();
      },
    );
  }

  // Get all classes
  Future<void> getClasses(BuildContext context) async {
    print('StudentController: Starting getClasses');
    state = true;

    final result = await _studentRepository.getClasses();

    state = false;
    print('StudentController: Finished getClasses API call');

    result.fold(
          (failure) {
        print('StudentController: Error getting classes - ${failure.message}');
        snackBar(context, failure.message);
      },
          (classes) {
        print('StudentController: Success - Received ${classes.length} classes');
        // Update the classes list in the provider
        ref.read(classesProvider.notifier).updateClasses(classes);
      },
    );
  }

  // Refresh students list
  Future<void> refreshStudents(BuildContext context) async {
    await getStudents(context);
  }

  // Show delete confirmation dialog
  Future<void> showDeleteConfirmation({
    required BuildContext context,
    required int studentId,
    required String studentName,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Student'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this student?'),
                SizedBox(height: 8),
                Text(
                  'Name: $studentName',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteStudent(
                  id: studentId,
                  context: context,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Notifier for managing students list state
class StudentsNotifier extends Notifier<List<Student>> {
  @override
  List<Student> build() {
    print('StudentsNotifier: Initialized with empty list');
    return [];
  }

  void updateStudents(List<Student> students) {
    print('StudentsNotifier: Updating with ${students.length} students');
    state = students;
  }

  void addStudent(Student student) {
    print('StudentsNotifier: Adding student ${student.name}');
    state = [...state, student];
  }

  void updateStudent(Student updatedStudent) {
    print('StudentsNotifier: Updating student ${updatedStudent.name}');
    state = state.map((student) {
      if (student.id == updatedStudent.id) {
        return updatedStudent;
      }
      return student;
    }).toList();
  }

  void removeStudent(int id) {
    print('StudentsNotifier: Removing student with ID: $id');
    state = state.where((student) => student.id != id).toList();
  }

  void clearStudents() {
    state = [];
  }

  // Search students by name
  List<Student> searchStudents(String query) {
    if (query.isEmpty) return state;

    return state.where((student) {
      return student.name.toLowerCase().contains(query.toLowerCase()) ||
          (student.course?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // Get students by course
  List<Student> getStudentsByCourse(String course) {
    return state.where((student) => student.course == course).toList();
  }

  // Get student by id
  Student? getStudentById(int id) {
    try {
      return state.firstWhere((student) => student.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Notifier for managing classes list state
class ClassesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    print('ClassesNotifier: Initialized with empty list');
    return [];
  }

  void updateClasses(List<String> classes) {
    print('ClassesNotifier: Updating with ${classes.length} classes');
    state = classes;
  }

  void addClassItem(String className) {
    if (!state.contains(className)) {
      state = [...state, className];
    }
  }

  void removeClassItem(String className) {
    state = state.where((item) => item != className).toList();
  }

  void clearClasses() {
    state = [];
  }
}