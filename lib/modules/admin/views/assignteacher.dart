import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campusquest/widgets/common_app_bar.dart'; // Corrected import for CommonAppBar
import 'package:campusquest/theme/theme.dart'; // Corrected import for AppTheme
import 'package:dropdown_button2/dropdown_button2.dart';

class TeachesScreen extends StatefulWidget {
  const TeachesScreen({super.key});

  @override
  State<TeachesScreen> createState() => _TeachesScreenState();
}

class _TeachesScreenState extends State<TeachesScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _teaches = [];
  List<Map<String, dynamic>> _filteredTeaches = [];
  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _semesters = [];
  bool _isLoading = true;
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

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
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _animationController.forward(),
    );

    _searchController.addListener(_filterTeaches);
    _fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchTeaches(),
      _fetchInstructors(),
      _fetchCourses(),
      _fetchSemesters(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchTeaches() async {
    try {
      final response = await _supabase
          .from('teaches')
          .select()
          .order('teaches_id');
      setState(() {
        _teaches = List<Map<String, dynamic>>.from(response);
        _filteredTeaches = List.from(_teaches);
      });
    } catch (e) {
      _showErrorMessage('Error fetching teaching assignments: $e');
    }
  }

  Future<void> _fetchInstructors() async {
    try {
      final response = await _supabase
          .from('instructor')
          .select()
          .order('instructor_id');
      setState(() => _instructors = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showErrorMessage('Error fetching instructors: $e');
    }
  }

  Future<void> _fetchCourses() async {
    try {
      final response = await _supabase
          .from('course')
          .select()
          .order('course_id');
      setState(() => _courses = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showErrorMessage('Error fetching courses: $e');
    }
  }

  Future<void> _fetchSemesters() async {
    try {
      final response = await _supabase
          .from('semester')
          .select()
          .order('semester_id');
      setState(() => _semesters = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showErrorMessage('Error fetching semesters: $e');
    }
  }

  void _filterTeaches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredTeaches =
          _teaches.where((teach) {
            final instructorName =
                _getInstructorName(teach['instructor_id']).toLowerCase();
            final courseName = _getCourseName(teach['course_id']).toLowerCase();
            final semesterNum =
                _getSemesterNumber(teach['semester_id']).toString();
            return instructorName.contains(query) ||
                courseName.contains(query) ||
                semesterNum.contains(query);
          }).toList();
    });
  }

  String _getInstructorName(int instructorId) {
    return _instructors.firstWhere(
          (instructor) => instructor['instructor_id'] == instructorId,
          orElse: () => {'name': 'Unknown'},
        )['name']
        as String;
  }

  String _getCourseName(int courseId) {
    return _courses.firstWhere(
          (course) => course['course_id'] == courseId,
          orElse: () => {'course_name': 'Unknown'},
        )['course_name']
        as String;
  }

  int _getSemesterNumber(int semesterId) {
    return _semesters.firstWhere(
          (semester) => semester['semester_id'] == semesterId,
          orElse: () => {'semester_number': 0},
        )['semester_number']
        as int;
  }

  Future<void> _deleteTeach(int teachesId, int index) async {
    final deletedTeach = _filteredTeaches[index];
    setState(() => _filteredTeaches.removeAt(index));
    try {
      await _supabase.from('teaches').delete().match({'teaches_id': teachesId});
      _teaches.removeWhere((t) => t['teaches_id'] == teachesId);
      _showSuccessMessage(
        'Teaching assignment deleted successfully',
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () async {
            try {
              final newTeach = Map<String, dynamic>.from(deletedTeach)
                ..remove('teaches_id');
              await _supabase.from('teaches').insert(newTeach);
              await _fetchTeaches();
              _showSuccessMessage('Teaching assignment restored');
            } catch (e) {
              _showErrorMessage('Failed to restore: $e');
            }
          },
        ),
      );
    } catch (e) {
      setState(() => _filteredTeaches.insert(index, deletedTeach));
      _showErrorMessage('Failed to delete: $e');
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? teach}) {
    final bool isEditing = teach != null;
    int? selectedInstructorId =
        isEditing ? teach!['instructor_id'] as int? : null;
    int? selectedCourseId = isEditing ? teach!['course_id'] as int? : null;
    int? selectedSemesterId = isEditing ? teach!['semester_id'] as int? : null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add/Edit Teaching Assignment",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_box,
                    color: AppTheme.yachtClubBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Teaching Assignment' : 'Assign Course',
                    style: const TextStyle(
                      color: AppTheme.yachtClubBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<int>(
                              isDense: true,
                              value: selectedInstructorId,
                              decoration: _inputDecoration(
                                'Instructor',
                                Icons.person,
                              ).copyWith(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items:
                                  _instructors
                                      .map(
                                        (instructor) => DropdownMenuItem<int>(
                                          value:
                                              instructor['instructor_id']
                                                  as int,
                                          child: Text(
                                            instructor['name'] as String,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setDialogState(
                                    () => selectedInstructorId = value,
                                  ),
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Instructor is required'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 250,
                            child: DropdownButtonFormField2<int>(
                              isExpanded: true,
                              decoration: _inputDecoration(
                                'Course',
                                Icons.book,
                              ).copyWith(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items:
                                  _courses
                                      .map(
                                        (course) => DropdownMenuItem<int>(
                                          value: course['course_id'] as int,
                                          child: SizedBox(
                                            width: 200,
                                            child: Text(
                                              course['course_name'] as String,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setDialogState(
                                    () => selectedCourseId = value,
                                  ),
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Course is required'
                                          : null,
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                width: 250,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<int>(
                              isDense: true,
                              value: selectedSemesterId,
                              decoration: _inputDecoration(
                                'Semester',
                                Icons.calendar_today,
                              ).copyWith(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items:
                                  _semesters
                                      .map(
                                        (semester) => DropdownMenuItem<int>(
                                          value: semester['semester_id'] as int,
                                          child: Text(
                                            'Semester ${semester['semester_number']}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setDialogState(
                                    () => selectedSemesterId = value,
                                  ),
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Semester is required'
                                          : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
                GestureDetector(
                  onTap: () async {
                    if (selectedInstructorId == null ||
                        selectedCourseId == null ||
                        selectedSemesterId == null) {
                      _showErrorMessage('All fields are required');
                      return;
                    }
                    Navigator.pop(context);
                    try {
                      if (isEditing) {
                        await _supabase
                            .from('teaches')
                            .update({
                              'instructor_id': selectedInstructorId,
                              'course_id': selectedCourseId,
                              'semester_id': selectedSemesterId,
                            })
                            .match({'teaches_id': teach!['teaches_id']});
                        _showSuccessMessage('Updated successfully');
                      } else {
                        await _supabase.from('teaches').insert({
                          'instructor_id': selectedInstructorId,
                          'course_id': selectedCourseId,
                          'semester_id': selectedSemesterId,
                        });
                        _showSuccessMessage('Course assign successfully');
                      }
                      _fetchTeaches();
                    } catch (e) {
                      _showErrorMessage('Operation failed: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkBlue.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEditing ? Icons.save : Icons.add,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Update' : 'Add',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTeachingDetails(Map<String, dynamic> teach) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder:
                (_, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.yachtClubBlueSwatch.shade50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getInstructorName(teach['instructor_id']),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.yachtClubBlue,
                                    ),
                                  ),
                                  Text(
                                    _getCourseName(teach['course_id']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          AppTheme.yachtClubBlueSwatch.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: AppTheme.yachtClubBlue,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem(
                                icon: Icons.person,
                                title: 'Instructor',
                                value: _getInstructorName(
                                  teach['instructor_id'],
                                ),
                              ),
                              _buildDetailItem(
                                icon: Icons.book,
                                title: 'Course',
                                value: _getCourseName(teach['course_id']),
                              ),
                              _buildDetailItem(
                                icon: Icons.calendar_today,
                                title: 'Semester',
                                value:
                                    'Semester ${_getSemesterNumber(teach['semester_id'])}',
                              ),
                              _buildDetailItem(
                                icon: Icons.tag,
                                title: 'Teaches ID',
                                value: teach['teaches_id'].toString(),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    label: 'Edit',
                                    icon: Icons.edit,
                                    color: Colors.blue,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showAddEditDialog(teach: teach);
                                    },
                                  ),
                                  _buildActionButton(
                                    label: 'Delete',
                                    icon: Icons.delete,
                                    color: Colors.red,
                                    onTap: () {
                                      Navigator.pop(context);
                                      final index = _filteredTeaches.indexWhere(
                                        (t) =>
                                            t['teaches_id'] ==
                                            teach['teaches_id'],
                                      );
                                      if (index != -1)
                                        _deleteTeach(
                                          teach['teaches_id'],
                                          index,
                                        );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  InputDecoration _inputDecoration(String labelText, IconData prefixIcon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: AppTheme.yachtClubBlue),
      prefixIcon: Icon(prefixIcon, color: AppTheme.yachtClubBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.yachtClubBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.yachtClubBlue, width: 2),
      ),
      filled: true,
      fillColor: AppTheme.yachtClubBlue,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  void _showSuccessMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration:
            action != null
                ? const Duration(seconds: 5)
                : const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        action: action,
      ),
    );
  }

  void _showErrorMessage(String message) {
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          _isSearching
              ? 'No Instructor match your search'
              : 'No teaching Instructor found',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSearching
              ? 'Try a different search term'
              : 'Add an Instructor to get started',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        if (!_isSearching)
          GestureDetector(
            onTap: () => _showAddEditDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Assign Instructor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTeachCard(Map<String, dynamic> teach, int index) {
    return Hero(
      tag: 'teach_${teach['teaches_id']}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        shadowColor: AppTheme.yachtClubBlue.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showTeachingDetails(teach),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.yachtClubBlue.withOpacity(0.1),
          highlightColor: AppTheme.yachtClubBlue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.yachtClubBlueSwatch.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: AppTheme.yachtClubBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getInstructorName(teach['instructor_id']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _getCourseName(teach['course_id']),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Semester ${_getSemesterNumber(teach['semester_id'])}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddEditDialog(teach: teach),
                      tooltip: 'Edit',
                      splashRadius: 24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTeach(teach['teaches_id'], index),
                      tooltip: 'Delete',
                      splashRadius: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.yachtClubBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.yachtClubBlue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Assign Instructor',
        userEmail: '', // You can pass the actual user email if available
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        showSearch: true,
        searchController: _searchController,
        isSearching: _isSearching,
        onSearchChanged: (_) => setState(() {}),
        onSearchToggle: () {
          setState(() {
            if (_isSearching) _searchController.clear();
            _isSearching = !_isSearching;
          });
        },
        onNotificationPressed: () => _refreshKey.currentState?.show(),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.yachtClubBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Instructors...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                key: _refreshKey,
                color: AppTheme.yachtClubBlue,
                onRefresh: _fetchData,
                child:
                    _filteredTeaches.isEmpty
                        ? Center(child: _buildEmptyState())
                        : Scrollbar(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTeaches.length,
                            itemBuilder:
                                (context, index) => _buildTeachCard(
                                  _filteredTeaches[index],
                                  index,
                                ),
                          ),
                        ),
              ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: GestureDetector(
          onTap: () => _showAddEditDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.veryDarkBlue, AppTheme.darkBlue],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Assign Instructor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
