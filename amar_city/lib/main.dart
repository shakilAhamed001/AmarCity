// Flutter এর material design ব্যবহারের জন্য import
import 'package:flutter/material.dart';
// Supabase initialize করার জন্য import
import 'package:supabase_flutter/supabase_flutter.dart';
// সব screen গুলো import করা হচ্ছে
import 'screens/splash/splash_screen.dart';
import 'screens/account/login_screen.dart';
import 'screens/account/create_account.dart';
import 'screens/officer/officer_screen.dart';
import 'screens/citizen/citizen_screen.dart';
import 'screens/admin/admin_dashboard.dart';
// Supabase URL ও key এর জন্য
import 'services/supabase_service.dart';
// Dark/Light theme toggle এর জন্য
import 'services/theme_notifier.dart';

void main() async {
  // Flutter engine ready হওয়ার আগে async কাজ করতে এটা দরকার
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase initialize — app শুরুতে একবারই হয়
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  // App চালু করা হচ্ছে
  runApp(const MainApp());
}

// MainApp হলো root widget — পুরো app এর শুরু এখান থেকে
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // ThemeNotifier singleton — dark/light mode track করে
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    // Theme পরিবর্তন হলে UI rebuild করার জন্য listener যোগ করা হচ্ছে
    _themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AmarCity',
      // Debug banner লুকানো হচ্ছে
      debugShowCheckedModeBanner: false,
      // isDark true হলে dark mode, না হলে light mode
      themeMode: _themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      // Light theme configuration
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E40AF),
        brightness: Brightness.light,
      ),
      // Dark theme configuration
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E40AF),
        brightness: Brightness.dark,
      ),
      // App শুরু হলে প্রথমে SplashScreen দেখাবে
      home: const SplashScreen(),
      // Named routes — Navigator.pushNamed() দিয়ে navigate করা যাবে
      routes: {
        '/login': (context) => const LoginScreen(),
        '/create_account': (context) => const CreateAccountScreen(),
        '/home': (context) => const CitizenScreen(),
        '/officer': (context) => const OfficerScreen(),
        '/citizen': (context) => const CitizenScreen(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}
