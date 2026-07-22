import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const GOVIStaysApp());
}

class GOVIStaysApp extends StatelessWidget {
  const GOVIStaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GOVIstays',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(),
    );
  }
}