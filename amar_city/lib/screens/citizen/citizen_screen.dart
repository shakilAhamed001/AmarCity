import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'citizen_profile.dart';

class CitizenScreen extends StatefulWidget {
  const CitizenScreen({Key? key}) : super(key: key);

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> {
  int _selectedIndex = 0;
  String _selectedComplaintFilter = 'New';
  String _userName = 'Citizen';

  List<Map<String, dynamic>> _allComplaints = [];
  bool _isLoading = true;

  // Stats
  int _totalComplaints = 0;
  int _inProgressCount = 0;
  int _resolvedCount = 0;
  int _escalatedCount = 0;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    if (user != null) {
      _userName = user.userMetadata?['full_name'] ?? 'Citizen';
    }
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('complaints')
          .select()
          .eq('citizen_id', AuthService.currentUser!.id)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);
      setState(() {
        _allComplaints = list;
        _totalComplaints = list.length;
        _inProgressCount = list.where((c) => c['status'] == 'In progress').length;
        _resolvedCount = list.where((c) => c['status'] == 'Resolved').length;
        _escalatedCount = list.where((c) => c['status'] == 'Escalated').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedComplaintFilter == 'New') {
      return _allComplaints.where((c) => c['status'] == 'New').toList();
    }
    return _allComplaints
        .where((c) => c['status'] == _selectedComplaintFilter)
        .toList();
  }

  List<Map<String, dynamic>> get _recentComplaints =>
      _allComplaints.take(2).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withOpacity(0.6);
    final bgColor = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildQuickActions(),
              _buildRecentComplaints(),
              _buildMyComplaintsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const CitizenProfileScreen()),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStatCard('$_totalComplaints', 'Total\nReports'),
              _buildHeaderStatCard('$_inProgressCount', 'In\nProgress'),
              _buildHeaderStatCard('$_resolvedCount', 'Resolved'),
              _buildHeaderStatCard('$_escalatedCount', 'Escalated'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatCard(String number, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickActionCard(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'Report issue',
                subtitle: 'Submit new complaint',
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                icon: Icons.list_alt_outlined,
                iconColor: const Color(0xFF059669),
                title: 'My complaints',
                subtitle: 'View & track all',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickActionCard(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: 'Live tracking',
                subtitle: 'Check complaint map',
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                icon: Icons.bar_chart_outlined,
                iconColor: const Color(0xFFEC4899),
                title: 'City stats',
                subtitle: 'Public analytics',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentComplaints() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent complaints',
                  style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {},
                child: const Text('See all >',
                    style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_recentComplaints.isEmpty)
            const Text('No complaints yet.',
                style: TextStyle(color: Color(0xFF6B7280)))
          else
            ..._recentComplaints.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildComplaintCard(c),
                )),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withOpacity(0.6);
    final status = c['status'] ?? 'New';
    final statusColor = _statusColor(status);
    final icon = _categoryIcon(c['category'] ?? 'OTHER');
    final iconColor = _categoryColor(c['category'] ?? 'OTHER');
    final date = _formatDate(c['created_at']);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['title'] ?? '', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(c['location'] ?? '', style: TextStyle(color: textSecondary, fontSize: 12)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('•', style: TextStyle(color: textSecondary))),
                  Text(date, style: TextStyle(color: textSecondary, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyComplaintsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My complaints',
              style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['New', 'In progress', 'Resolved', 'Escalated']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(f),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No $_selectedComplaintFilter complaints.',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          else
            ..._filteredComplaints.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMyComplaintItem(c),
                )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedComplaintFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedComplaintFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : theme.cardColor,
          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : theme.dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMyComplaintItem(Map<String, dynamic> c) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withOpacity(0.6);
    final textMuted = theme.colorScheme.onSurface.withOpacity(0.4);
    final status = c['status'] ?? 'New';
    final statusColor = _statusColor(status);
    final icon = _categoryIcon(c['category'] ?? 'OTHER');
    final iconColor = _categoryColor(c['category'] ?? 'OTHER');
    final date = _formatDate(c['created_at']);
    final officer = c['assigned_officer_name'] ?? 'Unassigned';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${c['complaint_id'] ?? ''}', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['title'] ?? '', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(c['location'] ?? '', style: TextStyle(color: textSecondary, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(date, style: TextStyle(color: textMuted, fontSize: 11)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('•', style: TextStyle(color: textMuted, fontSize: 11))),
                  Expanded(child: Text('Officer: $officer', style: TextStyle(color: textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CitizenProfileScreen()));
            return;
          }
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF1E40AF),
        unselectedItemColor: const Color(0xFFD1D5DB),
        items: [
          BottomNavigationBarItem(
              icon: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(
                  _selectedIndex == 1 ? Icons.edit : Icons.edit_outlined),
              label: 'Report'),
          BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2
                  ? Icons.format_list_bulleted
                  : Icons.format_list_bulleted_outlined),
              label: 'My issues'),
          BottomNavigationBarItem(
              icon: Icon(
                  _selectedIndex == 3 ? Icons.person : Icons.person_outline),
              label: 'Profile'),
        ],
      ),
    );
  }

  // Helpers
  Color _statusColor(String status) {
    switch (status) {
      case 'In progress': return const Color(0xFFF59E0B);
      case 'Resolved':    return const Color(0xFF059669);
      case 'Escalated':   return const Color(0xFFDC2626);
      default:            return const Color(0xFF3B82F6);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ROAD':      return Icons.warning_amber;
      case 'LIGHTING':  return Icons.lightbulb_outline;
      case 'GARBAGE':   return Icons.delete_outline;
      case 'DRAINAGE':
      case 'WATER':     return Icons.water_drop_outlined;
      default:          return Icons.report_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'ROAD':
      case 'LIGHTING':  return const Color(0xFFFCD34D);
      case 'GARBAGE':   return const Color(0xFF6B7280);
      case 'DRAINAGE':  return const Color(0xFF3B82F6);
      case 'WATER':     return const Color(0xFF60A5FA);
      default:          return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
