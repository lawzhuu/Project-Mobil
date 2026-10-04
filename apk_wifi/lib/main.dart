import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const SimaNetApp());
}

class SimaNetApp extends StatelessWidget {
  const SimaNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sima.net Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
