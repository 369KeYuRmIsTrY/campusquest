import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:campusquest/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:campusquest/controllers/login_controller.dart';
import 'package:campusquest/theme/theme.dart';
import 'package:campusquest/utils/open_file_plus.dart';

class Course {
  final String courseId;
  final String courseName;
  final int semesterId;
  final int semesterNumber;
  Course({
    required this.courseId,
    required this.courseName,
    required this.semesterId,
    required this.semesterNumber,
  });
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['course_id'].toString(),
      courseName: json['course_name'] ?? 'Unnamed Course',
      semesterId: json['semester_id'] as int? ?? 1,
      semesterNumber: json['semester_number'] as int? ?? 1,
    );
  }
}

class UploadAssignmentsPage extends StatefulWidget {
  const UploadAssignmentsPage({Key? key}) : super(key: key);

  @override
  _UploadAssignmentsPageState createState() => _UploadAssignmentsPageState();
}

class _UploadAssignmentsPageState extends State<UploadAssignmentsPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _maxMarksController = TextEditingController();

  // State variables
  List<Course> courses = [];
  Map<String, List<Map<String, dynamic>>> courseAssignments = {};
  String? selectedCourseId; // Single selected course
  bool _isLoading = false;
  bool _isEditing = false;
  int? _currentEditId;
  bool _isSaving = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // Instructor information
  int? _instructorId;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;

  // File variables
  PlatformFile? _pickedFile;
  String? _uploadedFileUrl;
  String? _uploadedFileName;

  // Constants
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  final List<String> _allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xlsx',
    'txt',
  ];

  // Supabase client
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fabAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _dueDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeData();
    Future.delayed(const Duration(milliseconds: 500), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _maxMarksController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _loadInstructorData();
      if (_instructorId != null) {
        await Future.wait([_fetchCourses(), _fetchAssignments()]);
        if (courses.isNotEmpty && selectedCourseId == null) {
          setState(() => selectedCourseId = courses.first.courseId);
        }
      }
    } catch (e) {
      print(e);
      _showErrorMessage('Error initializing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInstructorData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final savedInstructorId = prefs.getInt('instructorId');
    if (savedInstructorId != null) {
      setState(() {
        _instructorId = savedInstructorId;
        _isLoading = false;
      });
      return;
    }

    if (userId != null) {
      try {
        final parsedUserId = int.tryParse(userId);
        if (parsedUserId == null) throw Exception('Invalid user ID format');

        final instructorData =
            await supabase
                .from('instructor')
                .select('instructor_id')
                .eq('user_id', parsedUserId)
                .maybeSingle();

        if (instructorData != null) {
          final id = instructorData['instructor_id'] as int;
          await prefs.setInt('instructorId', id);
          setState(() => _instructorId = id);
        } else {
          _showErrorMessage('No instructor profile found');
        }
      } catch (e) {
        _showErrorMessage('Error fetching instructor data: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _showErrorMessage('No user ID found');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCourses() async {
    if (_instructorId == null) return;
    try {
      final response = await supabase
          .from('teaches')
          .select(
            'course:course_id(course_id, course_name, semester_id), semester:semester_id(semester_id, semester_number)',
          )
          .eq('instructor_id', _instructorId!);

      print('Teaches query response: $response');
      setState(() {
        courses =
            response
                .map<Course>(
                  (json) => Course.fromJson({
                    'course_id': json['course']['course_id'],
                    'course_name': json['course']['course_name'],
                    'semester_id': json['semester']['semester_id'],
                    'semester_number': json['semester']['semester_number'],
                  }),
                )
                .toList();
      });
      print(
        'Processed courses with semester numbers: ${courses.map((c) => '${c.courseName} (Sem ${c.semesterNumber})').join(', ')}',
      );
    } catch (e) {
      _showErrorMessage('Error fetching courses: $e');
    }
  }

  Future<void> _fetchAssignments() async {
    if (_instructorId == null) return;
    final response = await supabase
        .from('assignment')
        .select()
        .eq('created_by', _instructorId!)
        .order('due_date', ascending: false);

    final assignmentsList = List<Map<String, dynamic>>.from(response);
    setState(() {
      courseAssignments = {};
      for (var assignment in assignmentsList) {
        final courseId = assignment['course_id'].toString();
        if (!courseAssignments.containsKey(courseId)) {
          courseAssignments[courseId] = [];
        }
        courseAssignments[courseId]!.add(assignment);
      }
    });
  }

  Future<void> _addOrUpdateAssignment() async {
    if (_instructorId == null) {
      _showErrorMessage('Instructor ID not found');
      return;
    }
    if (!_validateInputs()) return;
    setState(() => _isSaving = true);
    try {
      // Find the selected course to get its semester_id
      final selectedCourse = courses.firstWhere(
        (course) => course.courseId == selectedCourseId,
        orElse: () => throw Exception('Selected course not found'),
      );

      final assignmentData = {
        'course_id': int.parse(selectedCourseId!),
        'semester_id': selectedCourse.semesterId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'file_path': _uploadedFileUrl,
        'due_date': _dueDateController.text,
        'max_marks': int.parse(_maxMarksController.text.trim()),
        'created_by': _instructorId!,
      };
      print('Creating assignment with data: $assignmentData');
      print(
        'Selected course: ${selectedCourse.courseName} (Sem ${selectedCourse.semesterNumber}, ID: ${selectedCourse.semesterId})',
      );
      if (_isEditing && _currentEditId != null) {
        await supabase
            .from('assignment')
            .update(assignmentData)
            .eq('assignment_id', _currentEditId!);
        _showSuccessMessage('Assignment updated successfully');
      } else {
        final response =
            await supabase.from('assignment').insert(assignmentData).select();
        if (response.isNotEmpty)
          _showSuccessMessage('Assignment added successfully');
      }
      _resetForm();
      await _fetchAssignments();
    } catch (e) {
      _showErrorMessage('Error saving assignment: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _validateInputs() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('Please enter a title');
      return false;
    }
    if (_dueDateController.text.isEmpty) {
      _showErrorMessage('Please select a due date');
      return false;
    }
    if (_maxMarksController.text.trim().isEmpty ||
        int.tryParse(_maxMarksController.text.trim()) == null) {
      _showErrorMessage('Please enter valid maximum marks');
      return false;
    }
    if (selectedCourseId == null) {
      _showErrorMessage('Please select a course');
      return false;
    }
    return true;
  }

  Future<void> _pickFile() async {
    if (_instructorId == null) {
      _showErrorMessage('Instructor ID not found');
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (result != null && result.files.single.size <= _maxFileSizeBytes) {
        setState(() {
          _pickedFile = result.files.single;
          _uploadedFileName = _pickedFile!.name;
        });
        await _uploadFile();
      } else {
        _showErrorMessage('File too large (max 10MB) or invalid type');
      }
    } catch (e) {
      _showErrorMessage('Error picking file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_instructorId == null || _pickedFile == null) return;
    setState(() => _isLoading = true);
    try {
      final fileBytes =
          _pickedFile!.bytes ?? await File(_pickedFile!.path!).readAsBytes();
      final fileName =
          '$_instructorId/assignments/${DateTime.now().millisecondsSinceEpoch}-${_pickedFile!.name}';
      await supabase.storage
          .from('assignments')
          .uploadBinary(fileName, fileBytes);
      final url = supabase.storage.from('assignments').getPublicUrl(fileName);
      setState(() => _uploadedFileUrl = url);
      _showSuccessMessage('File uploaded successfully');
    } catch (e) {
      _showErrorMessage('Error uploading file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editAssignment(Map<String, dynamic> assignment) {
    setState(() {
      _isEditing = true;
      _currentEditId = assignment['assignment_id'];
      _titleController.text = assignment['title'] ?? '';
      _descriptionController.text = assignment['description'] ?? '';
      _dueDateController.text = assignment['due_date'] ?? '';
      _maxMarksController.text = assignment['max_marks'].toString();
      _uploadedFileUrl = assignment['file_path'];
      _uploadedFileName = assignment['file_path']?.split('/').last;
      selectedCourseId = assignment['course_id'].toString();
    });
    _showAddEditDialog(assignment: assignment);
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _currentEditId = null;
      _titleController.clear();
      _descriptionController.clear();
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _maxMarksController.clear();
      _pickedFile = null;
      _uploadedFileUrl = null;
      _uploadedFileName = null;
      // Do not reset selectedCourseId; keep it as the current course from dropdown
    });
  }

  Future<void> _deleteAssignment(int assignmentId) async {
    if (_instructorId == null) return;
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('assignment')
          .delete()
          .eq('assignment_id', assignmentId);
      _showSuccessMessage('Assignment deleted successfully');
      await _fetchAssignments();
    } catch (e) {
      _showErrorMessage('Error deleting assignment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      setState(() => _isLoading = true);

      // Download the file first
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Use FileOpener to open the file
        await FileOpener.openEventFile(context, filePath);
      } else {
        _showErrorMessage('Failed to download file');
      }
    } catch (e) {
      _showErrorMessage('Error handling file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showErrorMessage(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? assignment}) {
    if (_instructorId == null) {
      _showErrorMessage('Instructor ID not found');
      return;
    }
    final bool isEditing = assignment != null;
    final titleController = TextEditingController(
      text: isEditing ? assignment!['title'] : _titleController.text,
    );
    final descriptionController = TextEditingController(
      text:
          isEditing ? assignment!['description'] : _descriptionController.text,
    );
    final dueDateController = TextEditingController(
      text: isEditing ? assignment!['due_date'] : _dueDateController.text,
    );
    final maxMarksController = TextEditingController(
      text:
          isEditing
              ? assignment!['max_marks'].toString()
              : _maxMarksController.text,
    );
    String? dialogSelectedCourseId =
        isEditing ? assignment!['course_id'].toString() : selectedCourseId;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_note : Icons.add_box,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit Assignment' : 'Add New Assignment',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: titleController,
                    labelText: 'Assignment Title',
                    prefixIcon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descriptionController,
                    labelText: 'Description',
                    prefixIcon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: dueDateController,
                    labelText: 'Due Date',
                    prefixIcon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null)
                        dueDateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(pickedDate);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: maxMarksController,
                    labelText: 'Max Marks',
                    prefixIcon: Icons.score,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: dialogSelectedCourseId,
                    decoration: InputDecoration(
                      labelText: 'Course',
                      prefixIcon: Icon(Icons.book, color: Colors.deepPurple),
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
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                    ),
                    items:
                        courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course.courseId,
                            child: Text(
                              '${course.courseName} (Sem ${course.semesterNumber})',
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      dialogSelectedCourseId = value;
                    },
                    validator:
                        (value) =>
                            value == null ? 'Please select a course' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_uploadedFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.file_present, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(child: Text('File: $_uploadedFileName')),
                        ],
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade100,
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel, color: Colors.grey),
                label: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      dueDateController.text.isEmpty ||
                      maxMarksController.text.isEmpty ||
                      dialogSelectedCourseId == null) {
                    _showErrorMessage(
                      'Title, due date, max marks, and course are required',
                    );
                    return;
                  }
                  Navigator.pop(context);
                  setState(() {
                    _titleController.text = titleController.text;
                    _descriptionController.text = descriptionController.text;
                    _dueDateController.text = dueDateController.text;
                    _maxMarksController.text = maxMarksController.text;
                    selectedCourseId = dialogSelectedCourseId;
                    if (isEditing) {
                      _isEditing = true;
                      _currentEditId = assignment!['assignment_id'];
                    }
                  });
                  await _addOrUpdateAssignment();
                },
                icon: Icon(isEditing ? Icons.save : Icons.add),
                label: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.deepPurple.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Assignments',
        userEmail: Provider.of<LoginController>(context).email.split('@').first,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
              : RefreshIndicator(
                key: _refreshKey,
                color: Colors.deepPurple,
                onRefresh: _fetchAssignments,
                child:
                    selectedCourseId == null || courses.isEmpty
                        ? const Center(
                          child: Text(
                            'No courses available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                        : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (courseAssignments.containsKey(selectedCourseId))
                              ...courseAssignments[selectedCourseId]!
                                  .map(
                                    (assignment) =>
                                        _buildAssignmentCard(assignment),
                                  )
                                  .toList()
                            else
                              const Center(
                                child: Text(
                                  'No assignments for this course',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
              ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Builder(
          builder:
              (context) => GestureDetector(
                onTap:
                    () => _instructorId != null ? _showAddEditDialog() : null,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Add Assignment',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final DateTime dueDate = DateTime.parse(assignment['due_date']);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          assignment['title'] ?? 'Untitled Assignment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignment['description'] != null)
              Text(assignment['description']),
            Text('Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}'),
            Text('Max Marks: ${assignment['max_marks']}'),
            if (assignment['file_path'] != null)
              InkWell(
                onTap:
                    () => _downloadFile(
                      assignment['file_path'],
                      assignment['file_path'].split('/').last,
                    ),
                child: Text(
                  'File: ${assignment['file_path'].split('/').last}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editAssignment(assignment),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed:
                  () => _showDeleteConfirmation(assignment['assignment_id']),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int assignmentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this assignment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAssignment(assignmentId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
