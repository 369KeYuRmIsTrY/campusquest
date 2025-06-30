import 'package:campusquest/modules/admin/views/instructor_screen.dart';
import 'package:campusquest/modules/student/views/StudentDashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_controller.dart';
import '../modules/admin/views/AdminDashboard.dart';
import '../modules/admin/views/EventsPage.dart';
import '../modules/admin/views/TimetablePage.dart';
import '../modules/instructor/views/AttendancePage.dart';
import '../modules/instructor/views/ClassSchedule.dart';
import '../modules/instructor/views/InstructorDashboard.dart';
import '../modules/instructor/views/createassignmentpage.dart';
import '../modules/student/views/AssignmentsPage.dart';
import '../modules/student/views/NotesPage.dart';
import '../modules/student/views/ProfilePage.dart';
import '../modules/student/views/TimetablePage.dart';
import '../theme/theme.dart'; // Import AppTheme
import '../modules/student/views/ExamsPage.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    final userRole = loginController.role ?? 'student';

    final roleBasedPages = _getRoleBasedPages(userRole);
    final roleBasedNavItems = _getRoleBasedNavItems(userRole);

    // final theme = Theme.of(context); // Access the current theme

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: SizedBox(
          key: ValueKey<int>(_currentIndex),
          child: roleBasedPages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor:
              Colors.transparent, // Set to transparent to show the gradient
          selectedItemColor:
              Colors.white, // Changed to white for visibility on dark gradient
          unselectedItemColor:
              AppTheme.greyishBlue, // Use greyishBlue for unselected items
          currentIndex: _currentIndex,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: roleBasedNavItems,
        ),
      ),
    );
  }

  List<Widget> _getRoleBasedPages(String role) {
    switch (role) {
      case 'admin':
        return [
          const AdminDashboard(),
          const AddInstructorPage(),
          const AddEventPage(),
          const TimetablePageAdmin()
        ];
      case 'instructor':
        return [
          const InstructorDashboard(),
          const ClassSchedule(),
          const UploadAssignmentsPage(),
          const AttendancePage()
        ];
      case 'student':
      default:
        return [
          StudentDashboard(),
          TimetablePage(),
          AssignmentsPage(),
          ExamsPage(),
          const NotesPage(),
          ProfilePage()
        ];
    }
  }

  List<BottomNavigationBarItem> _getRoleBasedNavItems(String role) {
    switch (role) {
      case 'admin':
        return [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Instructor'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
              icon: Icon(Icons.timelapse), label: 'Time Table'),
        ];
      case 'instructor':
        return [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: 'Assignments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle), label: 'Attendance'),
        ];
      case 'student':
      default:
        return [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.access_time), label: 'Timetable'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Assignments'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
    }
  }
}

// Remove this extension as it's no longer needed
// extension on ThemeData {
//   get bottomAppBarColor => null;
// }
