import 'package:flutter/material.dart';
import 'package:campusquest/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:campusquest/controllers/login_controller.dart';
import 'package:intl/intl.dart';

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

  // Controllers for edit dialog
  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  @override
  void dispose() {
    _marksController.dispose();
    _feedbackController.dispose();
    super.dispose();
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

      // 3. For each course, get assignments and their submissions with marks
      List<Map<String, dynamic>> courseResults = [];
      for (var course in courses) {
        // Get assignments for this course
        final assignments = await _supabase
            .from('assignment')
            .select('assignment_id, title, max_marks')
            .eq('course_id', course['course_id']);

        if (assignments.isEmpty) {
          courseResults.add({
            'course': course['course_name'],
            'assignments': [],
          });
          continue;
        }

        List<Map<String, dynamic>> assignmentResults = [];
        for (var assignment in assignments) {
          // Get submissions for this assignment
          final submissions = await _supabase
              .from('submission')
              .select('''
                submission_id, 
                student_id, 
                submission_date, 
                marks_obtained, 
                feedback,
                student!inner(name)
              ''')
              .eq('assignment_id', assignment['assignment_id']);

          final students =
              submissions
                  .map(
                    (s) => {
                      'submission_id': s['submission_id'],
                      'name': s['student']['name'],
                      'marks': s['marks_obtained'] ?? 'Not graded',
                      'submission_date': s['submission_date'],
                      'feedback': s['feedback'],
                    },
                  )
                  .toList();

          assignmentResults.add({
            'assignment_title': assignment['title'],
            'max_marks': assignment['max_marks'],
            'students': students,
          });
        }

        courseResults.add({
          'course': course['course_name'],
          'assignments': assignmentResults,
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

  Future<void> _editSubmission(
    Map<String, dynamic> submission,
    String assignmentTitle,
    String studentName,
    double? maxMarks,
  ) async {
    // Initialize controllers with current values
    _marksController.text = submission['marks']?.toString() ?? '';
    _feedbackController.text = submission['feedback']?.toString() ?? '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Edit Submission'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Assignment: $assignmentTitle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Student: $studentName',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (maxMarks != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Maximum Marks: $maxMarks',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  TextField(
                    controller: _marksController,
                    decoration: InputDecoration(
                      labelText: 'Marks',
                      hintText: 'Enter marks',
                      prefixIcon: Icon(Icons.score, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      labelText: 'Feedback',
                      hintText: 'Enter feedback (optional)',
                      prefixIcon: Icon(
                        Icons.feedback,
                        color: Colors.deepPurple,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_marksController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter marks')),
                    );
                    return;
                  }

                  final marks = double.tryParse(_marksController.text.trim());
                  if (marks == null || marks < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter valid marks')),
                    );
                    return;
                  }

                  if (maxMarks != null && marks > maxMarks) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Marks cannot exceed maximum marks ($maxMarks)',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'marks': marks,
                    'feedback': _feedbackController.text.trim(),
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      await _updateSubmission(
        submission['submission_id'],
        result['marks'],
        result['feedback'],
      );
    }
  }

  Future<void> _updateSubmission(
    int submissionId,
    double marks,
    String feedback,
  ) async {
    try {
      setState(() => _isLoading = true);

      await _supabase
          .from('submission')
          .update({
            'marks_obtained': marks,
            'feedback': feedback.isEmpty ? null : feedback,
          })
          .eq('submission_id', submissionId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the data
      await _fetchResults();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating submission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter courses, assignments, and students by search query
    final filteredCourses =
        _courses.where((course) {
          final courseName = course['course']?.toString().toLowerCase() ?? '';
          final assignments = (course['assignments'] as List<dynamic>?) ?? [];

          // Check if any assignment title matches
          final hasMatchingAssignment = assignments.any((assignment) {
            final assignmentTitle =
                assignment['assignment_title']?.toString().toLowerCase() ?? '';
            return assignmentTitle.contains(_searchQuery);
          });

          // Check if any student name matches
          final hasMatchingStudent = assignments.any((assignment) {
            final students = (assignment['students'] as List<dynamic>?) ?? [];
            return students.any(
              (student) => student['name'].toString().toLowerCase().contains(
                _searchQuery,
              ),
            );
          });

          return courseName.contains(_searchQuery) ||
              hasMatchingAssignment ||
              hasMatchingStudent;
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
                                final assignments =
                                    (course['assignments'] as List<dynamic>?) ??
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
                                        assignments.isEmpty
                                            ? [
                                              const ListTile(
                                                title: Text(
                                                  'No assignments found.',
                                                ),
                                              ),
                                            ]
                                            : assignments.map<Widget>((
                                              assignment,
                                            ) {
                                              final assignmentTitle =
                                                  assignment['assignment_title'] ??
                                                  '';
                                              final students =
                                                  (assignment['students']
                                                      as List<dynamic>?) ??
                                                  [];

                                              return ExpansionTile(
                                                title: Text(
                                                  assignmentTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                children:
                                                    students.isEmpty
                                                        ? [
                                                          const ListTile(
                                                            title: Text(
                                                              'No submissions found.',
                                                            ),
                                                          ),
                                                        ]
                                                        : students
                                                            .where(
                                                              (student) =>
                                                                  _searchQuery
                                                                      .isEmpty ||
                                                                  student['name']
                                                                      .toString()
                                                                      .toLowerCase()
                                                                      .contains(
                                                                        _searchQuery,
                                                                      ),
                                                            )
                                                            .map<Widget>(
                                                              (
                                                                student,
                                                              ) => ListTile(
                                                                leading: const Icon(
                                                                  Icons.person,
                                                                  color:
                                                                      Colors
                                                                          .deepPurple,
                                                                ),
                                                                title: Text(
                                                                  student['name'] ??
                                                                      '',
                                                                ),
                                                                subtitle: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    if (student['submission_date'] !=
                                                                        null)
                                                                      Text(
                                                                        'Submitted: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(student['submission_date']))}',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                    if (student['feedback'] !=
                                                                            null &&
                                                                        student['feedback']
                                                                            .toString()
                                                                            .isNotEmpty)
                                                                      Text(
                                                                        'Feedback: ${student['feedback']}',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                                trailing: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            student['marks'] ==
                                                                                    'Not graded'
                                                                                ? Colors.orange.shade100
                                                                                : Colors.green.shade100,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      child: Text(
                                                                        'Marks: ${student['marks']}',
                                                                        style: TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              student['marks'] ==
                                                                                      'Not graded'
                                                                                  ? Colors.orange.shade800
                                                                                  : Colors.green.shade800,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color:
                                                                            Colors.blue,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      onPressed:
                                                                          () => _editSubmission(
                                                                            student,
                                                                            assignmentTitle,
                                                                            student['name'],
                                                                            assignment['max_marks']?.toDouble(),
                                                                          ),
                                                                      tooltip:
                                                                          'Edit marks and feedback',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            )
                                                            .toList(),
                                              );
                                            }).toList(),
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
