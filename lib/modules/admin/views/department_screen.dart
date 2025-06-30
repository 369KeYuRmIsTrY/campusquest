import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:campusquest/controllers/login_controller.dart';
import 'package:campusquest/widgets/common_app_bar.dart';
import 'package:campusquest/modules/admin/models/department.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final _supabase = Supabase.instance.client;
  List<Department> _departments = [];
  List<Department> _filteredDepartments = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _searchController.addListener(_filterDepartments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoading = true);

    try {
      final response =
          await _supabase.from('department').select().order('department_name');

      setState(() {
        _departments =
            response.map((dept) => Department.fromMap(dept)).toList();
        _filteredDepartments = List.from(_departments);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Error fetching departments: $e');
    }
  }

  void _filterDepartments() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredDepartments = List.from(_departments);
        _isSearching = false;
      });
    } else {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredDepartments = _departments.where((dept) {
          return dept.departmentName.toLowerCase().contains(query) ||
              (dept.description?.toLowerCase().contains(query) ?? false) ||
              (dept.location?.toLowerCase().contains(query) ?? false) ||
              (dept.contactInfo?.toLowerCase().contains(query) ?? false);
        }).toList();
        _isSearching = true;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Department Management',
        userEmail: loginController.studentName ??
            loginController.email.split('@').first,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        showSearch: true,
        searchController: _searchController,
        isSearching: _isSearching,
        onSearchChanged: (_) => _filterDepartments(),
        onSearchToggle: () {
          setState(() {
            if (_isSearching) _searchController.clear();
            _isSearching = !_isSearching;
          });
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDepartments,
              child: _filteredDepartments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSearching
                                ? 'No departments match your search'
                                : 'No departments available',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSearching
                                ? 'Try a different search term'
                                : 'Add your first department',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDepartments.length,
                      itemBuilder: (context, index) {
                        return _buildDepartmentCard(
                            _filteredDepartments[index], index);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDepartmentCard(Department department, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDepartmentDetails(department),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.departmentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (department.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            department.description!,
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (department.location != null || department.contactInfo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (department.location != null) ...[
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(department.location!,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 16),
                      ],
                      if (department.contactInfo != null) ...[
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(department.contactInfo!,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepartmentDetails(Department department) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    department.departmentName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                        icon: Icons.business,
                        title: 'Department Name',
                        value: department.departmentName),
                    if (department.description != null) ...[
                      const Divider(),
                      _buildDetailItem(
                          icon: Icons.description,
                          title: 'Description',
                          value: department.description!),
                    ],
                    if (department.location != null) ...[
                      const Divider(),
                      _buildDetailItem(
                          icon: Icons.location_on,
                          title: 'Location',
                          value: department.location!),
                    ],
                    if (department.contactInfo != null) ...[
                      const Divider(),
                      _buildDetailItem(
                          icon: Icons.phone,
                          title: 'Contact Info',
                          value: department.contactInfo!),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          label: 'Edit',
                          icon: Icons.edit,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddEditDialog(department: department);
                          },
                        ),
                        _buildActionButton(
                          label: 'Delete',
                          icon: Icons.delete,
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(department);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.deepPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog({Department? department}) {
    final bool isEditing = department != null;
    final nameController = TextEditingController(
        text: isEditing ? department!.departmentName : '');
    final descriptionController = TextEditingController(
        text: isEditing ? department!.description ?? '' : '');
    final locationController = TextEditingController(
        text: isEditing ? department!.location ?? '' : '');
    final contactController = TextEditingController(
        text: isEditing ? department!.contactInfo ?? '' : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit : Icons.add, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Text(
              isEditing ? 'Edit Department' : 'Add New Department',
              style: const TextStyle(
                  color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Department Name',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Info',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) {
                _showErrorMessage('Department name is required');
                return;
              }

              try {
                if (isEditing) {
                  await _supabase.from('department').update({
                    'department_name': nameController.text,
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'location': locationController.text.isEmpty
                        ? null
                        : locationController.text,
                    'contact_info': contactController.text.isEmpty
                        ? null
                        : contactController.text,
                  }).match({'department_id': department!.departmentId});
                  _showSuccessMessage('Department updated successfully');
                } else {
                  await _supabase.from('department').insert({
                    'department_name': nameController.text,
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'location': locationController.text.isEmpty
                        ? null
                        : locationController.text,
                    'contact_info': contactController.text.isEmpty
                        ? null
                        : contactController.text,
                  });
                  _showSuccessMessage('Department added successfully');
                }
                Navigator.pop(context);
                _fetchDepartments();
              } catch (e) {
                _showErrorMessage(
                    isEditing ? 'Update failed: $e' : 'Add failed: $e');
              }
            },
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Department department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirm Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            'Are you sure you want to delete ${department.departmentName}? This action cannot be undone.'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              try {
                await _supabase
                    .from('department')
                    .delete()
                    .match({'department_id': department.departmentId});
                Navigator.pop(context);
                _showSuccessMessage('Department deleted successfully');
                _fetchDepartments();
              } catch (e) {
                _showErrorMessage('Delete failed: $e');
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
