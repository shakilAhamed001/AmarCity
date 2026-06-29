// AmarCity — Smart Municipality Platform
// এই file টি app এর entry point, MaterialApp configuration এখানে আছে

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amar_city/l10n/app_localizations.dart';
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
import 'services/escalation_service.dart';
import 'services/locale_service.dart';

void main() async {
  // Flutter engine ready হওয়ার আগে async কাজ করতে এটা দরকার
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialize — URL ও anon key দিয়ে connection তৈরি হচ্ছে
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // App start হওয়ার সময় পুরনো idle complaints escalate করা হচ্ছে
  EscalationService.checkAndEscalate();

  runApp(const MainApp());
}

// MainApp — root widget, theme ও locale পরিবর্তন হলে পুরো app rebuild হবে
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Singleton ThemeNotifier — dark/light mode control করে
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    // Theme পরিবর্তন হলে setState করে UI rebuild করা হচ্ছে
    _themeNotifier.addListener(() => setState(() {}));
    // Locale পরিবর্তন হলে setState করে পুরো app এ language apply হবে
    localeService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AmarCity',
      debugShowCheckedModeBanner: false,

      // Localization setup — English ও Bangla support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('bn'), // বাংলা
      ],
      // বর্তমানে selected locale — toggle করলে এটা পরিবর্তন হয়
      locale: localeService.locale,

      // Dark/Light mode — ThemeNotifier এর state অনুযায়ী
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

      // App শুরু হলে splash screen দেখাবে
      home: const SplashScreen(),

      // Named routes — role অনুযায়ী সঠিক screen এ navigate করা হয়
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
