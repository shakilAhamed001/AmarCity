// Flutter material design import
import 'package:flutter/material.dart';
// Supabase database connection এর জন্য
import '../../services/supabase_service.dart';
// User detail screen — tap করলে এখানে navigate করবে
import 'admin_user_detail_screen.dart';

// AdminUsers — Admin এর user management screen
class AdminUsers extends StatefulWidget {
  const AdminUsers({Key? key}) : super(key: key);

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  // Role filter — শুরুতে সব user দেখাবে
  String _selectedFilter = 'All';
  // Search query — নাম বা email দিয়ে খোঁজার জন্য
  String _searchQuery = '';
  // Database থেকে আনা সব user
  List<Map<String, dynamic>> _allUsers = [];
  // Data load হচ্ছে কিনা
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Screen load হলে users fetch করা হচ্ছে
    _fetchUsers();
  }

  // Supabase profiles table থেকে সব user fetch করার function
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // profiles table থেকে সব data আনা হচ্ছে, নতুন আগে
      final data = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _allUsers = (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Filter ও search অনুযায়ী user list return করে
  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString();
      final query = _searchQuery.toLowerCase();
      // নাম বা email এ search query আছে কিনা check
      final matchesSearch = name.contains(query) || email.contains(query);
      // Role filter match করা হচ্ছে
      final matchesFilter =
          _selectedFilter == 'All' ||
          role.toLowerCase() == _selectedFilter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // নির্দিষ্ট role এর user সংখ্যা count করার helper
  int _countByRole(String role) =>
      _allUsers.where((u) => (u['role'] ?? '') == role).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // উপরের gradient header — stats সহ
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              // নিচে টেনে refresh করলে users আবার fetch হবে
              onRefresh: _fetchUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Role filter chips
                    _buildFilters(),
                    const SizedBox(height: 16),
                    // Search field
                    _buildSearchField(),
                    const SizedBox(height: 16),
                    // Loading, empty বা user list দেখানো হচ্ছে
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No users found.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          )
                        : _buildUserList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header widget — gradient background, total count ও role stats
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
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // মোট user সংখ্যা dynamically দেখানো হচ্ছে
          Text(
            '${_allUsers.length} total users',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Citizen count stat
              _headerStat(
                '${_countByRole('Citizen')}',
                'Citizens',
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              // Officer count stat
              _headerStat(
                '${_countByRole('Officer')}',
                'Officers',
                const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Header এর একটি stat badge widget — count ও label দেখায়
  Widget _headerStat(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Role filter chips — All, Citizen, Officer
  Widget _buildFilters() {
    final filters = ['All', 'Citizen', 'Officer'];
    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            // tap করলে filter পরিবর্তন হবে
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // selected হলে বেগুনি, না হলে card color
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Search field widget — নাম বা email দিয়ে user খোঁজা যাবে
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(color: Color(0xFFB4B4B4), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Filtered user list — প্রতিটি user একটি card হিসেবে দেখানো হচ্ছে
  Widget _buildUserList() {
    return Column(
      children: _filteredUsers.map((u) {
        final name = (u['full_name'] ?? 'Unknown').toString();
        final email = (u['email'] ?? '').toString();
        final role = (u['role'] ?? 'Citizen').toString();
        final department = (u['department'] ?? '').toString();
        // নামের প্রথম অক্ষর avatar হিসেবে
        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        // Officer হলে নীল, Citizen হলে সবুজ
        final roleColor = role == 'Officer'
            ? const Color(0xFF3B82F6)
            : const Color(0xFF10B981);

        return GestureDetector(
          // tap করলে user detail screen এ navigate করবে
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdminUserDetailScreen(user: u),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar — নামের প্রথম অক্ষর দিয়ে
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User এর নাম
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // User এর email
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      // Department — শুধু Officer এর জন্য দেখাবে
                      if (department.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          department,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon — detail screen এ যাওয়ার ইঙ্গিত
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
    );
  }
}
