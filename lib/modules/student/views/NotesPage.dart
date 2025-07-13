import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/login_controller.dart';
import '../../../widgets/chapter_details_page.dart';
import '../../../widgets/subject_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Models ---
class Note {
  final int noteId;
  final int courseId;
  final String title;
  final String? description;
  final String? filePath;
  final int uploadedBy;
  final DateTime? uploadDate;

  Note({
    required this.noteId,
    required this.courseId,
    required this.title,
    this.description,
    this.filePath,
    required this.uploadedBy,
    this.uploadDate,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      noteId: json['note_id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      filePath: json['file_path'],
      uploadedBy: json['uploaded_by'],
      uploadDate:
          json['upload_date'] != null
              ? DateTime.tryParse(json['upload_date'].toString())
              : null,
    );
  }
}

class Course {
  final int courseId;
  final String courseName;
  final List<Note> notes;

  Course({
    required this.courseId,
    required this.courseName,
    required this.notes,
  });
}

// --- Controller ---
class _NotesController {
  final _supabase = Supabase.instance.client;

  Future<List<Course>> fetchCoursesWithNotesForStudent(int studentId) async {
    // 1. Get enrollments
    final enrollments = await _supabase
        .from('enrollment')
        .select('course_id')
        .eq('student_id', studentId)
        .eq('enrollment_status', 'Active');
    print('Enrollments: $enrollments');

    if (enrollments.isEmpty) return [];
    final courseIds = enrollments.map((e) => e['course_id']).toList();

    // 2. Fetch course details and notes for each course
    List<Course> courses = [];
    for (var courseId in courseIds) {
      final courseResult = await _supabase
          .from('course')
          .select('course_id, course_name')
          .eq('course_id', courseId);
      if (courseResult.isEmpty) continue;
      final course = courseResult.first;
      final notesResult = await _supabase
          .from('notes')
          .select('*')
          .eq('course_id', courseId);
      print('Notes for course $courseId: $notesResult');
      final notes = notesResult.map<Note>((n) => Note.fromJson(n)).toList();
      if (notes.isNotEmpty) {
        courses.add(
          Course(
            courseId: course['course_id'],
            courseName: course['course_name'],
            notes: notes,
          ),
        );
      }
    }
    return courses;
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _supabase = Supabase.instance.client;
  final _controller = _NotesController();
  bool _isLoading = true;
  List<Course> _coursesWithNotes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      // Fetch studentId from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('studentId');
      if (studentId == null) {
        throw Exception('Student ID is null in SharedPreferences.');
      }
      print('Student ID from SharedPreferences: $studentId');
      final enrollments = await _supabase
          .from('enrollment')
          .select('enrollment_id, student_id, course_id, enrollment_status')
          .eq('student_id', studentId);
      print('All enrollments for student: $enrollments');
      final activeEnrollments =
          enrollments.where((e) => e['enrollment_status'] == 'Active').toList();
      print('Active enrollments: $activeEnrollments');
      final courseIds = activeEnrollments.map((e) => e['course_id']).toList();

      // 2. Fetch course details and notes for each course
      List<Course> courses = [];
      for (var courseId in courseIds) {
        final courseResult = await _supabase
            .from('course')
            .select('course_id, course_name')
            .eq('course_id', courseId);
        if (courseResult.isEmpty) continue;
        final course = courseResult.first;
        final notesResult = await _supabase
            .from('notes')
            .select('*')
            .eq('course_id', courseId);
        print('Notes for course $courseId: $notesResult');
        final notes = notesResult.map<Note>((n) => Note.fromJson(n)).toList();
        if (notes.isNotEmpty) {
          courses.add(
            Course(
              courseId: course['course_id'],
              courseName: course['course_name'],
              notes: notes,
            ),
          );
        }
      }
      setState(() {
        _coursesWithNotes = courses;
        _isLoading = false;
      });
      print('Courses with Notes: ' + courses.toString());
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notes:  [31m${e.toString()} [0m';
        _isLoading = false;
      });
      print('Error fetching notes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notes / Materials',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchNotes,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _coursesWithNotes.isEmpty
              ? const Center(
                child: Text('No notes available for your courses.'),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children:
                      _coursesWithNotes.map((course) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotesViewPage(
                                      courseId: 'CRS${course.courseId}',
                                      courseName: course.courseName,
                                      chapters:
                                          course.notes
                                              .map(
                                                (note) => {
                                                  'title': note.title,
                                                  'description':
                                                      note.description ??
                                                      'No description available',
                                                  'file_path':
                                                      note.filePath ?? '',
                                                  'id': note.noteId.toString(),
                                                },
                                              )
                                              .toList(),
                                      notes:
                                          [], // Pass an empty list of Map<String, dynamic> to fix the linter error
                                    ),
                              ),
                            );
                          },
                          child: SubjectCard(
                            code: 'CRS${course.courseId}',
                            name: course.courseName,
                          ),
                        );
                      }).toList(),
                ),
              ),
    );
  }
}
