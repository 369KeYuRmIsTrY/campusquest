import 'package:campusquest/modules/admin/controllers/department_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../controllers/login_controller.dart';
import 'package:campusquest/theme/theme.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => DepartmentScreenState();
}

class DepartmentScreenState extends State<DepartmentScreen>
    with SingleTickerProviderStateMixin {
  late final DepartmentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DepartmentController(
      context: context,
      setStateCallback: setState,
      vsync: this,
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Departments',
        userEmail:
            loginController.studentName ??
            loginController.email.split('@').first,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        showSearch: true,
        isSearching: _controller.isSearching,
        searchController: _controller.searchController,
        onSearchChanged: (_) => _controller.filterDepartments(),
        onSearchToggle: () => _controller.toggleSearch(),
        onNotificationPressed: null, // Or provide a handler if needed
      ),
      body:
          _controller.isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.yachtClubBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading data...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                key: _controller.refreshKey,
                onRefresh: _controller.fetchData,
                color: AppTheme.yachtClubBlue,
                child:
                    _controller.filteredDepartments.isEmpty
                        ? Center(child: _controller.buildEmptyState(context))
                        : Scrollbar(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _controller.filteredDepartments.length,
                            itemBuilder: (context, index) {
                              return _controller.buildDepartmentCard(
                                context,
                                _controller.filteredDepartments[index],
                                index,
                              );
                            },
                          ),
                        ),
              ),
      floatingActionButton: ScaleTransition(
        scale: _controller.fabAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.velvetTealDark,
                AppTheme.velvetTeal,
                AppTheme.velvetTealLight,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _controller.showAddEditDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Department',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // Center the FAB
    );
  }
}
