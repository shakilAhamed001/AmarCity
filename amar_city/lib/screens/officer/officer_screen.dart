import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
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
  int _urgentCount = 0;
  int _doneCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchTasks();
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
      final data = await supabase
          .from('tasks')
          .select()
          .eq('officer_id', AuthService.currentUser!.id)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);
      setState(() {
        _tasks = list;
        _assignedCount = list.where((t) => t['status'] != 'Done').length;
        _urgentCount = list.where((t) => t['status'] == 'Urgent').length;
        _doneCount = list.where((t) => t['status'] == 'Done').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_department.isNotEmpty == true)
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
                        builder: (context) => const OfficerProfileScreen()));
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
          _buildStatCard(_assignedCount.toString(), 'Assigned', const Color(0xFF1E40AF)),
          _buildStatCard(_urgentCount.toString(), 'Urgent', const Color(0xFFDC2626)),
          _buildStatCard(_doneCount.toString(), 'Resolved', const Color(0xFF059669)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MY TASKS',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              TextButton.icon(
                onPressed: _showAddTaskSheet,
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF1E40AF)),
                label: const Text('Add',
                    style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text('No tasks yet. Tap Add to create one.',
                  style: TextStyle(color: textSecondary, fontSize: 13)),
            )
          else
            ..._tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskCard(t),
                )),
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
    final icon = _categoryIcon(task['category'] ?? 'OTHER');
    final iconColor = _categoryColor(task['category'] ?? 'OTHER');

    return Container(
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
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['title'] ?? '',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if ((task['subtitle'] ?? '').isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(task['subtitle'],
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showEditTaskSheet(task),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _deleteTask(task['id']),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Task Bottom Sheet ─────────────────────────────────────────

  void _showAddTaskSheet() => _showTaskSheet();
  void _showEditTaskSheet(Map<String, dynamic> task) =>
      _showTaskSheet(task: task);

  void _showTaskSheet({Map<String, dynamic>? task}) {
    final titleController =
        TextEditingController(text: task?['title'] ?? '');
    final subtitleController =
        TextEditingController(text: task?['subtitle'] ?? '');
    String selectedStatus = task?['status'] ?? 'Pending';
    String selectedCategory = task?['category'] ?? 'OTHER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task == null ? 'Add Task' : 'Edit Task',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Title
                TextField(
                  controller: titleController,
                  decoration: _inputDecoration('Title', Icons.title),
                ),
                const SizedBox(height: 12),
                // Subtitle
                TextField(
                  controller: subtitleController,
                  decoration:
                      _inputDecoration('Subtitle (optional)', Icons.notes),
                ),
                const SizedBox(height: 12),
                // Status
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: _inputDecoration('Status', Icons.flag_outlined),
                  items: ['Pending', 'Urgent', 'Review', 'Done']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => selectedStatus = v ?? selectedStatus),
                ),
                const SizedBox(height: 12),
                // Category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration:
                      _inputDecoration('Category', Icons.category_outlined),
                  items: [
                    'ROAD',
                    'WATER',
                    'LIGHTING',
                    'GARBAGE',
                    'DRAINAGE',
                    'LICENSE',
                    'OTHER'
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setModalState(
                      () => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.of(context).pop();
                      if (task == null) {
                        await _addTask(
                          title: titleController.text.trim(),
                          subtitle: subtitleController.text.trim(),
                          status: selectedStatus,
                          category: selectedCategory,
                        );
                      } else {
                        await _updateTask(
                          id: task['id'],
                          title: titleController.text.trim(),
                          subtitle: subtitleController.text.trim(),
                          status: selectedStatus,
                          category: selectedCategory,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(task == null ? 'Add Task' : 'Save Changes',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1E40AF)),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _addTask({
    required String title,
    required String subtitle,
    required String status,
    required String category,
  }) async {
    try {
      await supabase.from('tasks').insert({
        'officer_id': AuthService.currentUser!.id,
        'title': title,
        'subtitle': subtitle.isEmpty ? null : subtitle,
        'status': status,
        'category': category,
      });
      _fetchTasks();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _updateTask({
    required String id,
    required String title,
    required String subtitle,
    required String status,
    required String category,
  }) async {
    try {
      await supabase.from('tasks').update({
        'title': title,
        'subtitle': subtitle.isEmpty ? null : subtitle,
        'status': status,
        'category': category,
      }).eq('id', id);
      _fetchTasks();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteTask(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.from('tasks').delete().eq('id', id);
      _fetchTasks();
    }
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
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1
                  ? Icons.search
                  : Icons.search_outlined),
              label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2
                  ? Icons.notifications
                  : Icons.notifications_outlined),
              label: 'Notifications'),
        ],
      ),
    );
  }

  // Helpers
  Color _statusColor(String status) {
    switch (status) {
      case 'Urgent':  return const Color(0xFFDC2626);
      case 'Review':  return const Color(0xFF3B82F6);
      case 'Done':    return const Color(0xFF059669);
      default:        return const Color(0xFFF59E0B);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ROAD':      return Icons.warning_outlined;
      case 'WATER':     return Icons.water_drop_outlined;
      case 'LIGHTING':  return Icons.lightbulb_outline;
      case 'GARBAGE':   return Icons.delete_outline;
      case 'DRAINAGE':  return Icons.water_drop_outlined;
      case 'LICENSE':   return Icons.description_outlined;
      default:          return Icons.task_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'ROAD':      return const Color(0xFFDC2626);
      case 'WATER':     return const Color(0xFF3B82F6);
      case 'LIGHTING':  return const Color(0xFFFCD34D);
      case 'GARBAGE':   return const Color(0xFF6B7280);
      case 'DRAINAGE':  return const Color(0xFF60A5FA);
      case 'LICENSE':   return const Color(0xFF8B5CF6);
      default:          return const Color(0xFF9CA3AF);
    }
  }
}
