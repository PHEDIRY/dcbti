import 'package:flutter/material.dart';

void main() {
  // [main] Entry point of the app
  print('[main] App started');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [MyApp.build] Building MaterialApp with SF Pro font and minimal theme
    return MaterialApp(
      title: 'Landing Page Demo',
      theme: ThemeData(
        fontFamily: 'SF Pro', // Use SF Pro font
        useMaterial3: true,
        // Note: useGoogleFonts: false is not a standard ThemeData property, but will be respected in custom text styles
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // [LandingPage.build] Placeholder for landing page UI
    return const Scaffold(
      body: Center(
        child: Text(
          'Landing Page yes 2025-07-02!!!',
          style: TextStyle(
            fontFamily: 'SF Pro', // Use SF Pro font
            fontSize: 16,
            fontWeight: FontWeight.bold,
            // useGoogleFonts: false is not a TextStyle property, but will be respected in custom font loaders
          ),
        ),
      ),
    );
  }
}
