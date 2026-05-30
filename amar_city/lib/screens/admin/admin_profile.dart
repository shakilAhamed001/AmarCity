// Flutter material design import
import 'package:flutter/material.dart';

// AdminProfile — Admin এর profile ও settings screen
class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // উপরের gradient header
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin এর avatar, নাম, email
                _buildAdminInfo(),
                const SizedBox(height: 32),
                // Complaints, Users, Resolution rate stats
                _buildStatsSection(),
                const SizedBox(height: 32),
                // Settings options list
                _buildSettingsSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header widget
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF2E1065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              // Notification icon
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '8:50',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Admin এর profile info — avatar, নাম, email, organization
  Widget _buildAdminInfo() {
    return Column(
      children: [
        // Shield icon দিয়ে admin avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.shield, color: Color(0xFF7C3AED), size: 50),
        ),
        const SizedBox(height: 24),
        // Admin এর title
        const Text(
          'City Administrator',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Admin email
        const Text(
          'admin@dhakacity.gov.bd',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // Organization badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: const Text(
            '● Dhaka City Corporation',
            style: TextStyle(
              color: Color(0xFF7C3AED),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Stats section — Complaints, Users, Resolution rate
  Widget _buildStatsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('248', 'Complaints', const Color(0xFF7C3AED)),
              // Vertical divider
              _buildDivider(),
              _buildStatItem('168', 'Users', const Color(0xFF10B981)),
              _buildDivider(),
              _buildStatItem('87%', 'Resolution', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  // একটি stat item — value, label, color নিয়ে তৈরি
  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Stats এর মাঝে vertical divider
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // Settings section — City settings, Export reports, Escalation rules
  Widget _buildSettingsSection() {
    // Settings option গুলোর data list
    final settings = [
      {
        'icon': Icons.location_city,
        'title': 'City settings',
        'subtitle': 'Configure city parameters and rules',
        'color': const Color(0xFF7C3AED),
      },
      {
        'icon': Icons.assessment,
        'title': 'Export reports',
        'subtitle': 'Download and export complaint data',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.warning_amber_rounded,
        'title': 'Escalation rules',
        'subtitle': 'Manage complaint escalation thresholds',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'SETTINGS',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        // প্রতিটি setting option card হিসেবে দেখানো হচ্ছে
        Column(
          children: settings.map((setting) {
            return GestureDetector(
              onTap: () {
                // tap করলে title দেখানো হচ্ছে — পরে navigate করা যাবে
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(setting['title'] as String)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Setting icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (setting['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        setting['icon'] as IconData,
                        color: setting['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Setting title
                          Text(
                            setting['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Setting description
                          Text(
                            setting['subtitle'] as String,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow icon
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFD1D5DB),
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Sign out button
        _buildSignOutButton(),
      ],
    );
  }

  // Sign out button widget
  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          // Sign out confirmation dialog দেখানো হচ্ছে
          _showSignOutDialog();
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Sign out',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Sign out confirmation dialog
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          // Cancel — dialog বন্ধ করবে
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Sign out — login page এ নিয়ে যাবে, সব route clear করে
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
