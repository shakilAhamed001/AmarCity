// NotificationService — সব in-app notification সংক্রান্ত database operations এখানে
// notifications ও complaint_status_history table এর সাথে interact করে

import 'supabase_service.dart';

class NotificationService {
  // নির্দিষ্ট user কে একটি notification পাঠানোর function
  // [userId]   — যাকে notification পাঠাবে
  // [type]     — 'assignment' | 'status_update' | 'escalation' | 'feedback'
  // [complaintId] — কোন complaint এর সাথে সম্পর্কিত
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
      'is_read': false, // নতুন notification সবসময় unread শুরু হয়
    });
  }

  // নির্দিষ্ট user এর সব notification fetch করা — সবচেয়ে নতুন আগে
  static Future<List<Map<String, dynamic>>> fetchForUser(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // একটি notification read হিসেবে mark করা
  static Future<void> markRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // একজন user এর সব notification একসাথে read mark করা
  static Future<void> markAllRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('user_id', userId);
  }

  // Complaint এর status history তে নতুন entry যোগ করা
  // [updatedBy] — officer id বা 'system' (auto-escalation এর ক্ষেত্রে)
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

  // একটি complaint এর সম্পূর্ণ status history fetch করা — পুরনো আগে (timeline এর জন্য)
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
