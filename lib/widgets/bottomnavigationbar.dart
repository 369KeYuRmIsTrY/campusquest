import 'package:campusquest/modules/admin/views/instructor_screen.dart';
import 'package:campusquest/modules/student/views/StudentDashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_controller.dart';
import '../modules/admin/views/AdminDashboard.dart';
import '../modules/admin/views/EventsPage.dart';
import '../modules/admin/views/TimetablePage.dart';
import '../modules/admin/views/timetablescreen.dart';
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
import '../modules/student/views/StudentEventsPage.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _currentIndex = 0;

  final List<IconData> navIcons = [
    Icons.dashboard,
    Icons.person,
    Icons.event,
    Icons.timelapse,
    // ...add more as needed
  ];

  final List<String> navLabels = [
    'Dashboard',
    'Instructor',
    'Events',
    'Time Table',
    // ...add more as needed
  ];

  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    final userRole = loginController.role ?? 'student';

    final roleBasedPages = _getRoleBasedPages(userRole);
    final roleBasedNavItems = _getRoleBasedNavItems(userRole);

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
        height: 70,
        color: AppTheme.yachtClubBlue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(roleBasedNavItems.length, (index) {
            final isSelected = _currentIndex == index;
            final iconData = getIconData(roleBasedNavItems[index]);
            final label = getLabel(roleBasedNavItems[index]);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Transform.translate(
                      offset: Offset(0, isSelected ? -20 : 0),
                      child:
                          isSelected
                              ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.yachtClubLight,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  iconData,
                                  size: 30,
                                  color: AppTheme.yachtClubBlue,
                                ),
                              )
                              : Icon(
                                iconData,
                                size: 24,
                                color: AppTheme.yachtClubLight,
                              ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected ? AppTheme.yachtClubLight : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
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
          const TimetableScreen(),
        ];
      case 'instructor':
        return [
          const InstructorDashboard(),
          const ClassSchedule(),
          const UploadAssignmentsPage(),
          const AttendancePage(),
        ];
      case 'student':
      default:
        return [
          StudentDashboard(),
          const StudentEventsPage(),
          TimetablePage(),
          ProfilePage(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getRoleBasedNavItems(String role) {
    switch (role) {
      case 'admin':
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Instructor',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.timelapse),
            label: 'Time Table',
          ),
        ];
      case 'instructor':
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
        ];
      case 'student':
      default:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
    }
  }

  IconData getIconData(BottomNavigationBarItem item) {
    if (item.icon is Icon) {
      return (item.icon as Icon).icon!;
    }
    return Icons.circle;
  }

  String getLabel(BottomNavigationBarItem item) {
    return item.label ?? '';
  }
}

// Remove this extension as it's no longer needed
// extension on ThemeData {
//   get bottomAppBarColor => null;
// }
