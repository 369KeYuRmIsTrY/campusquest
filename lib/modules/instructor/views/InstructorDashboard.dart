import 'package:campusquest/controllers/login_controller.dart';
import 'package:campusquest/modules/instructor/views/Submitted_Assignments.dart';
import 'package:campusquest/modules/instructor/views/attendancepage.dart';
import 'package:campusquest/modules/instructor/views/uploadmaterialpage.dart';
import 'package:campusquest/modules/login/views/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:campusquest/widgets/common_app_bar.dart';
import 'package:campusquest/theme/theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:campusquest/modules/instructor/views/StudentResultsPage.dart';
import 'dart:ui';
import 'package:campusquest/widgets/bottomnavigationbar.dart';

import '../../../controllers/theme_controller.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  String instructorName = "Instructor";
  String designation = "";
  bool isLoading = true;
  final SupabaseClient _supabase = Supabase.instance.client;
  int _notesCount = 0;
  int _coursesCount = 0;
  int _studentsCount = 0;
  List<Map<String, dynamic>> _assignments = [];
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  final List<Map<String, dynamic>> quickActions = [
    {
      'title': 'Upload Materials',
      'subtitle': 'Share files with your students',
      'icon': Icons.upload_file,
      'gradient': [
        Color(0xFF36D1DC), // turquoise
        Color(0xFF5B86E5), // blue
      ],
      'onTap': 'uploadMaterials',
    },
    {
      'title': 'Attendance',
      'subtitle': 'Mark class attendance',
      'icon': Icons.calendar_today,
      'gradient': [
        Color(0xFF11998E), // green
        Color(0xFF38EF7D), // light green
      ],
      'onTap': 'attendance',
    },
    {
      'title': 'Upload Results',
      'subtitle': 'Add or update student marks',
      'icon': Icons.grade,
      'gradient': [
        Color(0xFFDA22FF), // purple
        Color(0xFF9733EE), // violet
      ],
      'onTap': 'uploadResults',
    },
    {
      'title': 'Student Records',
      'subtitle': 'View marks and attendance',
      'icon': Icons.people,
      'gradient': [
        Color(0xFFFF512F), // pinkish red
        Color(0xFFF09819), // orange
      ],
      'onTap': 'studentRecords',
    },
    {
      'title': 'Assignments',
      'subtitle': 'Grade student submissions',
      'icon': Icons.assignment,
      'gradient': [
        Color(0xFF614385), // deep purple
        Color(0xFF516395), // blue gray
      ],
      'onTap': 'assignments',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInstructorData();
    _fetchCounts();
    _fetchAssignments();
  }

  Future<void> _loadInstructorData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final savedName = prefs.getString('instructorName');
    final savedDesignation = prefs.getString('instructorDesignation');
    final savedProfileImage = prefs.getString('instructorProfileImage');

    if (savedName != null && savedDesignation != null) {
      setState(() {
        instructorName = savedName;
        designation = savedDesignation;
        _profileImageUrl = savedProfileImage;
        isLoading = false;
      });
      return;
    }

    if (userId != null) {
      try {
        final instructorData =
            await _supabase
                .from('instructor')
                .select('name, designation, profile_picture_path')
                .eq('user_id', int.parse(userId))
                .single();

        final name = instructorData['name'] as String;
        final prof = instructorData['designation'] as String;
        final profileImage = instructorData['profile_picture_path'] as String?;
        await prefs.setString('instructorName', name);
        await prefs.setString('instructorDesignation', prof);
        if (profileImage != null) {
          await prefs.setString('instructorProfileImage', profileImage);
        }
        setState(() {
          instructorName = name;
          designation = prof;
          _profileImageUrl = profileImage;
        });
      } catch (e) {
        print("Error fetching instructor data: $e");
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAssignments() async {
    try {
      final loginController = Provider.of<LoginController>(
        context,
        listen: false,
      );
      final instructorId = loginController.instructorId;
      if (instructorId == null) {
        throw Exception('Instructor ID is null');
      }
      final assignments = await _supabase
          .from('assignment')
          .select(
            'assignment_id, title, course_id, semester_id, due_date, description, file_path, max_marks, created_by, course!inner(course_name)',
          )
          .eq('created_by', instructorId);
      setState(() {
        _assignments = assignments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching assignments: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('instructorName');
    await prefs.remove('instructorDesignation');
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final loginController = Provider.of<LoginController>(
        context,
        listen: false,
      );
      final instructorId = loginController.instructorId;
      if (instructorId == null) return;

      // Fetch notes count
      final notesResponse = await _supabase
          .from('notes')
          .select()
          .eq('uploaded_by', instructorId);
      final notesCount = notesResponse.length;

      // Fetch courses count
      final coursesResponse = await _supabase
          .from('teaches')
          .select(
            'course:course_id(course_id, course_name, semester_id), semester:semester_id(semester_id, semester_number)',
          )
          .eq('instructor_id', instructorId);
      final coursesCount = coursesResponse.length;

      // Fetch students count
      final courseIds =
          coursesResponse.map((c) => c['course']['course_id']).toList();
      if (courseIds.isNotEmpty) {
        final studentsResponse = await _supabase
            .from('enrollment')
            .select('student_id')
            .inFilter('course_id', courseIds);

        // Get unique student IDs
        final uniqueStudentIds =
            studentsResponse.map((e) => e['student_id']).toSet().toList();
        final studentsCount = uniqueStudentIds.length;

        setState(() {
          _notesCount = notesCount;
          _coursesCount = coursesCount;
          _studentsCount = studentsCount;
        });
      } else {
        setState(() {
          _notesCount = notesCount;
          _coursesCount = coursesCount;
          _studentsCount = 0;
        });
      }
    } catch (e) {
      print('Error fetching counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Dashboard',
        userEmail: Provider.of<LoginController>(context).email.split('@').first,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
        ),
      ),
      drawer: CustomDrawer(
        username: instructorName,
        role: designation,
        onLogout: _logout,
        onSettings: () {
          // handle settings
        },
        onMenuTap: (index) {
          // handle menu navigation by index
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadMaterialsPage(),
                ),
              );
              break;
            case 2:
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AttendancePage()),
              );
              break;
            case 3:
              Navigator.pop(context);
              // Navigate to students page
              break;
            case 4:
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentResultsPage(),
                ),
              );
              break;
            case 5:
              Navigator.pop(context);
              // Add navigation if needed
              break;
          }
        },
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepPurple.shade50, Colors.white],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (context) {
                                  return FutureBuilder<Map<String, dynamic>>(
                                    future: _fetchInstructorDetails(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Text(
                                              'Error loading details',
                                            ),
                                          ),
                                        );
                                      }
                                      final details = snapshot.data ?? {};
                                      return Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 3,
                                                    ),
                                                  ),
                                                  child:
                                                      _profileImageUrl !=
                                                                  null &&
                                                              _profileImageUrl!
                                                                  .isNotEmpty
                                                          ? CircleAvatar(
                                                            backgroundColor:
                                                                AppTheme
                                                                    .veryDarkBlue,
                                                            radius: 28,
                                                            backgroundImage:
                                                                NetworkImage(
                                                                  _profileImageUrl!,
                                                                ),
                                                          )
                                                          : CircleAvatar(
                                                            backgroundColor:
                                                                AppTheme
                                                                    .veryDarkBlue,
                                                            radius: 28,
                                                            child: Text(
                                                              (details['name'] ??
                                                                          instructorName)
                                                                      .isNotEmpty
                                                                  ? (details['name'] ??
                                                                          instructorName)[0]
                                                                      .toUpperCase()
                                                                  : "I",
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 24,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                          ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            _buildDetailRow(
                                              Icons.work,
                                              'Designation',
                                              details['designation'] ??
                                                  designation,
                                            ),
                                            _buildDetailRow(
                                              Icons.email,
                                              'Email',
                                              details['email'] ?? 'N/A',
                                            ),
                                            _buildDetailRow(
                                              Icons.phone,
                                              'Phone',
                                              details['phone_number'] ?? 'N/A',
                                            ),
                                            _buildDetailRow(
                                              Icons.business,
                                              'Department',
                                              details['dept_name'] ?? 'N/A',
                                            ),
                                            _buildDetailRow(
                                              Icons.school,
                                              'Qualification',
                                              details['qualification'] ?? 'N/A',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.veryDarkBlue,
                                    AppTheme.darkBlue,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child:
                                            _profileImageUrl != null &&
                                                    _profileImageUrl!.isNotEmpty
                                                ? CircleAvatar(
                                                  backgroundColor:
                                                      AppTheme.veryDarkBlue,
                                                  radius: 24,
                                                  backgroundImage: NetworkImage(
                                                    _profileImageUrl!,
                                                  ),
                                                )
                                                : CircleAvatar(
                                                  backgroundColor:
                                                      AppTheme.veryDarkBlue,
                                                  radius: 24,
                                                  child: Text(
                                                    instructorName.isNotEmpty
                                                        ? instructorName[0]
                                                            .toUpperCase()
                                                        : "I",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back, $instructorName',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          designation.isNotEmpty
                                              ? designation
                                              : 'Instructor',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildCounterCard(
                                        'Materials',
                                        _notesCount,
                                        Colors.blue,
                                        Icons.book,
                                      ),
                                      _buildCounterCard(
                                        'Classes',
                                        _coursesCount,
                                        Colors.green,
                                        Icons.calendar_today,
                                      ),
                                      _buildCounterCard(
                                        'Students',
                                        _studentsCount,
                                        Colors.orange,
                                        Icons.people,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children:
                                quickActions
                                    .map(
                                      (action) => _buildQuickActionCard(
                                        action,
                                        context,
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Assignments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _assignments.isEmpty
                            ? Center(
                              child: Text(
                                'No assignments found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = _assignments[index];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      assignment['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo[700],
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Course: ${assignment['course']['course_name']}\nDue: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(assignment['due_date']))}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.indigo[700],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (
                                                context,
                                              ) => InstructorAssignmentsPage(
                                                title: assignment['title'],
                                                subject:
                                                    assignment['course']['course_name'],
                                                assignmentId:
                                                    assignment['assignment_id'],
                                                dueDate: DateTime.parse(
                                                  assignment['due_date'],
                                                ),
                                                instructorFilePath:
                                                    assignment['file_path'],
                                                description:
                                                    assignment['description'] ??
                                                    'No description',
                                                courseId:
                                                    assignment['course_id'],
                                                semesterId:
                                                    assignment['semester_id'],
                                                maxMarks:
                                                    assignment['max_marks'],
                                                createdBy:
                                                    assignment['created_by'],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildCounterCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(Map action, BuildContext context) {
    return InkWell(
      onTap: () {
        switch (action['onTap']) {
          case 'uploadMaterials':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadMaterialsPage()),
            );
            break;
          case 'attendance':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendancePage()),
            );
            break;
          case 'uploadResults':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentResultsPage()),
            );
            break;
          case 'studentRecords':
            // Add navigation if needed
            break;
          case 'assignments':
            // Add navigation if needed
            break;
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: List<Color>.from(action['gradient']),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(action['icon'], color: Colors.white, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      action['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action['subtitle'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchInstructorDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return {};
    try {
      final data =
          await _supabase
              .from('instructor')
              .select(
                'name, designation, dept_name, qualification, users(email, phone_number)',
              )
              .eq('user_id', int.parse(userId))
              .single();
      return {
        'name': data['name'],
        'designation': data['designation'],
        'dept_name': data['dept_name'],
        'qualification': data['qualification'],
        'email': data['users']?['email'],
        'phone_number': data['users']?['phone_number'],
      };
    } catch (e) {
      return {};
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('User ID not found');
      final file = File(pickedFile.path);
      final fileName =
          'instructors/$userId/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      // Upload to Supabase Storage
      await _supabase.storage.from('profilepictures').upload(fileName, file);
      final publicUrl = _supabase.storage
          .from('profilepictures')
          .getPublicUrl(fileName);
      // Save URL to instructor table
      await _supabase
          .from('instructor')
          .update({'profile_picture_path': publicUrl})
          .eq('user_id', int.parse(userId));
      // Save to local prefs and state
      await prefs.setString('instructorProfileImage', publicUrl);
      setState(() {
        _profileImageUrl = publicUrl;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image updated!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }
}

extension on PostgrestFilterBuilder<PostgrestList> {
  any(String s, List list) {}
}

class CustomDrawer extends StatelessWidget {
  final String username;
  final String role;
  final VoidCallback? onLogout;
  final VoidCallback? onSettings;
  final Function(int)? onMenuTap;

  const CustomDrawer({
    Key? key,
    required this.username,
    required this.role,
    this.onLogout,
    this.onSettings,
    this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2A6472), // AppBar color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2A6472)),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Color(0xFF2A6472),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    role,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  iconColor: Color(0xFF9B59B6), // purple
                  text: 'Dashboard',
                  onTap: () => onMenuTap?.call(0),
                ),
                _buildDrawerItem(
                  icon: Icons.upload_file,
                  iconColor: Color(0xFF2980B9), // blue
                  text: 'Upload Materials',
                  onTap: () => onMenuTap?.call(1),
                ),
                _buildDrawerItem(
                  icon: Icons.event_available,
                  iconColor: Color(0xFF27AE60), // green
                  text: 'Attendance',
                  onTap: () => onMenuTap?.call(2),
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  iconColor: Color(0xFFF39C12), // orange
                  text: 'Students',
                  onTap: () => onMenuTap?.call(3),
                ),
                _buildDrawerItem(
                  icon: Icons.star,
                  iconColor: Color(0xFFE84393), // pink
                  text: 'Upload Results',
                  onTap: () => onMenuTap?.call(4),
                ),
                const Divider(color: Colors.white24, thickness: 1),
                _buildDrawerItem(
                  icon: Icons.settings,
                  iconColor: Colors.white70,
                  text: 'Settings',
                  onTap: onSettings,
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  text: 'Logout',
                  textColor: Colors.redAccent,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      onTap: onTap,
    );
  }
}

class InstructorDashboardEntry extends StatelessWidget {
  const InstructorDashboardEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomBar();
  }
}
