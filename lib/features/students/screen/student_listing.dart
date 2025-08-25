import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rebatur_machine_test/core/local_variable.dart';
import 'package:rebatur_machine_test/features/students/screen/student_add.dart';

import '../../../core/theme/color_constant.dart';
import '../../../model/student_model.dart';
import '../controller/student_controller.dart';

class StudentListingPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<StudentListingPage> createState() => _StudentListingPageState();
}

class _StudentListingPageState extends ConsumerState<StudentListingPage>
    with WidgetsBindingObserver {
  int currentPage = 1;
  int itemsPerPage = 10;
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = true;

  // Auto-refresh interval (30 seconds - you can adjust this)
  static const Duration _autoRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load students when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Loading students...');
      ref.read(studentControllerProvider.notifier).getStudents(context);
    });

    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // App came back to foreground - refresh data and restart timer
        print('App resumed - refreshing data');
        _refreshData();
        if (_isAutoRefreshEnabled) {
          _startAutoRefresh();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      // App went to background - stop timer to save resources
        _stopAutoRefresh();
        break;
      case AppLifecycleState.detached:
        _stopAutoRefresh();
        break;
      case AppLifecycleState.hidden:
        _stopAutoRefresh();
        break;
    }
  }

  // Start auto-refresh timer
  void _startAutoRefresh() {
    _stopAutoRefresh(); // Stop any existing timer

    if (_isAutoRefreshEnabled) {
      _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
        if (mounted && !ref.read(studentControllerProvider)) {
          print('Auto-refreshing data...');
          _refreshData();
        }
      });
      print('Auto-refresh started (${_autoRefreshInterval.inSeconds}s interval)');
    }
  }

  // Stop auto-refresh timer
  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // Toggle auto-refresh on/off
  void _toggleAutoRefresh() {
    setState(() {
      _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
    });

    if (_isAutoRefreshEnabled) {
      _startAutoRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-refresh enabled (${_autoRefreshInterval.inSeconds}s)'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _stopAutoRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-refresh disabled'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Refresh data method
  void _refreshData() {
    if (mounted) {
      ref.read(studentControllerProvider.notifier).getStudents(context);
    }
  }

  // Manual refresh with user feedback
  void _manualRefresh() {
    print('Manual refresh triggered');
    _refreshData();

    // Show brief feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Calculate total pages based on data
  int getTotalPages() {
    final allStudents = ref.watch(studentsProvider);
    if (allStudents.isEmpty) return 1;
    return (allStudents.length / itemsPerPage).ceil();
  }

  List<Student> getCurrentPageStudents() {
    final allStudents = ref.watch(studentsProvider);
    if (allStudents.isEmpty) return [];

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    // Ensure we don't go beyond the list length
    if (startIndex >= allStudents.length) {
      return [];
    }

    if (endIndex > allStudents.length) {
      endIndex = allStudents.length;
    }

    return allStudents.sublist(startIndex, endIndex);
  }

  // Reset to page 1 when data changes significantly
  void _checkAndResetPage() {
    final totalPages = getTotalPages();
    if (currentPage > totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          currentPage = 1;
        });
      });
    }
  }

  void _deleteStudent(int studentId) {
    ref.read(studentControllerProvider.notifier).deleteStudent(
      id: studentId,
      context: context,
    );
  }

  void _editStudent(Student student) {
    final nameController = TextEditingController(text: student.name);
    final phoneController = TextEditingController(text: student.phone);
    final classController = TextEditingController(text: student.course ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: classController,
                decoration: InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(studentControllerProvider.notifier).updateStudent(
                  id: student.id!,
                  name: nameController.text,
                  email: student.email,
                  phone: phoneController.text,
                  className: student.course!,
                  subjects: student.subjects!,
                  course: classController.text,
                  context: context,
                );
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(studentControllerProvider);
    final allStudents = ref.watch(studentsProvider);
    final totalPages = getTotalPages();
    final currentStudents = getCurrentPageStudents();

    // Check if we need to reset page when data changes
    _checkAndResetPage();

    print('Build called - Loading: $isLoading, Students count: ${allStudents.length}, Total Pages: $totalPages, Current Page: $currentPage');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with banner image
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
                          SizedBox(),
                          Expanded(
                            child: Text(
                              'Student Listing',
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
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Enhanced header with refresh controls
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Manual refresh button
                              IconButton(
                                onPressed: isLoading ? null : _manualRefresh,
                                icon: AnimatedRotation(
                                  turns: isLoading ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 1000),
                                  child: Icon(
                                    Icons.refresh,
                                    color: ColorConstant.blue,
                                  ),
                                ),
                                tooltip: 'Manual Refresh',
                              ),

                              SizedBox(width: 12),
                              // Show total count
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total: ${allStudents.length} students',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Navigate to add page and refresh when returning
                              final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => StudentAddPage())
                              );
                              // Auto-refresh when returning from add page
                              if (result != null || mounted) {
                                print('Returned from Add page - refreshing data');
                                _refreshData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ColorConstant.blue,
                                    ColorConstant.red,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                alignment: Alignment.center,
                                child: Text(
                                  'Add New',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Section
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: ColorConstant.blue),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isLoading
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: ColorConstant.blue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Loading students...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                            : currentStudents.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                allStudents.isEmpty ? 'No students found' : 'No students on this page',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              if (allStudents.isNotEmpty && currentPage > 1)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      currentPage = 1;
                                    });
                                  },
                                  child: Text('Go to first page'),
                                ),
                            ],
                          ),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Table(
                            border: TableBorder.all(
                              color: ColorConstant.blue,
                              width: 1.5,
                            ),
                            columnWidths: {
                              0: FlexColumnWidth(1), // Sr No
                              1: FlexColumnWidth(2), // Name
                              2: FlexColumnWidth(2), // Phone
                              3: FlexColumnWidth(1), // Class
                              4: FlexColumnWidth(4), // Actions
                            },
                            children: [
                              // Table Header
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                ),
                                children: [
                                  _buildTableHeaderCell('Sr\nNo'),
                                  _buildTableHeaderCell('Name'),
                                  _buildTableHeaderCell('Phone'),
                                  _buildTableHeaderCell('Class'),
                                  _buildTableHeaderCell('Actions'),
                                ],
                              ),
                              // Table Data Rows
                              ...currentStudents.asMap().entries.map((entry) {
                                int index = entry.key;
                                Student student = entry.value;

                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  children: [
                                    _buildTableDataCell(
                                      '${(currentPage - 1) * itemsPerPage + index + 1}',
                                    ),
                                    _buildTableDataCell(student.name),
                                    _buildTableDataCell(student.phone),
                                    _buildTableDataCell(student.course ?? ''),
                                    _buildTableActionCell(student),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Pagination at the bottom - Always show if there's data
                    if (allStudents.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                        ),
                        child: Column(
                          children: [
                            // Pagination info
                            Text(
                              'Page $currentPage of $totalPages (${allStudents.length} total students)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Pagination buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Previous button
                                if (currentPage > 1)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        currentPage--;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 4),
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.chevron_left,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),

                                // Page numbers (smart pagination)
                                ..._buildPaginationNumbers(totalPages),

                                // Next button
                                if (currentPage < totalPages)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        currentPage++;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 4),
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
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

  // Smart pagination numbers generation
  List<Widget> _buildPaginationNumbers(int totalPages) {
    List<Widget> pages = [];

    if (totalPages <= 7) {
      // Show all pages if total pages is 7 or less
      for (int i = 1; i <= totalPages; i++) {
        pages.add(_buildPageButton(i));
      }
    } else {
      // Smart pagination for more than 7 pages
      if (currentPage <= 4) {
        // Show first 5 pages, then ... and last page
        for (int i = 1; i <= 5; i++) {
          pages.add(_buildPageButton(i));
        }
        pages.add(_buildDots());
        pages.add(_buildPageButton(totalPages));
      } else if (currentPage >= totalPages - 3) {
        // Show first page, then ... and last 5 pages
        pages.add(_buildPageButton(1));
        pages.add(_buildDots());
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pages.add(_buildPageButton(i));
        }
      } else {
        // Show first page, ..., current-1, current, current+1, ..., last page
        pages.add(_buildPageButton(1));
        pages.add(_buildDots());
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pages.add(_buildPageButton(i));
        }
        pages.add(_buildDots());
        pages.add(_buildPageButton(totalPages));
      }
    }

    return pages;
  }

  Widget _buildPageButton(int pageNumber) {
    return GestureDetector(
      onTap: () {
        setState(() {
          currentPage = pageNumber;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: currentPage == pageNumber ? Color(0xFFFF6B6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: currentPage == pageNumber ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: currentPage == pageNumber ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: currentPage == pageNumber ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        '...',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 10,
          color: ColorConstant.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableDataCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableActionCell(Student student) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _editStudent(student),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.visibility,
                size: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
          SizedBox(width: 6),
          GestureDetector(
            onTap: () => _editStudent(student),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.edit,
                size: 14,
                color: Colors.orange[700],
              ),
            ),
          ),
          SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteStudent(student.id!),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.delete,
                size: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}