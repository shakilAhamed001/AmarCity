import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/account/login_screen.dart';
import 'screens/account/create_account.dart';
import 'screens/officer/officer_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MainApp());
}

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
        '/login': (context) => const LoginScreen(),
        '/create_account': (context) => const CreateAccountScreen(),
        '/home': (context) => const HomePage(),
        '/officer': (context) => const OfficerScreen(), // Officer route added
      },
    );
  }
}

// Update Splash Screen to navigate to login instead of home
// In splash_screen.dart, change the navigation line to:
// Navigator.of(context).pushReplacementNamed('/login');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
