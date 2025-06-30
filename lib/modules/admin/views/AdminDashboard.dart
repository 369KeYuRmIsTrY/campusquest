import 'package:campusquest/modules/admin/views/ExportStudentDataPage.dart';
import 'package:campusquest/modules/admin/views/Program_Courses.dart';
import 'package:campusquest/modules/admin/views/TimeSlotScreen.dart';
import 'package:campusquest/modules/admin/views/assignteacher.dart';
import 'package:campusquest/modules/admin/views/classroom_screen.dart';
import 'package:campusquest/modules/admin/views/course_screen.dart';
import 'package:campusquest/modules/admin/views/department_screen.dart';
import 'package:campusquest/modules/admin/views/enrollment_screen.dart';
import 'package:campusquest/modules/admin/views/instructor_screen.dart';
import 'package:campusquest/modules/admin/views/programscreen.dart';
import 'package:campusquest/modules/admin/views/semester_screen.dart';
import 'package:campusquest/modules/login/views/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_animate/flutter_animate.dart'
    show AnimateIfVisible, AnimateIfVisibleWrapper;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../controllers/login_controller.dart'; // Ensure this path is correct
import '../../../controllers/theme_controller.dart';
import '../../../theme/theme.dart'; // Import AppTheme
import '../../../widgets/common_app_bar.dart'; // Import CommonAppBar
import '../views/EventsPage.dart';
import 'Update_student.dart';
import 'TimetablePage.dart'; // Import the correct TimetablePage
import 'createassignmentpageform.dart'; // Import the correct CreateAssignmentPageForm
import 'AdminExamsPage.dart';

// Assuming you have initialized Supabase in your main.dart file
final supabase = Supabase.instance.client;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _programsCount = 0;
  int _studentsCount = 0;
  int _instructorsCount = 0;
  int _classroomsCount = 0;
  int _coursesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      // Using the correct table names from the schema
      final programsResponse = await supabase.from('program').select('count');
      final studentsResponse = await supabase.from('student').select('count');
      final instructorsResponse = await supabase
          .from('instructor')
          .select('count');
      final classroomsResponse = await supabase
          .from('classroom')
          .select('count');
      final coursesResponse = await supabase.from('course').select('count');

      setState(() {
        // Using null-aware operators to handle potential null values
        _programsCount = programsResponse[0]['count'] ?? 0;
        _studentsCount = studentsResponse[0]['count'] ?? 0;
        _instructorsCount = instructorsResponse[0]['count'] ?? 0;
        _classroomsCount = classroomsResponse[0]['count'] ?? 0;
        _coursesCount = coursesResponse[0]['count'] ?? 0;
      });
    } catch (e) {
      print('Error fetching counts: $e'); // Print error to console

      // Default all counts to 0 in case of error
      setState(() {
        _programsCount = 0;
        _studentsCount = 0;
        _instructorsCount = 0;
        _classroomsCount = 0;
        _coursesCount = 0;
      });

      // Show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching counts: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<LoginController>(context).role;
    final loginController = Provider.of<LoginController>(
      context,
    ); // Get loginController instance

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Admin Dashboard',
        userEmail:
            loginController.studentName ??
            loginController.email
                .split('@')
                .first, // Use studentName or part of email
        onNotificationPressed: () {
          // Handle notification press
        },
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ), // Set icon color to white
                onPressed: () => Scaffold.of(context).openDrawer(),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightBackground, // Start color
              Colors.white, // End color for a subtle gradient
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ), // Changed color
                ),
                const SizedBox(height: 8),
                const Text(
                  'Heres an overview of your system.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Counters Section
                _buildCountersSection(context),

                const SizedBox(height: 24),

                // Quick Actions Section
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ), // Changed color
                ),
                const SizedBox(height: 12),

                _buildButtonsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Counters Section - Made responsive
  Widget _buildCountersSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletOrLarger = constraints.maxWidth > 600;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTabletOrLarger ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isTabletOrLarger ? 1.5 : 1.2,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            final counters = [
              {
                'label': 'Programs',
                'count': _programsCount,
                'color': Colors.purple,
              },
              {
                'label': 'Students',
                'count': _studentsCount,
                'color': Colors.teal,
              },
              {
                'label': 'Instructors',
                'count': _instructorsCount,
                'color': Colors.blue,
              },
              {
                'label': 'Classrooms',
                'count': _classroomsCount,
                'color': Colors.green,
              },
              {
                'label': 'Courses',
                'count': _coursesCount,
                'color': Colors.orange,
              },
            ];

            // Add animation to each card with a staggered delay
            return _buildCounterCard(
                  counters[index]['label'] as String,
                  counters[index]['count'] as int,
                  counters[index]['color'] as Color,
                )
                .animate()
                .fadeIn(duration: 600.ms, delay: (index * 200).ms)
                .scale(duration: 600.ms, delay: (index * 200).ms);
          },
        );
      },
    );
  }

  // Counter Card
  Widget _buildCounterCard(String label, int count, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    color.withAlpha((255 * 0.1).toInt()),
                    color.withAlpha((255 * 0.3).toInt()),
                    value,
                  )!,
                  Color.lerp(
                    color.withAlpha((255 * 0.3).toInt()),
                    color.withAlpha((255 * 0.1).toInt()),
                    value,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, value],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.95 + 0.05 * value,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Buttons Section - Made fully responsive
  Widget _buildButtonsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletOrLarger = constraints.maxWidth > 600;
        final buttonDataList = [
          {
            'label': 'Add Instructor',
            'icon': Icons.person_add,
            'color': Colors.blue,
            'route': const AddInstructorPage(),
          },
          {
            'label': 'Assign Instructors',
            'icon': Icons.assignment_ind,
            'color': Colors.green,
            'route': const TeachesScreen(),
          },
          {
            'label': 'Manage Programs',
            'icon': Icons.school,
            'color': Colors.purple,
            'route': const ProgramScreen(),
          },
          {
            'label': 'Update Student',
            'icon': Icons.add_box,
            'color': Colors.orange,
            'route': BulkStudentUpdateScreen(),
          },
          {
            'label': 'Create Event',
            'icon': Icons.event,
            'color': Colors.red,
            'route': AddEventPage(),
          },
          {
            'label': 'Export Student Data',
            'icon': Icons.download,
            'color': Colors.brown,
            'route': const StudentScreen(),
          },
        ];

        return AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTabletOrLarger ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isTabletOrLarger ? 1.3 : 1.0,
            ),
            itemCount: buttonDataList.length,
            itemBuilder: (context, index) {
              final buttonData = buttonDataList[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 900),
                columnCount: isTabletOrLarger ? 3 : 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    delay: Duration(milliseconds: 150 * index),
                    child: _buildActionButton(
                      context,
                      label: buttonData['label'] as String,
                      icon: buttonData['icon'] as IconData,
                      color: buttonData['color'] as Color,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => buttonData['route'] as Widget,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Action Button for Quick Actions
  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: screenWidth * 0.1, color: color),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Drawer (Side Navigation)
  Widget _buildDrawer(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    final themeController = Provider.of<ThemeController>(context);

    // List of drawer items (icon, label, onTap)
    final drawerItems = [
      {
        'icon': Icons.dashboard,
        'label': 'Dashboard',
        'onTap': () {
          Navigator.pop(context);
        },
      },
      {
        'icon': Icons.person,
        'label': 'Instructors',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInstructorPage()),
          );
        },
      },
      {
        'icon': Icons.event,
        'label': 'Events',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEventPage()),
          );
        },
      },
      {
        'icon': Icons.schedule,
        'label': 'Timetable',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimetablePageAdmin()),
          );
        },
      },
      {
        'icon': Icons.book,
        'label': 'Courses',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseScreen()),
          );
        },
      },
      {
        'icon': Icons.class_,
        'label': 'Classrooms',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClassroomScreen()),
          );
        },
      },
      {
        'icon': Icons.business,
        'label': 'Departments',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DepartmentScreen()),
          );
        },
      },
      {
        'icon': Icons.layers,
        'label': 'Programs',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProgramScreen()),
          );
        },
      },
      {
        'icon': Icons.assignment,
        'label': 'Assignments',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreateAssignmentFormPage(
                    courseId: '',
                    semesterId: '',
                    dueDate: DateTime.now(),
                    onAssignmentCreated: () {},
                  ),
            ),
          );
        },
      },
      {
        'icon': Icons.receipt,
        'label': 'Enrollments',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EnrollmentScreen()),
          );
        },
      },
      {
        'icon': Icons.group,
        'label': 'Students',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BulkStudentUpdateScreen()),
          );
        },
      },
      {
        'icon': Icons.date_range,
        'label': 'Semesters',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SemesterScreen()),
          );
        },
      },
      {
        'icon': Icons.access_time,
        'label': 'Time Slots',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimeSlotScreen()),
          );
        },
      },
      {
        'icon': Icons.link,
        'label': 'Program Courses',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProgramCoursesScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.file_download,
        'label': 'Export Data',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentScreen()),
          );
        },
      },
      {
        'icon': Icons.assignment_turned_in,
        'label': 'Exams',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminExamsPage()),
          );
        },
      },
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'onTap': () async {
          await loginController.logout();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
      },
    ];

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/admin.png'),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loginController.studentName ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    loginController.role,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
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
                            color: Colors.white,
                          ),
                          title: Text(
                            item['label'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: item['onTap'] as VoidCallback,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
