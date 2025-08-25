import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import '../../../core/custom_widget/custom_textform_field.dart';
import '../../../core/theme/color_constant.dart';
import '../controller/student_controller.dart';

class StudentAddPage extends ConsumerStatefulWidget {
  const StudentAddPage({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentAddPage> createState() => _StudentAddPageState();
}

class _StudentAddPageState extends ConsumerState<StudentAddPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
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
    _emailController.dispose();
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

  void _saveStudent() {
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

      // Call the createStudent method from controller with new parameters
      ref.read(studentControllerProvider.notifier).createStudent(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        className: _selectedClass!,
        subjects: _subjectList,
        photo: _selectedImage,
        context: context,
        onSuccess: () {
          // This will be called when student is created successfully
          _clearForm();
        },
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _subjectController.clear();
    setState(() {
      _selectedClass = null;
      _selectedImage = null;
      _subjectList.clear();
      _editingIndex = null;
    });
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
          // Custom TextField that acts as image picker trigger
          GestureDetector(
            onTap: _pickImage,
            child: AbsorbPointer(
              child: CustomTextField(
                controller: TextEditingController(
                    text: _selectedImage != null
                        ? 'Image selected: ${_selectedImage!.path.split('/').last}'
                        : ''
                ),
                hintText: 'Upload Your Photo',
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.upload)
                ),
              ),
            ),
          ),

          // Always show container below text field
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorConstant.blue,
                width: 1,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                // Image icon overlay when image is selected
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/image_icon.svg',
                      width: 16,
                      height: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Remove/Change image button
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child:Icon(Icons.image,size: 35,)
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

          // Add/Update/Cancel buttons in next line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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

          // Subject table using Table widget
          if (_subjectList.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: ColorConstant.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Table(
                  border: TableBorder.all(
                    color: ColorConstant.blue,
                    width: 1,
                  ),
                  columnWidths: {
                    0: FixedColumnWidth(50),    // S.No
                    1: FlexColumnWidth(3),      // Subject
                    2: FixedColumnWidth(80),    // Actions
                  },
                  children: [
                    // Table Header
                    TableRow(
                      decoration: BoxDecoration(
                        color: ColorConstant.blue.withOpacity(0.1),
                      ),
                      children: [
                        _buildTableHeaderCell('S.No'),
                        _buildTableHeaderCell('Subject'),
                        _buildTableHeaderCell('Actions'),
                      ],
                    ),
                    // Table Data Rows
                    ..._subjectList.asMap().entries.map((entry) {
                      int index = entry.key;
                      String subject = entry.value;

                      return TableRow(
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        children: [
                          _buildTableDataCell('${index + 1}'),
                          _buildTableDataCell(subject),
                          _buildTableActionCell(index),
                        ],
                      );
                    }).toList(),
                  ],
                ),
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

                  SizedBox(height: 8),
                  Text(
                    'No subjects added yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),

                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: ColorConstant.blue,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableDataCell(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
        textAlign: text == '${_subjectList.length}' ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildTableActionCell(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                              'Student Personal Details',
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

                    // Replace the single subject field with subject management section
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
                                    text: isLoading ? '' : 'Save',
                                    color: ColorConstant.blue,
                                    onPressed: _saveStudent,
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
                                child: _buildButton(text: 'Cancel',
                                  onPressed: _cancelForm,
                                  color: ColorConstant.blue,
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