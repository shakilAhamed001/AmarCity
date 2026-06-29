// EscalationService — 48 ঘণ্টার বেশি idle complaints auto-escalate করার service
// App start এ একবার call হয় এবং যোগ্য complaints এর status → Escalated করে দেয়

import 'supabase_service.dart';
import 'notification_service.dart';

class EscalationService {
  // কত ঘণ্টা idle থাকলে escalate হবে
  static const int _escalationHours = 48;

  // 48+ ঘণ্টা idle complaints check করে escalate করার main function
  // last_escalated_at check করা হয় — একই complaint বারবার escalate হবে না
  static Future<void> checkAndEscalate() async {
    try {
      // 48 ঘণ্টা আগের UTC timestamp threshold হিসেবে ব্যবহার হচ্ছে
      final threshold = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: _escalationHours))
          .toIso8601String();

      // New বা In progress status — threshold এর আগে updated এবং কখনো escalate হয়নি
      final data = await supabase
          .from('complaints')
          .select('id, title, citizen_id, updated_at')
          .inFilter('status', ['New', 'In progress'])
          .lt('updated_at', threshold)
          .isFilter('last_escalated_at', null);

      final complaints = List<Map<String, dynamic>>.from(data);

      // Escalate করার মতো complaint না থাকলে early return
      if (complaints.isEmpty) return;

      // সব Admin এর id fetch করা — তাদের notification পাঠাতে হবে
      final adminData = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'Admin');
      final adminIds =
          (adminData as List).map((a) => a['id'].toString()).toList();

      // প্রতিটি যোগ্য complaint process করা হচ্ছে
      for (final c in complaints) {
        final complaintId = c['id'].toString();
        final title = c['title'] as String? ?? 'Complaint';

        // Status → Escalated এবং last_escalated_at timestamp set করা
        // last_escalated_at থাকলে পরের run এ এটা আর escalate হবে না
        await supabase.from('complaints').update({
          'status': 'Escalated',
          'last_escalated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', complaintId);

        // Status history তে escalation event record করা
        await NotificationService.addStatusHistory(
          complaintId: complaintId,
          status: 'Escalated',
          comment: 'Auto-escalated: no update for $_escalationHours hours.',
          updatedBy: 'system',
        );

        // সব Admin কে notification পাঠানো
        for (final adminId in adminIds) {
          await NotificationService.send(
            userId: adminId,
            title: '⚠️ Auto-Escalated',
            body:
                '"$title" was escalated after $_escalationHours hrs of inactivity.',
            type: 'escalation',
            complaintId: complaintId,
          );
        }

        // Complaint এর citizen কেও notification পাঠানো
        final citizenId = c['citizen_id']?.toString();
        if (citizenId != null) {
          await NotificationService.send(
            userId: citizenId,
            title: 'Complaint Escalated',
            body:
                'Your complaint "$title" has been escalated due to no response within $_escalationHours hours.',
            type: 'escalation',
            complaintId: complaintId,
          );
        }
      }
    } catch (_) {
      // Silent fail — escalation error app launch কে block করবে না
    }
  }
}
