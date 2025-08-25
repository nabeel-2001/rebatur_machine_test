import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import '../../../core/custom_widget/custom_textform_field.dart';
import '../../../core/theme/color_constant.dart';
import '../../../model/student_model.dart';
import '../controller/student_controller.dart';

class StudentEditPage extends ConsumerStatefulWidget {
  final Student student;

  const StudentEditPage({Key? key, required this.student}) : super(key: key);

  @override
  ConsumerState<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends ConsumerState<StudentEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _subjectController = TextEditingController();

  // Image picker
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Dropdown value
  String? _selectedClass;

  bool _hasLoadedClasses = false;

  // Subject list management
  List<String> _subjectList = [];
  int? _editingIndex;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.student.name);
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _selectedClass = widget.student.course; // Assuming course maps to class

    // Initialize subjects if they exist
    if (widget.student.subjects != null && widget.student.subjects!.isNotEmpty) {
      _subjectList = List<String>.from(widget.student.subjects!);
    }

    // Load classes when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClasses();
    });
  }

  void _loadClasses() {
    if (!_hasLoadedClasses) {
      ref.read(studentControllerProvider.notifier).getClasses(context);
      _hasLoadedClasses = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Subject management methods
  void _addSubject() {
    if (_subjectController.text.trim().isNotEmpty) {
      setState(() {
        if (_editingIndex != null) {
          // Update existing subject
          _subjectList[_editingIndex!] = _subjectController.text.trim();
          _editingIndex = null;
        } else {
          // Add new subject
          _subjectList.add(_subjectController.text.trim());
        }
        _subjectController.clear();
      });
    }
  }

  void _editSubject(int index) {
    setState(() {
      _editingIndex = index;
      _subjectController.text = _subjectList[index];
    });
  }

  void _deleteSubject(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Subject'),
          content: Text('Are you sure you want to delete "${_subjectList[index]}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _subjectList.removeAt(index);
                  if (_editingIndex == index) {
                    _editingIndex = null;
                    _subjectController.clear();
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _subjectController.clear();
    });
  }

  void _updateStudent() {
    if (_formKey.currentState!.validate()) {
      if (_subjectList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one subject')),
        );
        return;
      }

      if (_selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a class')),
        );
        return;
      }

      // Call the updateStudent method from controller
      ref.read(studentControllerProvider.notifier).updateStudent(
        id: widget.student.id!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        className: _selectedClass!,
        subjects: _subjectList,
        email: "",
        course:"" ,
        photo: _selectedImage, // Only if a new photo was selected
        context: context,
        onSuccess: () {
          // This will be called when student is updated successfully
        },
      );
    }
  }

  void _cancelForm() {
    Navigator.pop(context);
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            child: Text(
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

  Widget _buildImagePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Photo',
            style: TextStyle(
              color: ColorConstant.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(
                  color: ColorConstant.blue,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
                  : widget.student.photoUrl != null && widget.student.photoUrl!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.student.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to update image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    final classes = ref.watch(classesProvider);
    final isLoading = ref.watch(studentControllerProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: _selectedClass,
        hint: Text(
          isLoading ? 'Loading classes...' : 'Select Class',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        decoration: InputDecoration(
          labelText: 'Class',
          labelStyle: TextStyle(
            color: ColorConstant.blue,
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: ColorConstant.blue,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: ColorConstant.blue,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: ColorConstant.blue,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: isLoading
              ? Container(
            width: 20,
            height: 20,
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.blue),
            ),
          )
              : null,
        ),
        items: classes.isEmpty
            ? null
            : classes.map((String className) {
          return DropdownMenuItem<String>(
            value: className,
            child: Text(className),
          );
        }).toList(),
        onChanged: isLoading
            ? null
            : (String? newValue) {
          setState(() {
            _selectedClass = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a class';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubjectSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subjects',
            style: TextStyle(
              color: ColorConstant.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Subject input field
          CustomTextField(
            controller: _subjectController,
            hintText: _editingIndex != null ? 'Edit Subject' : 'Enter Subject',
            keyboardType: TextInputType.text,
          ),

          const SizedBox(height: 12),

          // Add/Update/Cancel buttons
          Row(
            children: [
              Container(
                height: 45,
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorConstant.blue, ColorConstant.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addSubject,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        _editingIndex != null ? 'Update' : 'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_editingIndex != null) ...[
                const SizedBox(width: 10),
                Container(
                  height: 45,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _cancelEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Subject table
          if (_subjectList.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: ColorConstant.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstant.blue.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: ColorConstant.blue, width: 1),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          child: Text(
                            'S.No',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: ColorConstant.blue,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Expanded(
                          child: Text(
                            'Subject',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: ColorConstant.blue,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Container(
                          width: 80,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.blue,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table rows
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _subjectList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: index < _subjectList.length - 1
                                ? BorderSide(color: ColorConstant.blue.withOpacity(0.3), width: 1)
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: ColorConstant.blue.withOpacity(0.3),
                              margin: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Expanded(
                              child: Text(
                                _subjectList[index],
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: ColorConstant.blue.withOpacity(0.3),
                              margin: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Container(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () => _editSubject(index),
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _deleteSubject(index),
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No subjects added yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Add subjects using the input field above',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isLoading = ref.watch(studentControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom AppBar Container
          Container(
            height: height * 0.2,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/banner.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Edit Student Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 40),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Name',
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student name';
                        }
                        return null;
                      },
                    ),

                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),

                    _buildClassDropdown(),

                    _buildSubjectSection(),

                    _buildImagePicker(),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: AbsorbPointer(
                            absorbing: isLoading,
                            child: Opacity(
                              opacity: isLoading ? 0.6 : 1.0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildButton(
                                    text: isLoading ? '' : 'Update',
                                    color: ColorConstant.blue,
                                    onPressed: _updateStudent,
                                  ),
                                  if (isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isLoading ? null : _cancelForm,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Cancel',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}