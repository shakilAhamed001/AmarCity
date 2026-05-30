// Flutter material design import
import 'package:flutter/material.dart';
// Supabase auth এর UserAttributes ও AuthException এর জন্য
import 'package:supabase_flutter/supabase_flutter.dart';
// Supabase database ও auth service
import '../../services/supabase_service.dart';

// ChangePasswordScreen — Citizen এর password পরিবর্তনের screen
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // তিনটি password field এর controller
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Password visibility toggle — শুরুতে সব hidden
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  // Submit loading state
  bool _isLoading = false;

  @override
  void dispose() {
    // Memory leak এড়াতে সব controller dispose করা হচ্ছে
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password change করার main function
  Future<void> _changePassword() async {
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Validation — সব field পূরণ হয়েছে কিনা check
    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    // নতুন password কমপক্ষে ৬ character হতে হবে
    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }
    // নতুন password ও confirm password match করতে হবে
    if (newPass != confirmPass) {
      _showSnack('New passwords do not match');
      return;
    }
    // নতুন password পুরনো password এর মতো হওয়া যাবে না
    if (currentPass == newPass) {
      _showSnack('New password must be different from current password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // প্রথমে current password দিয়ে re-authenticate করা হচ্ছে
      // এতে নিশ্চিত হওয়া যাচ্ছে যে current password সঠিক
      final email = AuthService.currentUser!.email!;
      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPass,
      );
      // Current password সঠিক হলে নতুন password update করা হচ্ছে
      await supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        _showSnack('Password changed successfully');
        // Success হলে আগের screen এ ফিরে যাচ্ছে
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      // Supabase auth error handle করা হচ্ছে
      if (mounted) {
        if (e.message.toLowerCase().contains('invalid')) {
          // 'invalid' error মানে current password ভুল
          _showSnack('Current password is incorrect');
        } else {
          _showSnack(e.message);
        }
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      // সব ক্ষেত্রে loading বন্ধ করা হচ্ছে
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Snackbar দেখানোর helper function
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Change Password',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Lock icon — screen এর top এ decorative icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    size: 48, color: Color(0xFF1E40AF)),
              ),
            ),
            const SizedBox(height: 12),
            // Title text
            const Center(
              child: Text('Set a new password',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937))),
            ),
            const SizedBox(height: 6),
            // Subtitle — password requirement hint
            const Center(
              child: Text('Your new password must be at least 6 characters',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ),
            const SizedBox(height: 36),
            // Current password field
            _buildPasswordField(
              label: 'CURRENT PASSWORD',
              controller: _currentPasswordController,
              obscure: _obscureCurrent,
              hint: 'Enter current password',
              // Eye icon toggle — password দেখা/লুকানো
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 20),
            // New password field
            _buildPasswordField(
              label: 'NEW PASSWORD',
              controller: _newPasswordController,
              obscure: _obscureNew,
              hint: 'Enter new password',
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 20),
            // Confirm new password field
            _buildPasswordField(
              label: 'CONFIRM NEW PASSWORD',
              controller: _confirmPasswordController,
              obscure: _obscureConfirm,
              hint: 'Re-enter new password',
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 36),
            // Change Password submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // Loading চলাকালীন button disable থাকবে
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                // Loading হলে spinner, না হলে text
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Change Password',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable password field widget — label, controller, visibility toggle সহ
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required String hint,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label — uppercase
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          // obscure true হলে password hidden থাকবে
          obscureText: obscure == true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF999999), fontSize: 14),
            // বাম পাশে lock icon
            prefixIcon: const Icon(Icons.lock_outlined,
                color: Color(0xFF1E40AF), size: 20),
            // ডান পাশে eye icon — visibility toggle করে
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF1E40AF),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            // Focus হলে নীল border দেখাবে
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF1E40AF), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }
}
