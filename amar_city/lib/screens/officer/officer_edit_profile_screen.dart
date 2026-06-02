import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

// OfficerEditProfileScreen — Officer এর profile edit করার screen
class OfficerEditProfileScreen extends StatefulWidget {
  const OfficerEditProfileScreen({Key? key}) : super(key: key);

  @override
  State<OfficerEditProfileScreen> createState() =>
      _OfficerEditProfileScreenState();
}

class _OfficerEditProfileScreenState extends State<OfficerEditProfileScreen> {
  // নাম ও email field এর controller
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  // Save loading state
  bool _isLoading = false;

  // Department — auth metadata থেকে read করা হচ্ছে, change করা যাবে না
  String get _department =>
      (AuthService.currentUser?.userMetadata?['department'] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    // Current user এর info দিয়ে controllers initialize করা হচ্ছে
    final user = AuthService.currentUser;
    _nameController = TextEditingController(
      text: user?.userMetadata?['full_name'] ?? '',
    );
    // Email read-only — এখানে change করা যাবে না
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    // Memory leak এড়াতে controllers dispose করা হচ্ছে
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Profile save করার function
  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Name cannot be empty');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Supabase auth metadata তে full_name update করা হচ্ছে
      await supabase.auth.updateUser(
        UserAttributes(data: {'full_name': _nameController.text.trim()}),
      );
      // profiles table এও নাম update করা হচ্ছে
      await supabase
          .from('profiles')
          .update({'full_name': _nameController.text.trim()})
          .eq('id', AuthService.currentUser!.id);

      if (mounted) {
        _showSnack('Profile updated successfully');
        // true return করে parent screen কে জানানো হচ্ছে যে update হয়েছে
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Snackbar দেখানোর helper function
  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    // Avatar এ নামের প্রথম অক্ষর দেখানোর জন্য
    final userName = _nameController.text;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // AppBar এ Save button — loading চলাকালীন disable
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Circle avatar — নামের প্রথম অক্ষর দিয়ে
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF1E40AF),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('PERSONAL INFO'),
            const SizedBox(height: 12),
            // Full name field — editable
            _buildField(
              label: 'FULL NAME',
              controller: _nameController,
              icon: Icons.person_outline,
              hint: 'Enter your full name',
            ),
            const SizedBox(height: 16),
            // Email field — read-only
            _buildField(
              label: 'EMAIL ADDRESS',
              controller: _emailController,
              icon: Icons.email_outlined,
              hint: 'Email address',
              readOnly: true,
            ),
            const SizedBox(height: 4),
            const Text(
              'Email cannot be changed here.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            // Department field — read-only, শুধু Officer এর জন্য দেখাবে
            if (_department.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildReadOnlyInfo(
                'DEPARTMENT',
                _department,
                Icons.business_outlined,
              ),
            ],
            const SizedBox(height: 32),
            // Bottom Save Changes button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
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
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section title widget — নীল রঙে uppercase text
  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1E40AF),
      letterSpacing: 0.5,
    ),
  );

  // Read-only info display widget — department দেখানোর জন্য
  Widget _buildReadOnlyInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            // Read-only field এর background ধূসর
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1E40AF), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Reusable form field widget — label, icon, hint ও optional readOnly সহ
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label — uppercase ছোট text
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF1E40AF), size: 18),
            filled: true,
            // Read-only field এর background আলাদা রঙ
            fillColor: readOnly
                ? const Color(0xFFEEEEEE)
                : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            // Focus হলে নীল border দেখাবে
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1E40AF),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
