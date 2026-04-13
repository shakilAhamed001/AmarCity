import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class CitizenProfileScreen extends StatelessWidget {
  const CitizenProfileScreen({Key? key}) : super(key: key);

  String get _userName {
    final user = AuthService.currentUser;
    return user?.userMetadata?['full_name'] ?? 'Citizen';
  }

  String get _userEmail {
    return AuthService.currentUser?.email ?? '';
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
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
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF1E40AF),
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            _userEmail,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Edit Profile',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildOption(context, Icons.settings, 'Settings'),
                _buildOption(context, Icons.list_alt_outlined, 'My Complaints'),
                _buildOption(context, Icons.location_on_outlined, 'Address'),
                _buildOption(context, Icons.lock_outline, 'Change Password'),
                _buildOption(context, Icons.help_outline, 'Help & Support'),
                _buildOption(context, Icons.logout, 'Log out',
                    color: Colors.red, onTap: () => _logout(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title,
      {Color color = Colors.black, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          trailing:
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
