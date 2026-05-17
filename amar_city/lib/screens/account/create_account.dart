// Flutter material design import
import 'package:flutter/material.dart';
// RichText এ tap handle করার জন্য
import 'package:flutter/gestures.dart';
// Auth service — account তৈরি করার জন্য
import '../../services/supabase_service.dart';

// CreateAccountScreen — নতুন account তৈরির screen
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // সব input field এর controller
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  // Password visibility toggle
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // বর্তমানে কোন role selected — শুরুতে Citizen
  String _selectedRole = 'Citizen';
  // Officer এর জন্য selected department
  String? _selectedDepartment;
  // Form submit loading state
  bool _isLoading = false;

  // Officer এর জন্য available department list
  static const List<String> _departments = [
    'Public Health & Sanitation Department',
    'Trade License Issuance & Registration Department',
    'Waste Management Department',
    'Engineering Department',
  ];

  @override
  void initState() {
    super.initState();
    // Controller initialize করা হচ্ছে
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // Memory leak এড়াতে সব controller dispose করা হচ্ছে
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Create account button press করলে এই function call হয়
  void _handleCreateAccount() async {
    // সব field পূরণ হয়েছে কিনা check
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    // Password match check
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    // Officer হলে department select করা বাধ্যতামূলক
    if (_selectedRole == 'Officer' && _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Supabase এ নতুন user তৈরি করা হচ্ছে
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        department: _selectedDepartment,
      );
      if (response.user != null && mounted) {
        // Email verification এর জন্য বলা হচ্ছে
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please check your email to verify.')),
        );
        // Login screen এ navigate করা হচ্ছে
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0066CC),
        title: const Text('Create Account'),
        elevation: 0,
      ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                    // Form title
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Join AmarCity community',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Full name field
                    _buildTextField(
                      label: 'FULL NAME',
                      hint: 'Rahim Ahmed',
                      icon: Icons.person_outline,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),
                    // Email field
                    _buildTextField(
                      label: 'EMAIL ADDRESS',
                      hint: 'rahim@example.com',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    // Password field
                    _buildPasswordField(
                      label: 'PASSWORD',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      onVisibilityToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Confirm password field
                    _buildPasswordField(
                      label: 'CONFIRM PASSWORD',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      obscure: _obscureConfirmPassword,
                      onVisibilityToggle: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Account type selection
                    const Text(
                      'ACCOUNT TYPE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Citizen ও Officer role button
                    Row(
                      children: [
                        _buildRoleButton('Citizen', Icons.person, 'General public user'),
                        const SizedBox(width: 12),
                        _buildRoleButton('Officer', Icons.work, 'Municipality staff'),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Officer select করলে department section দেখাবে
                    if (_selectedRole == 'Officer') ..._buildDepartmentSection(),
                    const SizedBox(height: 25),
                    // Create account button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066CC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Loading হলে spinner, না হলে text
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign in link — already have account
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.w600,
                              ),
                              // tap করলে login screen এ ফিরে যাবে
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).pop();
                                },
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
        ),
      ),
    );
  }

  // Department selection section — শুধু Officer এর জন্য
  List<Widget> _buildDepartmentSection() {
    return [
      const Text(
        'DEPARTMENT',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 12),
      // প্রতিটি department radio button হিসেবে দেখানো হচ্ছে
      ..._departments.map((dept) {
        final isSelected = _selectedDepartment == dept;
        return GestureDetector(
          // tap করলে department select হবে
          onTap: () => setState(() => _selectedDepartment = dept),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? const Color(0xFF0066CC) : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? const Color(0xFF0066CC).withOpacity(0.07)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                // Radio button icon
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFF0066CC) : const Color(0xFF999999),
                  size: 20,
                ),
                const SizedBox(width: 12),
                // Department name
                Expanded(
                  child: Text(
                    dept,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF0066CC) : const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  // Role selection button — Citizen বা Officer
  Widget _buildRoleButton(String role, IconData icon, String subtitle) {
    final bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF0066CC) : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? const Color(0xFF0066CC).withOpacity(0.08)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF0066CC) : const Color(0xFF999999),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                role,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF0066CC) : const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 3),
              // Role description
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF999999),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable text field widget
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF0066CC),
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
        ),
      ],
    );
  }

  // Reusable password field widget — visibility toggle সহ
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          // obscure true হলে password লুকানো থাকবে
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: Color(0xFF0066CC),
              size: 20,
            ),
            // Eye icon — visibility toggle
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF0066CC),
                size: 20,
              ),
              onPressed: onVisibilityToggle,
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
      ],
    );
  }
}
