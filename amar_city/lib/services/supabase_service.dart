// Supabase Flutter package import — database ও auth এর জন্য
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://oljsrexiazknzdveaqkj.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sanNyZXhpYXprbnpkdmVhcWtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3Mzg4MDYsImV4cCI6MjA5MTMxNDgwNn0.gPP715G1GDHUXtgTXRLcpAYZZZA39k5EE3AvCY-Sbj0';

// Global supabase client — যেকোনো file থেকে এটা দিয়ে database access করা যাবে
final supabase = Supabase.instance.client;

// AuthService — সব authentication related কাজ এখানে
class AuthService {
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? department,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'role': role,
        if (department != null) 'department': department,
      },
      emailRedirectTo: null,
    );
    // profiles table এ insert এখন Supabase trigger করে দেবে automatically
    return response;
  }

  // Email ও password দিয়ে login করার function
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Logout করার function — session clear হয়ে যাবে
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // বর্তমানে login করা user কে return করে, না থাকলে null
  static User? get currentUser => supabase.auth.currentUser;
}
