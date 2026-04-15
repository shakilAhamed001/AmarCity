import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('New passwords do not match');
      return;
    }
    if (currentPass == newPass) {
      _showSnack('New password must be different from current password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify current password by re-authenticating
      final email = AuthService.currentUser!.email!;
      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPass,
      );
      // Current password matched — now update
      await supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        _showSnack('Password changed successfully');
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.message.toLowerCase().contains('invalid')) {
          _showSnack('Current password is incorrect');
        } else {
          _showSnack(e.message);
        }
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            // Icon
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
            const Center(
              child: Text('Set a new password',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937))),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Your new password must be at least 6 characters',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ),
            const SizedBox(height: 36),
            // Current Password
            _buildPasswordField(
              label: 'CURRENT PASSWORD',
              controller: _currentPasswordController,
              obscure: _obscureCurrent,
              hint: 'Enter current password',
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 20),
            // New Password
            _buildPasswordField(
              label: 'NEW PASSWORD',
              controller: _newPasswordController,
              obscure: _obscureNew,
              hint: 'Enter new password',
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 20),
            // Confirm Password
            _buildPasswordField(
              label: 'CONFIRM NEW PASSWORD',
              controller: _confirmPasswordController,
              obscure: _obscureConfirm,
              hint: 'Re-enter new password',
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 36),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure == true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF999999), fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outlined,
                color: Color(0xFF1E40AF), size: 20),
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
