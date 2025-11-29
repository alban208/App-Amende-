import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

class AmendesApp extends StatelessWidget {
  const AmendesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amendes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
