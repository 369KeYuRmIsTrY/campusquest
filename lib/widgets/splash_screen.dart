import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/login_controller.dart';
import '../widgets/bottomnavigationbar.dart';
import '../modules/login/views/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Wait for 3 seconds to show splash screen
      await Future.delayed(Duration(seconds: 3));

      if (!mounted) return;

      final loginController =
          Provider.of<LoginController>(context, listen: false);
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // If we have a session, restore it
        await loginController.restoreSession();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              loginController.isLoggedIn ? BottomBar() : LoginPage(),
        ),
      );
    } catch (e) {
      print('Error checking auth state: $e');
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // You can change this to your theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/logocq.png',
              width: 250,
            ),
            SizedBox(height: 20),

            // App name text
            Text(
              'CampusQuest',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0039A6), // Your specific color
              ),
            ),
            SizedBox(height: 10),
            Text(
              'ACCESS ALL WORK FROM HERE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 1.5,
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
