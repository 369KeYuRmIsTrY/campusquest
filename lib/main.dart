import 'package:campusquest/widgets/bottomnavigationbar.dart';
import 'package:campusquest/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_preview/device_preview.dart';

import 'controllers/login_controller.dart';
import 'controllers/theme_controller.dart';
import 'modules/login/views/login.dart';
import 'widgets/splash_screen.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gvszcisvxubllksvsojl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2c3pjaXN2eHVibGxrc3Zzb2psIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NzgzMjcsImV4cCI6MjA2NTU1NDMyN30.WRSSw53v-z51QjLklEEBRFCVZER7u_KwfSaAaGX7b9E',
    debug: true,
  );

  // Listen to auth state changes
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn) {
      print('User signed in: ${session?.user?.email}');
    } else if (event == AuthChangeEvent.signedOut) {
      print('User signed out');
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      print('Token refreshed');
    }
  });

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) {
              final controller = LoginController();
              controller
                  .restoreSession(); // Ensure session is restored on app start
              return controller;
            },
          ),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(
        context); // Access themeController from Provider

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      themeMode: themeController.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
