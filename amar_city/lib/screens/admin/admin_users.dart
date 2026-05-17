import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({Key? key}) : super(key: key);

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
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

  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(query) || email.contains(query);
      final matchesFilter =
          _selectedFilter == 'All' ||
          role.toLowerCase() == _selectedFilter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _countByRole(String role) =>
      _allUsers.where((u) => (u['role'] ?? '') == role).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _buildFilters(),
                    const SizedBox(height: 16),
                    _buildSearchField(),
                    const SizedBox(height: 16),
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
          Text(
            '${_allUsers.length} total users',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat(
                '${_countByRole('Citizen')}',
                'Citizens',
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
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

  Widget _buildFilters() {
    final filters = ['All', 'Citizen', 'Officer'];
    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
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

  Widget _buildUserList() {
    return Column(
      children: _filteredUsers.map((u) {
        final name = (u['full_name'] ?? 'Unknown').toString();
        final email = (u['email'] ?? '').toString();
        final role = (u['role'] ?? 'Citizen').toString();
        final department = (u['department'] ?? '').toString();
        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final roleColor = role == 'Officer'
            ? const Color(0xFF3B82F6)
            : const Color(0xFF10B981);

        return GestureDetector(
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
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
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
