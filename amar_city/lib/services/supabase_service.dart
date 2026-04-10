import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://oljsrexiazknzdveaqkj.supabase.co';
const String supabaseAnonKey = 'sb_publishable_uSHuEtUY-ehFPRC8duG6kQ_V6uurT1k';

final supabase = Supabase.instance.client;

class AuthService {
  // Sign Up
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'role': role},
    );
    return response;
  }

  // Sign In
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

  // Sign Out
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Current User
  static User? get currentUser => supabase.auth.currentUser;
}
