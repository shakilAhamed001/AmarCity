// Supabase Flutter package import — database ও auth এর জন্য
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase project এর URL — এটা দিয়ে database connect হয়
const String supabaseUrl = 'https://oljsrexiazknzdveaqkj.supabase.co';
// Anonymous key — public access এর জন্য, secret না
const String supabaseAnonKey = 'sb_publishable_uSHuEtUY-ehFPRC8duG6kQ_V6uurT1k';

// Global supabase client — যেকোনো file থেকে এটা দিয়ে database access করা যাবে
final supabase = Supabase.instance.client;

// AuthService — সব authentication related কাজ এখানে
class AuthService {
  // নতুন account তৈরি করার function
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'Citizen', 'Officer', বা 'Admin'
    String? department, // শুধু Officer এর জন্য
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      // extra user info metadata হিসেবে save হয়
      data: {
        'full_name': name,
        'role': role,
        // department শুধু তখনই পাঠানো হবে যখন null না
        if (department != null) 'department': department,
      },
    );
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
