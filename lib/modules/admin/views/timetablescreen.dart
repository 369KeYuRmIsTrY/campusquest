import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campusquest/widgets/common_app_bar.dart';
import 'package:campusquest/theme/theme.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _programSemesters = [];
  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = true;
  int? _selectedProgramSemesterId;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProgramSemesters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProgramSemesters() async {
    setState(() => _isLoading = true);
    final semesters = await _supabase
        .from('semester')
        .select('semester_id, semester_number, program_id');
    final programs = await _supabase
        .from('program')
        .select('program_id, program_name, batch_year');
    final programMap = {for (var p in programs) p['program_id']: p};
    _programSemesters =
        List<Map<String, dynamic>>.from(semesters).map((s) {
          final p = programMap[s['program_id']];
          return {
            'semester_id': s['semester_id'],
            'semester_number': s['semester_number'],
            'program_id': s['program_id'],
            'program_name': p != null ? p['program_name'] : 'Unknown',
            'batch_year': p != null ? p['batch_year'] : '',
          };
        }).toList();
    // Set default selected program & semester to the first one if available
    if (_programSemesters.isNotEmpty && _selectedProgramSemesterId == null) {
      _selectedProgramSemesterId =
          _programSemesters.first['semester_id'] as int;
      await _fetchTimetable(_selectedProgramSemesterId!);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchTimetable(int semesterId) async {
    setState(() => _isLoading = true);
    // Fetch timetable entries for the selected semester
    final timetableData = await _supabase.from('timetable').select();
    // Fetch all related data for mapping names
    final courses = await _supabase
        .from('course')
        .select('course_id, course_name');
    final classrooms = await _supabase
        .from('classroom')
        .select('classroom_id, building, room_number');
    final timeSlots = await _supabase.from('time_slot').select();
    final teaches = await _supabase
        .from('teaches')
        .select('teaches_id, instructor_id');
    final instructors = await _supabase
        .from('instructor')
        .select('instructor_id, name');

    // Filter timetable for the selected semester
    final filteredTimetable =
        List<Map<String, dynamic>>.from(
          timetableData,
        ).where((entry) => entry['semester_id'] == semesterId).toList();

    print('DEBUG: filteredTimetable = ' + filteredTimetable.toString());
    final teachesMap = {
      for (var t in teaches) t['teaches_id']: t['instructor_id'],
    };
    print('DEBUG: teachesMap = ' + teachesMap.toString());
    final instructorMap = {
      for (var i in instructors) i['instructor_id']: i['name'],
    };

    // Map for quick lookup
    final courseMap = {for (var c in courses) c['course_id']: c['course_name']};
    final classroomMap = {
      for (var c in classrooms)
        c['classroom_id']: '${c['building']} - ${c['room_number']}',
    };
    final timeSlotMap = {for (var t in timeSlots) t['time_slot_id']: t};

    // Build display data
    final displayTimetable =
        filteredTimetable.map((entry) {
          final teachesId = entry['teaches_id'];
          String instructorName = 'Not Assigned';
          if (teachesId != null) {
            final instructorId = teachesMap[teachesId];
            if (instructorId != null) {
              instructorName = instructorMap[instructorId] ?? 'Unknown';
            }
          }
          final courseId = entry['course_id'];
          final timeSlot = timeSlotMap[entry['time_slot_id']];
          return {
            'course_name': courseMap[courseId] ?? 'Unknown',
            'instructor_name': instructorName,
            'classroom': classroomMap[entry['classroom_id']] ?? 'Unknown',
            'day': timeSlot != null ? timeSlot['day'] : 'Unknown',
            'time':
                timeSlot != null
                    ? '${timeSlot['start_time']} - ${timeSlot['end_time']}'
                    : '',
          };
        }).toList();

    setState(() {
      _timetable = displayTimetable;
      _isLoading = false;
    });
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedProgramSemesterId,
              decoration: const InputDecoration(
                labelText: 'Program & Semester',
              ),
              items:
                  _programSemesters
                      .map(
                        (ps) => DropdownMenuItem<int>(
                          value: ps['semester_id'] as int,
                          child: Text(
                            '${ps['program_name']} (${ps['batch_year']}) - Semester ${ps['semester_number']}',
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) async {
                setState(() {
                  _selectedProgramSemesterId = v;
                  _timetable = [];
                });
                if (v != null) {
                  await _fetchTimetable(v);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    // Filter timetable by search query if searching
    final filteredTimetable =
        _isSearching && _searchQuery.isNotEmpty
            ? _timetable.where((entry) {
              final query = _searchQuery.toLowerCase();
              return (entry['course_name'] ?? '').toLowerCase().contains(
                    query,
                  ) ||
                  (entry['instructor_name'] ?? '').toLowerCase().contains(
                    query,
                  ) ||
                  (entry['classroom'] ?? '').toLowerCase().contains(query) ||
                  (entry['day'] ?? '').toLowerCase().contains(query);
            }).toList()
            : _timetable;
    if (filteredTimetable.isEmpty) {
      return const Expanded(
        child: Center(child: Text('No timetable entries for this selection.')),
      );
    }
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filteredTimetable.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = filteredTimetable[index];
          return Card(
            color: AppTheme.yachtClubLight,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['course_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.yachtClubBlue,
                        ),
                      ),
                      Text(
                        entry['day'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.yachtClubGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 18,
                        color: AppTheme.yachtClubBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry['instructor_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.yachtClubBlue,
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Icon(
                        Icons.class_,
                        size: 18,
                        color: AppTheme.yachtClubBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry['classroom'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.yachtClubBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppTheme.yachtClubBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.yachtClubBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog() async {
    // Fetch all programs, semesters, courses, instructors, classrooms, time slots, and teaches
    List<Map<String, dynamic>> semesters = await _supabase
        .from('semester')
        .select('semester_id, semester_number, program_id');
    List<Map<String, dynamic>> programs = await _supabase
        .from('program')
        .select('program_id, program_name, batch_year');
    List<Map<String, dynamic>> courses = await _supabase
        .from('course')
        .select('course_id, course_name, semester_id');
    List<Map<String, dynamic>> instructors = await _supabase
        .from('instructor')
        .select('instructor_id, name');
    List<Map<String, dynamic>> classrooms = await _supabase
        .from('classroom')
        .select('classroom_id, building, room_number');
    List<Map<String, dynamic>> timeSlots =
        await _supabase.from('time_slot').select();
    List<Map<String, dynamic>> teaches = await _supabase
        .from('teaches')
        .select('teaches_id, instructor_id, course_id, semester_id');

    // Build combined program-semester list
    final programMap = {for (var p in programs) p['program_id']: p};
    List<Map<String, dynamic>> programSemesters =
        List<Map<String, dynamic>>.from(semesters).map((s) {
          final p = programMap[s['program_id']];
          return {
            'semester_id': s['semester_id'],
            'semester_number': s['semester_number'],
            'program_id': s['program_id'],
            'program_name': p != null ? p['program_name'] : 'Unknown',
            'batch_year': p != null ? p['batch_year'] : '',
          };
        }).toList();

    int? selectedProgramSemesterId = _selectedProgramSemesterId;
    int? selectedCourseId;
    int? selectedTeachesId;
    String? selectedClassroomId;
    int? selectedTimeSlotId;
    bool isSubmitting = false;

    List<Map<String, dynamic>> filteredCourses = [];
    List<Map<String, dynamic>> filteredTeaches = [];

    void updateFilters() {
      filteredCourses =
          courses
              .where(
                (c) =>
                    selectedProgramSemesterId == null ||
                    c['semester_id'] == selectedProgramSemesterId,
              )
              .toList();
      if (selectedCourseId != null && selectedProgramSemesterId != null) {
        filteredTeaches =
            teaches
                .where(
                  (t) =>
                      t['course_id'] == selectedCourseId &&
                      t['semester_id'] == selectedProgramSemesterId,
                )
                .toList();
      } else {
        filteredTeaches = [];
      }
    }

    updateFilters();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            updateFilters();
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 16,
              title: const Text(
                'Add Timetable Entry',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppTheme.yachtClubBlue,
                ),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedProgramSemesterId,
                        decoration: InputDecoration(
                          labelText: 'Program & Semester',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items:
                            programSemesters
                                .map<DropdownMenuItem<int>>(
                                  (ps) => DropdownMenuItem<int>(
                                    value: ps['semester_id'] as int,
                                    child: Text(
                                      '${ps['program_name']} (${ps['batch_year']}) - Semester ${ps['semester_number']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setDialogState(() {
                            selectedProgramSemesterId = v;
                            selectedCourseId = null;
                            selectedTeachesId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: selectedCourseId,
                        decoration: InputDecoration(
                          labelText: 'Course',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items:
                            filteredCourses
                                .map<DropdownMenuItem<int>>(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['course_id'] as int,
                                    child: Text(
                                      c['course_name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setDialogState(() {
                            selectedCourseId = v;
                            // Update filteredTeaches for the new course
                            filteredTeaches =
                                teaches
                                    .where(
                                      (t) =>
                                          t['course_id'] == v &&
                                          t['semester_id'] ==
                                              selectedProgramSemesterId,
                                    )
                                    .toList();
                            // Auto-select the first available instructor if any
                            if (filteredTeaches.isNotEmpty) {
                              selectedTeachesId =
                                  filteredTeaches.first['teaches_id'] as int;
                            } else {
                              selectedTeachesId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        value: selectedTeachesId,
                        decoration: InputDecoration(
                          labelText: 'Instructor',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Not Assigned',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          ...filteredTeaches.map<DropdownMenuItem<int?>>((t) {
                            final instructor = instructors.firstWhere(
                              (i) => i['instructor_id'] == t['instructor_id'],
                              orElse: () => {'name': 'Unknown'},
                            );
                            return DropdownMenuItem<int?>(
                              value: t['teaches_id'] as int,
                              child: Text(
                                instructor['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged:
                            (v) => setDialogState(() => selectedTeachesId = v),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedClassroomId,
                        decoration: InputDecoration(
                          labelText: 'Classroom',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items:
                            classrooms
                                .map<DropdownMenuItem<String>>(
                                  (c) => DropdownMenuItem<String>(
                                    value: c['classroom_id'] as String,
                                    child: Text(
                                      '${c['building']} - ${c['room_number']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) =>
                                setDialogState(() => selectedClassroomId = v),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: selectedTimeSlotId,
                        decoration: InputDecoration(
                          labelText: 'Time Slot',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppTheme.yachtClubBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items:
                            timeSlots
                                .map<DropdownMenuItem<int>>(
                                  (t) => DropdownMenuItem<int>(
                                    value: t['time_slot_id'] as int,
                                    child: Text(
                                      '${t['day']} ${t['start_time']} - ${t['end_time']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setDialogState(() => selectedTimeSlotId = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.yachtClubBlue),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            if (selectedProgramSemesterId == null ||
                                selectedCourseId == null ||
                                selectedClassroomId == null ||
                                selectedTimeSlotId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields.'),
                                ),
                              );
                              return;
                            }
                            setDialogState(() => isSubmitting = true);
                            try {
                              await _supabase.from('timetable').insert({
                                'course_id': selectedCourseId,
                                'semester_id': selectedProgramSemesterId,
                                'classroom_id': selectedClassroomId,
                                'time_slot_id': selectedTimeSlotId,
                                'teaches_id': selectedTeachesId,
                              });
                              Navigator.pop(context);
                              if (_selectedProgramSemesterId != null) {
                                await _fetchTimetable(
                                  _selectedProgramSemesterId!,
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Entry added!')),
                              );
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: \\${e.toString()}'),
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.yachtClubBlue,
                    foregroundColor: AppTheme.yachtClubLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child:
                      isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.yachtClubLight,
                            ),
                          )
                          : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Timetable Admin',
        userEmail: '',
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
        showSearch: true,
        searchController: _searchController,
        isSearching: _isSearching,
        onSearchToggle: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchQuery = '';
              _searchController.clear();
            }
          });
        },
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildFilters(), _buildTable()],
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, color: AppTheme.yachtClubLight),
              label: const Text(
                'Add Time Table',
                style: TextStyle(color: AppTheme.yachtClubLight),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yachtClubBlue,
                foregroundColor: AppTheme.yachtClubLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
