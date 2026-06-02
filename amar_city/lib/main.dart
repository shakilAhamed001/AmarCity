// Flutter এর material design widgets ব্যবহারের জন্য import
import 'package:flutter/material.dart';
// Supabase Flutter package — database ও auth এর জন্য
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/account/login_screen.dart';
import 'screens/account/create_account.dart';
import 'screens/officer/officer_screen.dart';
import 'screens/citizen/citizen_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/forget_password/reset_password_screen.dart';
import 'services/supabase_service.dart';
import 'services/theme_notifier.dart';

// App এর entry point — Supabase initialize করে তারপর app চালু করে
void main() async {
  // Flutter engine ready হওয়ার আগে async কাজ করতে এটা দরকার
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase initialize — URL ও anon key দিয়ে connection তৈরি হচ্ছে
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MainApp());
}

// MainApp — পুরো app এর root widget
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // ThemeNotifier — dark/light mode পরিবর্তনের জন্য
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
      debugShowCheckedModeBanner: false,
      // ThemeNotifier এর isDark অনুযায়ী dark বা light mode set হচ্ছে
      themeMode: _themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      // Light theme — নীল color seed দিয়ে
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E40AF),
        brightness: Brightness.light,
      ),
      // Dark theme — একই color seed কিন্তু dark brightness
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E40AF),
        brightness: Brightness.dark,
      ),
      // App শুরু হলে SplashScreen দেখাবে
      home: const SplashScreen(),
      // Named routes — Navigator.pushNamed() দিয়ে navigate করা যাবে
      routes: {
        '/login': (context) => const LoginScreen(),
        '/create_account': (context) => const CreateAccountScreen(),
        '/home': (context) => const CitizenScreen(),
        '/officer': (context) => const OfficerScreen(),
        '/citizen': (context) => const CitizenScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/reset_password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
