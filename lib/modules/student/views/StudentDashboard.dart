import 'package:campusquest/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../widgets/common_app_bar.dart';
import '../../../theme/theme.dart';
import '../../../utils/open_file_plus.dart';
import 'StudentEventsPage.dart';
import 'TimetablePage.dart';
import 'AssignmentsPage.dart';
import 'ExamsPage.dart';
import 'NotesPage.dart';
import 'ProfilePage.dart';
import '../../login/views/login.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _studentData;
  bool _isLoadingStudentData = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    Future.microtask(() {
      final loginController = Provider.of<LoginController>(
        context,
        listen: false,
      );
      if (loginController.studentId != null) {
        _fetchStudentData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentData() async {
    setState(() => _isLoadingStudentData = true);
    try {
      final loginController = Provider.of<LoginController>(
        context,
        listen: false,
      );
      final studentId = loginController.studentId;
      if (studentId == null) throw Exception('Student ID is null');
      final response =
          await _supabase
              .from('student')
              .select(
                'student_id, name, roll_number, dept_name, program_id, current_semester, profile_picture_path,address,city,state,country,postal_code',
              )
              .eq('student_id', studentId)
              .single();
      setState(() {
        _studentData = response;
        _isLoadingStudentData = false;
      });
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error fetching student data: $e');
        setState(() => _isLoadingStudentData = false);
      }
    }
  }

  void _showFullScreenIdCard() {
    if (_studentData == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, animation, __) => FadeTransition(
              opacity: animation,
              child: Scaffold(
                backgroundColor: Colors.black.withOpacity(0.9),
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed:
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Share functionality would go here",
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
                body: Center(
                  child: Hero(
                    tag: 'student-id-card',
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildFullScreenIdCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildFullScreenIdCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.yachtClubBlueSwatch.shade700,
            AppTheme.yachtClubBlueSwatch.shade400,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.yachtClubBlueSwatch.shade900.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student ID Card',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 30),
              ),
            ],
          ),
          const Divider(color: Colors.white70, thickness: 1, height: 32),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
              image:
                  _studentData!['profile_picture_path'] != null
                      ? DecorationImage(
                        image: NetworkImage(
                          _studentData!['profile_picture_path'],
                        ),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _studentData!['profile_picture_path'] == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white70)
                    : null,
          ),
          const SizedBox(height: 24),
          Text(
            _studentData!['name'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Roll No: ${_studentData!['roll_number'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFullScreenIdField(
            'Student ID',
            _studentData!['student_id'].toString(),
            Icons.perm_identity,
          ),
          _buildFullScreenIdField(
            'Department',
            _studentData!['dept_name'] ?? 'Not Assigned',
            Icons.business,
          ),
          _buildFullScreenIdField(
            'Program ID',
            _studentData!['program_id'].toString(),
            Icons.school,
          ),
          _buildFullScreenIdField(
            'Semester',
            _studentData!['current_semester'].toString(),
            Icons.calendar_today,
          ),
          _buildFullScreenIdField(
            'Address',
            _studentData!['address'].toString(),
            Icons.perm_identity,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.yachtClubBlueSwatch.shade900,
                  AppTheme.yachtClubBlueSwatch.shade600,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Valid for Current Semester',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenIdField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildStudentIdCard() {
    if (_isLoadingStudentData) return _buildStudentIdCardShimmer();
    if (_studentData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              'Failed to load student data',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchStudentData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yachtClubBlueSwatch.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Hero(
      tag: 'student-id-card',
      child: FadeTransition(
        opacity: _animation,
        child: Card(
          elevation: 4,
          shadowColor: AppTheme.yachtClubBlueSwatch.shade200.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: _showFullScreenIdCard,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.yachtClubBlueSwatch.shade100,
                    Colors.grey.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.yachtClubBlueSwatch.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student ID Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.veryDarkBlue,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.yachtClubBlueSwatch.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.school,
                              color: AppTheme.veryDarkBlue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.yachtClubBlueSwatch.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fullscreen,
                              color: AppTheme.veryDarkBlue,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(
                    color: AppTheme.veryDarkBlue,
                    thickness: 0.5,
                    height: 24,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.yachtClubBlueSwatch.shade700,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.yachtClubBlueSwatch.shade200
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          image:
                              _studentData!['profile_picture_path'] != null
                                  ? DecorationImage(
                                    image: NetworkImage(
                                      _studentData!['profile_picture_path'],
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _studentData!['profile_picture_path'] == null
                                ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color:AppTheme
                                          .yachtClubBlue
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _studentData!['name'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.veryDarkBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.badge,
                                  size: 16,
                                  color: AppTheme.veryDarkBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Roll No: ${_studentData!['roll_number'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildIdField(
                    'Student ID',
                    _studentData!['student_id'].toString(),
                    Icons.perm_identity,
                  ),
                  _buildIdField(
                    'Department',
                    _studentData!['dept_name'] ?? 'Not Assigned',
                    Icons.business,
                  ),
                  _buildIdField(
                    'Program ID',
                    _studentData!['program_id'].toString(),
                    Icons.school,
                  ),
                  _buildIdField(
                    'Semester',
                    _studentData!['current_semester'].toString(),
                    Icons.collections_bookmark_sharp,
                  ),
                  _buildIdField(
                    'Address',
                    _studentData!['address'].toString(),
                    Icons.local_mall,
                  ),
                  _buildIdField(
                    'City',
                    _studentData!['city'].toString(),
                    Icons.location_city_sharp,
                  ),
                  _buildIdField(
                    'State',
                    _studentData!['state'].toString(),
                    Icons.location_searching,
                  ),
                  _buildIdField(
                    'Country',
                    _studentData!['country'].toString(),
                    Icons.location_pin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentIdCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          height: 240,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildIdField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.yachtClubBlueSwatch.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.veryDarkBlue),
            const SizedBox(width: 8),
            Text(
              '$label: $value',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    final drawerItems = [
      {
        'icon': Icons.event,
        'label': 'Events',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentEventsPage()),
          );
        },
      },
      {
        'icon': Icons.schedule,
        'label': 'Time Table',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TimetablePage()),
          );
        },
      },
      {
        'icon': Icons.assignment,
        'label': 'Assignment',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssignmentsPage()),
          );
        },
      },
      {
        'icon': Icons.school,
        'label': 'Exams',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExamsPage()),
          );
        },
      },
      {
        'icon': Icons.note,
        'label': 'Notes',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotesPage()),
          );
        },
      },
      {
        'icon': Icons.person,
        'label': 'Profile',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        },
      },
    ];

    return Drawer(
      child: Container(
        color: AppTheme.yachtClubBlue,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.yachtClubBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        _studentData != null &&
                                _studentData!['profile_picture_path'] != null &&
                                _studentData!['profile_picture_path']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(
                              _studentData!['profile_picture_path'],
                            )
                            : const AssetImage('assets/students.png')
                                as ImageProvider,
                    backgroundColor: AppTheme.yachtClubLight,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loginController.studentName ?? 'Student',
                    style: const TextStyle(
                      color: AppTheme.yachtClubLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    loginController.role,
                    style: TextStyle(
                      color: AppTheme.yachtClubLight.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Animated drawer items
            AnimationLimiter(
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              child: Column(
                children: List.generate(drawerItems.length, (index) {
                  final item = drawerItems[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 350),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        delay: Duration(milliseconds: 10 * index),
                        child: ListTile(
                          leading: Icon(
                            item['icon'] as IconData,
                            color: AppTheme.yachtClubLight,
                          ),
                          title: Text(
                            item['label'] as String,
                            style: const TextStyle(
                              color: AppTheme.yachtClubLight,
                            ),
                          ),
                          onTap: item['onTap'] as VoidCallback,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await loginController.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logout successful'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Student Dashboard',
        userEmail:
            loginController.studentName ??
            loginController.email.split('@').first,
      ),
      backgroundColor: Colors.grey.shade50,
      drawer: _buildDrawer(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildStudentIdCard(),
        ),
      ),
    );
  }
}
