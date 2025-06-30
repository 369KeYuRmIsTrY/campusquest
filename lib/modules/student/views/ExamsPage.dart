import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/login_controller.dart';
import '../../../widgets/common_app_bar.dart';

class ExamsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Exams',
        userEmail: Provider.of<LoginController>(context).studentName ??
            Provider.of<LoginController>(context).email.split('@').first,
      ),
      body: Center(
        child: Text('This is the Exams page for students.'),
      ),
    );
  }
}
