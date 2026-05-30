import 'supabase_service.dart';

class NotificationService {
  // Insert a notification row for a specific user
  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    required String type, // 'assignment' | 'status_update'
    required String complaintId,
  }) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'complaint_id': complaintId,
      'is_read': false,
    });
  }

  // Fetch notifications for current user, newest first
  static Future<List<Map<String, dynamic>>> fetchForUser(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Mark a notification as read
  static Future<void> markRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // Mark all notifications as read for a user
  static Future<void> markAllRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('user_id', userId);
  }

  // Add a status history entry
  static Future<void> addStatusHistory({
    required String complaintId,
    required String status,
    String? comment,
    required String updatedBy,
  }) async {
    await supabase.from('complaint_status_history').insert({
      'complaint_id': complaintId,
      'status': status,
      'comment': comment,
      'updated_by': updatedBy,
    });
  }

  // Fetch status history for a complaint
  static Future<List<Map<String, dynamic>>> fetchStatusHistory(
      String complaintId) async {
    final data = await supabase
        .from('complaint_status_history')
        .select()
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }
}
