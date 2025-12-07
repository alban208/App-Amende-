import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

/// Widget racine de l'application
/// Gère automatiquement l'état de connexion via Firebase Auth
class AmendesApp extends StatelessWidget {
  const AmendesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Amendes App',
      
      // Thème moderne Material 3
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      
      // Thème sombre (optionnel)
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      
      // Page d'accueil dynamique selon l'état d'authentification
      home: const AuthGate(),
    );
  }
}

/// Widget qui écoute l'état d'authentification Firebase
/// Redirige automatiquement vers Login ou Dashboard
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Écoute en temps réel l'état de connexion
      stream: FirebaseAuth.instance.authStateChanges(),
      
      builder: (context, snapshot) {
        // Affichage pendant le chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si utilisateur connecté → Dashboard
        // Sinon → Login
        if (snapshot.hasData) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}