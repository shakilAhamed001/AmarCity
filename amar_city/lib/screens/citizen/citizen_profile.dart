// Flutter material design import
import 'package:flutter/material.dart';
// Auth service — current user info এর জন্য
import '../../services/supabase_service.dart';
// Theme toggle এর জন্য
import '../../services/theme_notifier.dart';
// Profile edit screen
import 'edit_profile_screen.dart';
// Address screen
import 'address_screen.dart';
// Password change screen
import 'change_password_screen.dart';

// CitizenProfileScreen — Citizen এর profile page
class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({Key? key}) : super(key: key);

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  // User এর নাম ও email
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    // User info load করা হচ্ছে
    _loadUser();
  }

  // Supabase auth থেকে current user এর info load করার function
  void _loadUser() {
    final user = AuthService.currentUser;
    setState(() {
      _userName = user?.userMetadata?['full_name'] ?? 'Citizen';
      _userEmail = user?.email ?? '';
    });
  }

  // Logout করার function
  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      // সব route clear করে login screen এ যাচ্ছে
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Profile',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Circle avatar — নামের প্রথম অক্ষর দিয়ে
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF1E40AF),
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          // User এর নাম
          Text(_userName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          // User এর email
          Text(_userEmail,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          // Edit profile button
          ElevatedButton(
            onPressed: () async {
              // Edit screen থেকে ফিরে আসলে user info reload হবে
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
              if (updated == true) _loadUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Edit Profile',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 24),
          // Profile options list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildOption(Icons.list_alt_outlined, 'My Complaints'),
                // Address option — tap করলে address screen এ যাবে
                _buildOption(Icons.location_on_outlined, 'Address',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const AddressScreen()),
                    )),
                // Change password option
                _buildOption(Icons.lock_outline, 'Change Password',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen()),
                    )),
                // Dark mode toggle
                _buildDarkModeOption(),
                _buildOption(Icons.help_outline, 'Help & Support'),
                // Logout option — লাল রঙে
                _buildOption(Icons.logout, 'Log out',
                    color: Colors.red, onTap: _logout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dark mode toggle option widget
  Widget _buildDarkModeOption() {
    final isDark = ThemeNotifier().isDark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        ListTile(
          leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: textColor),
          title: Text('Dark Mode', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          // Switch toggle — tap করলে theme পরিবর্তন হবে
          trailing: Switch(
            value: isDark,
            activeColor: const Color(0xFF1E40AF),
            onChanged: (_) {
              ThemeNotifier().toggle();
              setState(() {});
            },
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }

  // একটি profile option item widget
  Widget _buildOption(IconData icon, String title,
      {Color? color, VoidCallback? onTap}) {
    // color দেওয়া না হলে default text color ব্যবহার হবে
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: textColor),
          title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
