import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../complaint_tracking/complaint_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import 'officer_profile.dart';

class OfficerScreen extends StatefulWidget {
  const OfficerScreen({Key? key}) : super(key: key);

  @override
  State<OfficerScreen> createState() => _OfficerScreenState();
}

class _OfficerScreenState extends State<OfficerScreen> {
  int _selectedIndex = 0;
  String _userName = 'Officer';
  String _department = '';

  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  int _assignedCount = 0;
  int _inProgressCount = 0;
  int _doneCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final user = AuthService.currentUser;
    if (user != null) {
      setState(() {
        _userName = (user.userMetadata?['full_name'] as String?) ?? 'Officer';
        _department = (user.userMetadata?['department'] as String?) ?? '';
      });
    }
    await _fetchTasks();
  }

  void _loadUser() {
    final user = AuthService.currentUser;
    if (user != null) {
      setState(() {
        _userName = (user.userMetadata?['full_name'] as String?) ?? 'Officer';
        _department = (user.userMetadata?['department'] as String?) ?? '';
      });
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final cData = await supabase
          .from('complaints')
          .select()
          .eq('assigned_officer_id', AuthService.currentUser!.id)
          .order('created_at', ascending: false);
      final complaints = List<Map<String, dynamic>>.from(cData);

      setState(() {
        _tasks = complaints;
        _assignedCount = complaints
            .where((c) => c['status'] == 'New' || c['status'] == 'In progress')
            .length;
        _inProgressCount =
            complaints.where((c) => c['status'] == 'In progress').length;
        _doneCount =
            complaints.where((c) => c['status'] == 'Resolved').length;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show notifications screen when tab 2 is selected
    if (_selectedIndex == 2) {
      return Scaffold(
        body: NotificationsScreen(
          viewerRole: 'Officer',
          onBack: () => setState(() => _selectedIndex = 0),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildStatisticsCards(),
              _buildMyTasks(),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_department.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(_department,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ),
                  const Text('Good morning,',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(_userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_outline,
                      color: Colors.white, size: 24),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const OfficerProfileScreen(),
                    ));
                    _loadUser();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          _buildStatCard(
              _assignedCount.toString(), 'Assigned', const Color(0xFF1E40AF)),
          _buildStatCard(
              _inProgressCount.toString(), 'In Progress', const Color(0xFFF59E0B)),
          _buildStatCard(
              _doneCount.toString(), 'Resolved', const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
    final cardColor = Theme.of(context).cardColor;
    final textSecondary =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(number,
                style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasks() {
    final textSecondary =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MY TASKS',
              style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text('No tasks assigned yet.',
                  style: TextStyle(color: textSecondary, fontSize: 13)),
            )
          else
            ..._tasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTaskCard(t),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    final status = task['status'] ?? 'Pending';
    final statusColor = _statusColor(status);
    final category = task['category'] ?? 'OTHER';
    final icon = _categoryIcon(category);
    final iconColor = _categoryColor(category);
    final isComplaint = task.containsKey('citizen_id');

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(
          complaint: task,
          viewerRole: 'Officer',
        ),
      )).then((_) => _fetchTasks()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isComplaint)
                    Text('#${task['complaint_id'] ?? ''}',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  Text(task['title'] ?? '',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if ((task['location'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isComplaint)
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFF6B7280)),
                        if (isComplaint) const SizedBox(width: 4),
                        Text(task['location'] ?? '',
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ],
                  if (isComplaint) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Citizen Complaint',
                          style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF1E40AF),
        unselectedItemColor: const Color(0xFFD1D5DB),
        items: [
          BottomNavigationBarItem(
            icon: Icon(
                _selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1
                ? Icons.search
                : Icons.search_outlined),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 2
                ? Icons.notifications
                : Icons.notifications_outlined),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Urgent':
        return const Color(0xFFDC2626);
      case 'Review':
        return const Color(0xFF3B82F6);
      case 'Done':
        return const Color(0xFF059669);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ROAD':
        return Icons.warning_outlined;
      case 'WATER':
        return Icons.water_drop_outlined;
      case 'LIGHTING':
        return Icons.lightbulb_outline;
      case 'GARBAGE':
        return Icons.delete_outline;
      case 'DRAINAGE':
        return Icons.water_drop_outlined;
      case 'LICENSE':
        return Icons.description_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'ROAD':
        return const Color(0xFFDC2626);
      case 'WATER':
        return const Color(0xFF3B82F6);
      case 'LIGHTING':
        return const Color(0xFFFCD34D);
      case 'GARBAGE':
        return const Color(0xFF6B7280);
      case 'DRAINAGE':
        return const Color(0xFF60A5FA);
      case 'LICENSE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
