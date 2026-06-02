import 'supabase_service.dart';

// NotificationService — notification সংক্রান্ত সব database কাজ এখানে
class NotificationService {
  // নির্দিষ্ট user কে একটি notification পাঠানোর function
  // userId — যাকে notification পাঠাবে
  // type — 'assignment' বা 'status_update'
  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String complaintId,
  }) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'complaint_id': complaintId,
      // নতুন notification শুরুতে unread থাকে
      'is_read': false,
    });
  }

  // নির্দিষ্ট user এর সব notification fetch করার function — নতুন আগে
  static Future<List<Map<String, dynamic>>> fetchForUser(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // একটি notification কে read হিসেবে mark করার function
  static Future<void> markRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // একজন user এর সব notification কে read হিসেবে mark করার function
  static Future<void> markAllRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('user_id', userId);
  }

  // Complaint এর status history তে একটি নতুন entry যোগ করার function
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

  // একটি complaint এর সম্পূর্ণ status history fetch করার function — পুরনো আগে
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
