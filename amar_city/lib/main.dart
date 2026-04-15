import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/account/login_screen.dart';
import 'screens/account/create_account.dart';
import 'screens/officer/officer_screen.dart';
import 'screens/citizen/citizen_screen.dart';
import 'services/supabase_service.dart';
import 'services/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AmarCity',
      debugShowCheckedModeBanner: false,
      themeMode: _themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E40AF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E40AF),
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/create_account': (context) => const CreateAccountScreen(),
        '/home': (context) => const CitizenScreen(),
        '/officer': (context) => const OfficerScreen(),
        '/citizen': (context) => const CitizenScreen(),
      },
    );
  }
}
