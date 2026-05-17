// Flutter material design import
import 'package:flutter/material.dart';
// Gesture recognizer — RichText এ tap handle করার জন্য
import 'package:flutter/gestures.dart';
// Auth service — login করার জন্য
import '../../services/supabase_service.dart';

// LoginScreen — App এর login page
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Email ও password input field controller
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  // Password দেখানো/লুকানোর জন্য — শুরুতে লুকানো
  bool _obscurePassword = true;
  // বর্তমানে কোন role selected — শুরুতে Citizen
  String _selectedRole = 'Citizen';

  // Admin এর hardcoded credentials — Supabase auth ব্যবহার করে না
  static const String _adminEmail = 'admin@amarcity.com';
  static const String _adminPassword = 'Admin@1234';

  @override
  void initState() {
    super.initState();
    // Controller initialize করা হচ্ছে
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Memory leak এড়াতে controller dispose করা হচ্ছে
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Password visibility toggle করার function
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // Login button loading state
  bool _isLoading = false;

  // Sign in button press করলে এই function call হয়
  void _handleSignIn() async {
    // Empty field check
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Admin login — Supabase ব্যবহার না করে local check করা হচ্ছে
    if (_selectedRole == 'Admin') {
      if (_emailController.text.trim() == _adminEmail &&
          _passwordController.text == _adminPassword) {
        // Credentials সঠিক হলে admin dashboard এ navigate
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid admin credentials.')),
        );
      }
      return;
    }

    // Citizen ও Officer এর জন্য Supabase auth ব্যবহার করা হচ্ছে
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null && mounted) {
        // Role অনুযায়ী সঠিক screen এ navigate করা হচ্ছে
        if (_selectedRole == 'Officer') {
          Navigator.of(context).pushReplacementNamed('/officer');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        // Error message user-friendly করা হচ্ছে
        String message = e.toString();
        if (message.contains('email_not_confirmed')) {
          message = 'Please verify your email first. Check your inbox.';
        } else if (message.contains('invalid_credentials')) {
          message = 'Invalid email or password.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      // Loading শেষ করা হচ্ছে
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Blue gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF001F5C),
              const Color(0xFF004B9E),
              const Color(0xFF0066CC),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo ও app name section
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: Column(
                  children: [
                    // App logo container
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.cyan.shade300,
                              Colors.blue.shade400,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.apartment,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // App name
                    const Text(
                      'AmarCity',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Tagline
                    const Text(
                      'SMART MUNICIPALITY PLATFORM',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Login form card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome text
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Sign in to your civic dashboard',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Email input field
                        const Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'rahim@example.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF0066CC),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF0066CC),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        // Password input field
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          // _obscurePassword true হলে password লুকানো থাকবে
                          obscureText: _obscurePassword == true,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: Color(0xFF0066CC),
                              size: 20,
                            ),
                            // Eye icon — password দেখানো/লুকানোর জন্য
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF0066CC),
                                size: 20,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF0066CC),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Forgot password button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Forgot password implement করতে হবে
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF0066CC),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Role selection section
                        const Text(
                          'SIGN IN AS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ৩টি role button — Citizen, Officer, Admin
                        Row(
                          children: [
                            _buildRoleButton('Citizen', Icons.person),
                            const SizedBox(width: 10),
                            _buildRoleButton('Officer', Icons.work),
                            const SizedBox(width: 10),
                            _buildRoleButton('Admin', Icons.shield),
                          ],
                        ),
                        const SizedBox(height: 25),
                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            // Loading চলাকালীন button disable থাকবে
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066CC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            // Loading হলে spinner, না হলে text দেখাবে
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign in securely',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Divider — 'or continue with' text সহ
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Social login buttons — Google ও Facebook
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Google sign in implement করতে হবে
                                },
                                icon: const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 14,
                                  ),
                                ),
                                label: const SizedBox.shrink(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Facebook sign in implement করতে হবে
                                },
                                icon: const Text(
                                  'Facebook',
                                  style: TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 14,
                                  ),
                                ),
                                label: const SizedBox.shrink(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Create account link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'New to AmarCity? ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Create account',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0066CC),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  // tap করলে create account screen এ navigate
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/create_account');
                                    },
                                ),
                                const TextSpan(
                                  text: ' ↗',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0066CC),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Role selection button widget — Citizen, Officer, Admin
  Widget _buildRoleButton(String role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        // tap করলে selected role পরিবর্তন হবে
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              // selected হলে নীল border, না হলে ধূসর
              color: isSelected
                  ? const Color(0xFF0066CC)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? const Color(0xFF0066CC).withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF999999),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                role,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0066CC)
                      : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
