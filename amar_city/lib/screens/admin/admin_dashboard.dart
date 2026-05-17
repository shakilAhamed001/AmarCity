// Flutter material design import
import 'package:flutter/material.dart';
// Admin panel এর সব tab screen import
import 'admin_overview.dart';
import 'admin_users.dart';
import 'admin_complain.dart';
import 'admin_profile.dart';

// AdminDashboard — Admin এর main screen, bottom navigation সহ
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // বর্তমানে কোন tab selected আছে তা track করে — শুরুতে 0 (Overview)
  int _selectedTab = 0;

  // ৪টি tab এর screen list — index দিয়ে access করা হয়
  final List<Widget> _tabs = [
    const AdminOverview(),   // index 0 — Dashboard overview
    const AdminUsers(),      // index 1 — User management
    const AdminComplaints(), // index 2 — Complaints list
    const AdminProfile(),    // index 3 — Admin profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // _selectedTab অনুযায়ী সঠিক screen দেখানো হচ্ছে
      body: _tabs[_selectedTab],
      // নিচের navigation bar
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Bottom navigation bar widget
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // উপরে হালকা shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Overview',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                label: 'Users',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'Complaints',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.account_circle_outlined,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // একটি navigation item widget — icon, label ও index নিয়ে তৈরি
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    // এই item টি selected কিনা check করা হচ্ছে
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      // tap করলে selected tab পরিবর্তন হবে
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            // selected হলে বেগুনি, না হলে ধূসর
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFF9CA3AF),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
