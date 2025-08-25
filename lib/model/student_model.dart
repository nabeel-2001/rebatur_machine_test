class Student {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? course;
  final List<String>? subjects;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Student({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.course,
    this.subjects,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create Student from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    // Handle subjects - could be array of strings or array of objects
    List<String>? subjectsList;
    if (json['subjects'] != null) {
      if (json['subjects'] is List) {
        subjectsList = (json['subjects'] as List).map((subject) {
          // If subject is an object with a 'name' field
          if (subject is Map<String, dynamic> && subject.containsKey('name')) {
            return subject['name'].toString();
          }
          // If subject is just a string
          return subject.toString();
        }).toList();
      }
    }

    return Student(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      course: json['class'] ?? json['course'], // Handle both 'class' and 'course'
      subjects: subjectsList,
      photoUrl: json['photo_url'] ?? json['photo'] ?? json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  // Method to convert Student to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      if (address != null) 'address': address,
      if (course != null) 'course': course,
      if (subjects != null) 'subjects': subjects,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Method to create a copy of Student with updated fields
  Student copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? course,
    List<String>? subjects,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      course: course ?? this.course,
      subjects: subjects ?? this.subjects,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get subjects as a formatted string
  String get subjectsString {
    if (subjects == null || subjects!.isEmpty) {
      return 'No subjects';
    }
    return subjects!.join(', ');
  }

  // Helper method to check if student has subjects
  bool get hasSubjects {
    return subjects != null && subjects!.isNotEmpty;
  }

  // Helper method to get subject count
  int get subjectCount {
    return subjects?.length ?? 0;
  }

  // Helper method to check if student has photo
  bool get hasPhoto {
    return photoUrl != null && photoUrl!.isNotEmpty;
  }

  @override
  String toString() {
    return 'Student{id: $id, name: $name, email: $email, phone: $phone, address: $address, course: $course, subjects: $subjects, photoUrl: $photoUrl, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Student &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              email == other.email &&
              phone == other.phone &&
              address == other.address &&
              course == other.course &&
              _listEquals(subjects, other.subjects) &&
              photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      address.hashCode ^
      course.hashCode ^
      subjects.hashCode ^
      photoUrl.hashCode;

  // Helper method to compare lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}