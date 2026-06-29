import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_city/l10n/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'citizen_profile.dart';
import 'citizen_report.dart';
import '../complaint_tracking/complaint_detail_screen.dart';
import '../notifications/notifications_screen.dart';

class CitizenScreen extends StatefulWidget {
  const CitizenScreen({Key? key}) : super(key: key);

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> {
  int _selectedIndex = 0;
  // key-based filter: 'new', 'in_progress', 'resolved', 'escalated'
  String _selectedComplaintFilter = 'new';
  String _userName = 'Citizen';

  List<Map<String, dynamic>> _allComplaints = [];
  bool _isLoading = true;

  int _totalComplaints = 0;
  int _inProgressCount = 0;
  int _resolvedCount = 0;
  int _escalatedCount = 0;

  int _unreadCount = 0;
  RealtimeChannel? _notifChannel;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    if (user != null) {
      _userName = user.userMetadata?['full_name'] ?? 'Citizen';
    }
    _fetchComplaints();
    _fetchUnreadCount();
    _subscribeNotifications();
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    try {
      final data = await NotificationService.fetchForUser(user.id);
      if (mounted) {
        setState(() {
          _unreadCount = data.where((n) => n['is_read'] == false).length;
        });
      }
    } catch (_) {}
  }

  void _subscribeNotifications() {
    final user = AuthService.currentUser;
    if (user == null) return;
    _notifChannel = supabase
        .channel('citizen_notif:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (mounted) setState(() => _unreadCount++);
          },
        )
        .subscribe();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('complaints')
          .select()
          .eq('citizen_id', AuthService.currentUser!.id)
          .order('created_at', ascending: false);

      final list = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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
    const filterMap = {
      'new': 'New',
      'in_progress': 'In progress',
      'resolved': 'Resolved',
      'escalated': 'Escalated',
    };
    final dbStatus = filterMap[_selectedComplaintFilter];
    if (dbStatus == null) return _allComplaints;
    return _allComplaints.where((c) => c['status'] == dbStatus).toList();
  }

  List<Map<String, dynamic>> get _recentComplaints =>
      _allComplaints.take(2).toList();

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex == 2) {
      return NotificationsScreen(
        viewerRole: 'Citizen',
        onBack: () => setState(() => _selectedIndex = 0),
      );
    }

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
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
    final l10n = AppLocalizations.of(context)!;
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
                  Text(
                    l10n.goodMorning,
                    style: const TextStyle(
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
                child: ProfileAvatarWidget(userName: _userName, radius: 22),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStatCard('$_totalComplaints', l10n.totalReports),
              _buildHeaderStatCard('$_inProgressCount', l10n.inProgress),
              _buildHeaderStatCard('$_resolvedCount', l10n.resolved),
              _buildHeaderStatCard('$_escalatedCount', l10n.escalated),
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
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.quickActions,
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickActionCard(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: l10n.reportIssue,
                subtitle: l10n.submitNewComplaint,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const CitizenReportScreen()));
                  _fetchComplaints();
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                icon: Icons.list_alt_outlined,
                iconColor: const Color(0xFF059669),
                title: l10n.myComplaints,
                subtitle: l10n.viewAndTrackAll,
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
                title: l10n.liveTracking,
                subtitle: l10n.checkComplaintMap,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                icon: Icons.bar_chart_outlined,
                iconColor: const Color(0xFFEC4899),
                title: l10n.cityStats,
                subtitle: l10n.publicAnalytics,
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
    final textSecondary =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.recentComplaints,
                  style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {},
                child: Text(l10n.seeAll,
                    style: const TextStyle(
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
            Text(l10n.noComplaintsYet,
                style: const TextStyle(color: Color(0xFF6B7280)))
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
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(
              complaint: c,
              viewerRole: 'Citizen',
            ),
          ))
          .then((_) => _fetchComplaints()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['title'] ?? '',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(c['location'] ?? '',
                        style:
                            TextStyle(color: textSecondary, fontSize: 12)),
                    Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•',
                            style: TextStyle(color: textSecondary))),
                    Text(date,
                        style:
                            TextStyle(color: textSecondary, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyComplaintsSection() {
    final l10n = AppLocalizations.of(context)!;
    final filterLabels = [
      l10n.statusNew,
      l10n.inProgress,
      l10n.resolved,
      l10n.escalated,
    ];
    const filterKeys = ['new', 'in_progress', 'resolved', 'escalated'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.myComplaints,
              style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(filterKeys.length, (i) {
                final isSelected = _selectedComplaintFilter == filterKeys[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedComplaintFilter = filterKeys[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Theme.of(context).cardColor,
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(filterLabels[i],
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }),
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
                l10n.noFilteredComplaints(_selectedComplaintFilter),
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
    final officer = c['assigned_officer_name'] ??
        AppLocalizations.of(context)!.unassigned;
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(
              complaint: c,
              viewerRole: 'Citizen',
            ),
          ))
          .then((_) => _fetchComplaints()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
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
                      Text('#${c['id'] ?? ''}',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c['title'] ?? '',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(c['location'] ?? '',
                        style:
                            TextStyle(color: textSecondary, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(date,
                        style: TextStyle(color: textMuted, fontSize: 11)),
                    Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•',
                            style: TextStyle(
                                color: textMuted, fontSize: 11))),
                    Expanded(
                        child: Text(
                            '${AppLocalizations.of(context)!.officer}: $officer',
                            style:
                                TextStyle(color: textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final l10n = AppLocalizations.of(context)!;
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
          if (index == 1) {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => const CitizenReportScreen()))
                .then((_) => _fetchComplaints());
            return;
          }
          if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CitizenProfileScreen()));
            return;
          }
          if (index == 2) {
            setState(() {
              _unreadCount = 0;
              _selectedIndex = 2;
            });
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
              label: l10n.home),
          BottomNavigationBarItem(
              icon: Icon(
                  _selectedIndex == 1 ? Icons.edit : Icons.edit_outlined),
              label: l10n.report),
          BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_selectedIndex == 2
                      ? Icons.notifications
                      : Icons.notifications_outlined),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: l10n.notifications),
          BottomNavigationBarItem(
              icon: Icon(
                  _selectedIndex == 3 ? Icons.person : Icons.person_outline),
              label: l10n.profile),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In progress':
        return const Color(0xFFF59E0B);
      case 'Resolved':
        return const Color(0xFF059669);
      case 'Escalated':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ROAD':
        return Icons.warning_amber;
      case 'LIGHTING':
        return Icons.lightbulb_outline;
      case 'GARBAGE':
        return Icons.delete_outline;
      case 'DRAINAGE':
      case 'WATER':
        return Icons.water_drop_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'ROAD':
      case 'LIGHTING':
        return const Color(0xFFFCD34D);
      case 'GARBAGE':
        return const Color(0xFF6B7280);
      case 'DRAINAGE':
        return const Color(0xFF3B82F6);
      case 'WATER':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
