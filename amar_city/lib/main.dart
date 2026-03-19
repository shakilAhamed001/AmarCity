import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MainApp());
}
// test 
//test 2
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AmarCity',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Simple Home Page - Replace with your actual home screen
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AmarCity'),
        backgroundColor: const Color(0xFF0066CC),
      ),
      body: const Center(
        child: Text(
          'Welcome to AmarCity',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}