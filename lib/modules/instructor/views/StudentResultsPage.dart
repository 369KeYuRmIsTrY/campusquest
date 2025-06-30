import 'package:flutter/material.dart';
import 'package:campusquest/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:campusquest/controllers/login_controller.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  String _searchQuery = '';
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final loginController = Provider.of<LoginController>(
        context,
        listen: false,
      );
      final instructorId = loginController.instructorId;
      if (instructorId == null) throw Exception('Instructor ID not found');

      // 1. Get courses taught by this instructor
      final teaches = await _supabase
          .from('teaches')
          .select('course_id')
          .eq('instructor_id', instructorId);

      final courseIds = teaches.map((t) => t['course_id']).toList();

      if (courseIds.isEmpty) {
        setState(() {
          _courses = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Get course details
      final courses = await _supabase
          .from('course')
          .select('course_id, course_name')
          .inFilter('course_id', courseIds);

      // 3. For each course, get enrolled students and their marks
      List<Map<String, dynamic>> courseResults = [];
      for (var course in courses) {
        final enrollments = await _supabase
            .from('enrollment')
            .select('student_id, marks, student!inner(name)')
            .eq('course_id', course['course_id']);

        final students =
            enrollments
                .map(
                  (e) => {
                    'name': e['student']['name'],
                    'marks': e['marks'] ?? 'N/A',
                  },
                )
                .toList();

        courseResults.add({
          'course': course['course_name'],
          'students': students,
        });
      }

      setState(() {
        _courses = courseResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching results: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter courses and students by search query
    final filteredCourses =
        _courses.where((course) {
          final courseName = course['course']?.toString().toLowerCase() ?? '';
          final students = (course['students'] as List<dynamic>?) ?? [];
          final hasMatchingStudent = students.any(
            (student) =>
                student['name'].toString().toLowerCase().contains(_searchQuery),
          );
          return courseName.contains(_searchQuery) || hasMatchingStudent;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Results',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by student or course',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child:
                        filteredCourses.isEmpty
                            ? const Center(child: Text('No results found.'))
                            : ListView.builder(
                              itemCount: filteredCourses.length,
                              itemBuilder: (context, courseIndex) {
                                final course = filteredCourses[courseIndex];
                                final students =
                                    (course['students'] as List<dynamic>?) ??
                                    [];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  elevation: 3,
                                  child: ExpansionTile(
                                    title: Text(
                                      course['course'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    children:
                                        students.isEmpty
                                            ? [
                                              const ListTile(
                                                title: Text(
                                                  'No students enrolled.',
                                                ),
                                              ),
                                            ]
                                            : students
                                                .where(
                                                  (student) =>
                                                      _searchQuery.isEmpty ||
                                                      student['name']
                                                          .toString()
                                                          .toLowerCase()
                                                          .contains(
                                                            _searchQuery,
                                                          ),
                                                )
                                                .map<Widget>(
                                                  (student) => ListTile(
                                                    leading: const Icon(
                                                      Icons.person,
                                                      color: Colors.deepPurple,
                                                    ),
                                                    title: Text(
                                                      student['name'] ?? '',
                                                    ),
                                                    trailing: Text(
                                                      'Marks: ${student['marks'] ?? 'N/A'}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
