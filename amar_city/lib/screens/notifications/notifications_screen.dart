import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../complaint_tracking/complaint_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String viewerRole;
  final VoidCallback? onBack;
  const NotificationsScreen({Key? key, required this.viewerRole, this.onBack})
      : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await NotificationService.fetchForUser(user.id);
      if (mounted) setState(() => _notifications = data);
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    final user = AuthService.currentUser;
    if (user == null) return;
    _channel = supabase
        .channel('notifications:${user.id}')
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
            if (mounted) {
              final newNotif = Map<String, dynamic>.from(payload.newRecord);
              setState(() => _notifications.insert(0, newNotif));
            }
          },
        )
        .subscribe();
  }

  Future<void> _openComplaint(Map<String, dynamic> notif) async {
    final complaintId = notif['complaint_id']?.toString();
    if (complaintId == null) return;

    // Mark as read
    if (notif['is_read'] == false) {
      await NotificationService.markRead(notif['id'].toString());
      setState(() => notif['is_read'] = true);
    }

    // Fetch complaint
    try {
      final data = await supabase
          .from('complaints')
          .select()
          .eq('id', complaintId)
          .single();
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ComplaintDetailScreen(
            complaint: Map<String, dynamic>.from(data),
            viewerRole: widget.viewerRole,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] == false).length;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Notifications not available.',
            style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Notifications${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () async {
                final user = AuthService.currentUser;
                if (user == null) return;
                await NotificationService.markAllRead(user.id);
                setState(() {
                  for (final n in _notifications) {
                    n['is_read'] = true;
                  }
                });
              },
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text('No notifications yet.',
                      style: TextStyle(color: Color(0xFF9CA3AF))))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildNotifCard(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif) {
    final isRead = notif['is_read'] == true;
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? '';
    final type = notif['type'] as String? ?? '';
    final date = _formatDate(notif['created_at'] as String?);

    return GestureDetector(
      onTap: () => _openComplaint(notif),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isRead
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF93C5FD)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor(type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon(type),
                  color: _typeColor(type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFF1F2937))),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(date,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'assignment':
        return const Color(0xFF7C3AED);
      case 'status_update':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_ind_outlined;
      case 'status_update':
        return Icons.update_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
