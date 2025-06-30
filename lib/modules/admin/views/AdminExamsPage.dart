import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/login_controller.dart';
import '../../../widgets/common_app_bar.dart';

class AdminExamsPage extends StatefulWidget {
  const AdminExamsPage({Key? key}) : super(key: key);

  @override
  State<AdminExamsPage> createState() => _AdminExamsPageState();
}

class _AdminExamsPageState extends State<AdminExamsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _selectedCourse;
  String? _selectedSemester;
  String? _selectedClass;

  // Mock data for dropdowns
  final List<String> _courses = ['Math', 'Physics', 'Chemistry', 'Biology'];
  final List<String> _semesters = ['Spring 2024', 'Fall 2024'];
  final List<String> _classes = ['Class A', 'Class B', 'Class C'];

  // List to store created exams
  final List<Map<String, dynamic>> _exams = [];

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _createExam() {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      setState(() {
        _exams.add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'dateTime': _selectedDateTime,
          'duration': _durationController.text,
          'course': _selectedCourse,
          'semester': _selectedSemester,
          'class': _selectedClass,
        });
        _titleController.clear();
        _descriptionController.clear();
        _durationController.clear();
        _selectedDateTime = null;
        _selectedCourse = null;
        _selectedSemester = null;
        _selectedClass = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Manage Exams',
        userEmail: loginController.studentName ??
            loginController.email.split('@').first,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Exam Title'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Title required'
                        : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration:
                        InputDecoration(labelText: 'Description (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_selectedDateTime == null
                            ? 'No Date & Time chosen'
                            : 'Date: ${_selectedDateTime!.toLocal().toString().substring(0, 16)}'),
                      ),
                      ElevatedButton(
                        onPressed: _pickDateTime,
                        child: Text('Pick Date & Time'),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _durationController,
                    decoration:
                        InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Duration required'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedCourse,
                    items: _courses
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCourse = val),
                    decoration: InputDecoration(labelText: 'Associated Course'),
                    hint: Text('Select Course (optional)'),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedSemester,
                    items: _semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSemester = val),
                    decoration: InputDecoration(labelText: 'Semester'),
                    hint: Text('Select Semester (optional)'),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    items: _classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedClass = val),
                    decoration: InputDecoration(labelText: 'Class'),
                    hint: Text('Select Class (optional)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createExam,
                    child: Text('Create Exam'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Created Exams:',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._exams.map((exam) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(exam['title'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exam['description'] != null &&
                            exam['description'].toString().isNotEmpty)
                          Text('Description: ${exam['description']}'),
                        Text(
                            'Date & Time: ${exam['dateTime']?.toLocal().toString().substring(0, 16) ?? ''}'),
                        Text('Duration: ${exam['duration']} minutes'),
                        if (exam['course'] != null)
                          Text('Course: ${exam['course']}'),
                        if (exam['semester'] != null)
                          Text('Semester: ${exam['semester']}'),
                        if (exam['class'] != null)
                          Text('Class: ${exam['class']}'),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
