import 'package:flutter/material.dart';
import 'package:amar_city/l10n/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../services/theme_notifier.dart';
import '../../services/locale_service.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'officer_edit_profile_screen.dart';
import 'officer_address_screen.dart';
import '../citizen/change_password_screen.dart';

// OfficerProfileScreen — Officer এর profile page
class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({Key? key}) : super(key: key);

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  // Officer এর নাম, email ও department
  String _userName = '';
  String _userEmail = '';
  String _department = '';

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
      _userName = (user?.userMetadata?['full_name'] as String?) ?? 'Officer';
      _userEmail = user?.email ?? '';
      _department = (user?.userMetadata?['department'] as String?) ?? '';
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
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Profile picture — editable false
          ProfileAvatarWidget(userName: _userName, radius: 44),
          const SizedBox(height: 12),
          // Officer এর নাম
          Text(
            _userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          // Email
          Text(
            _userEmail,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          // Department badge — শুধু department থাকলে দেখাবে
          if (_department.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _department,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Edit profile button
          ElevatedButton(
            onPressed: () async {
              // Edit screen থেকে ফিরে আসলে user info reload হবে
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const OfficerEditProfileScreen(),
                ),
              );
              if (updated == true) _loadUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          // Profile options list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Address option
                _buildOption(
                  Icons.location_on_outlined,
                  'Address',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OfficerAddressScreen(),
                    ),
                  ),
                ),
                // Change password option
                _buildOption(
                  Icons.lock_outline,
                  'Change Password',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                _buildDarkModeOption(),
                _buildLanguageOption(),
                _buildOption(Icons.help_outline, 'Help & Support'),
                // Logout option — লাল রঙে
                _buildOption(
                  Icons.logout,
                  'Log out',
                  color: Colors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // একটি profile option item widget
  Widget _buildOption(
    IconData icon,
    String title, {
    Color? color,
    VoidCallback? onTap,
  }) {
    // color দেওয়া না হলে default text color ব্যবহার হবে
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: textColor),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildDarkModeOption() {
    final isDark = ThemeNotifier().isDark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        ListTile(
          leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: textColor),
          title: Text('Dark Mode', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
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

  Widget _buildLanguageOption() {
    final l10n = AppLocalizations.of(context)!;
    final isBangla = localeService.isBangla;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.language, color: textColor),
          title: Text(l10n.language, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          trailing: GestureDetector(
            onTap: () {
              localeService.toggle();
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E40AF).withOpacity(0.3)),
              ),
              child: Text(
                isBangla ? l10n.bangla : l10n.english,
                style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
