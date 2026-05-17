// Flutter material design import
import 'package:flutter/material.dart';
// Supabase database connection এর জন্য
import '../../services/supabase_service.dart';

// AdminUserDetailScreen — একজন user এর সব details দেখানোর screen
class AdminUserDetailScreen extends StatefulWidget {
  // Parent screen থেকে user data pass করা হয়
  final Map<String, dynamic> user;
  const AdminUserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  // এই user এর complaint list
  List<Map<String, dynamic>> _complaints = [];
  // Complaints load হচ্ছে কিনা
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Screen load হলে এই user এর complaints fetch করা হচ্ছে
    _fetchComplaints();
  }

  // Supabase থেকে এই user এর complaints fetch করার function
  Future<void> _fetchComplaints() async {
    try {
      // complaints table থেকে শুধু এই user এর complaints আনা হচ্ছে
      // citizen_id দিয়ে filter করা হচ্ছে
      final data = await supabase
          .from('complaints')
          .select()
          .eq('citizen_id', widget.user['id'])
          .order('created_at', ascending: false);
      setState(() {
        _complaints = (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // widget.user থেকে সব field safe ভাবে extract করা হচ্ছে
    final u = widget.user;
    final name = (u['full_name'] ?? 'Unknown') as String;
    final email = (u['email'] ?? '') as String;
    final role = (u['role'] ?? 'Citizen') as String;
    final department = (u['department'] ?? '') as String;
    // Address fields
    final house = (u['house_number'] ?? '') as String;
    final street = (u['street_name'] ?? '') as String;
    final ward = (u['ward_number'] ?? '') as String;
    final city = (u['city'] ?? '') as String;
    final state = (u['state'] ?? '') as String;
    final postal = (u['postal_code'] ?? '') as String;
    final country = (u['country'] ?? '') as String;
    // Officer হলে নীল, Citizen হলে সবুজ
    final roleColor = role == 'Officer'
        ? const Color(0xFF3B82F6)
        : const Color(0xFF10B981);
    // নামের প্রথম অক্ষর avatar হিসেবে
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C1D95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'User Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card — avatar, নাম, email, role badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Circle avatar — নামের প্রথম অক্ষর দিয়ে
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: roleColor.withOpacity(0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Department section — শুধু Officer এর জন্য দেখাবে
            if (department.isNotEmpty) ...[
              _sectionTitle('DEPARTMENT'),
              const SizedBox(height: 10),
              _infoCard([
                _infoRow(Icons.business_outlined, 'Department', department),
              ]),
              const SizedBox(height: 20),
            ],

            // Address section — কোনো address field থাকলে দেখাবে
            if (house.isNotEmpty || street.isNotEmpty || city.isNotEmpty) ...[
              _sectionTitle('ADDRESS'),
              const SizedBox(height: 10),
              _infoCard([
                // শুধু যেসব field এ data আছে সেগুলো দেখাবে
                if (house.isNotEmpty)
                  _infoRow(Icons.home_outlined, 'House / Apt', house),
                if (street.isNotEmpty)
                  _infoRow(Icons.signpost_outlined, 'Street', street),
                if (ward.isNotEmpty)
                  _infoRow(Icons.grid_3x3_outlined, 'Ward', ward),
                if (city.isNotEmpty)
                  _infoRow(Icons.location_city_outlined, 'City', city),
                if (state.isNotEmpty)
                  _infoRow(Icons.map_outlined, 'State', state),
                if (postal.isNotEmpty)
                  _infoRow(Icons.markunread_mailbox_outlined, 'Postal', postal),
                if (country.isNotEmpty)
                  _infoRow(Icons.flag_outlined, 'Country', country),
              ]),
              const SizedBox(height: 20),
            ],

            // Complaints section — শুধু Citizen এর জন্য দেখাবে
            if (role == 'Citizen') ...[
              // Complaint count সহ section title
              _sectionTitle('COMPLAINTS (${_complaints.length})'),
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _complaints.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No complaints submitted.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ),
                    )
                  // প্রতিটি complaint card হিসেবে দেখানো হচ্ছে
                  : Column(
                      children: _complaints
                          .map((c) => _complaintCard(c))
                          .toList(),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  // Section title widget — বেগুনি রঙে uppercase text
  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Color(0xFF7C3AED),
      letterSpacing: 0.5,
    ),
  );

  // Info card — একটি white card এ rows দেখায়
  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: rows),
    );
  }

  // একটি info row — icon, label ও value দেখায়
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label — ছোট ধূসর text
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                // Value — বড় text
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // একটি complaint card widget
  Widget _complaintCard(Map<String, dynamic> c) {
    final status = c['status'] ?? 'New';
    // Status অনুযায়ী রঙ নির্ধারণ
    final statusColor = _statusColor(status);
    // ISO date কে readable format এ convert
    final date = _formatDate(c['created_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Complaint ID
              Text(
                '#${c['complaint_id'] ?? ''}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Complaint title
          Text(
            c['title'] ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              // Location
              Text(
                c['location'] ?? '',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const Spacer(),
              // Submit date
              Text(
                date,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              c['category'] ?? '',
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Status অনুযায়ী রঙ return করার helper function
  Color _statusColor(String status) {
    switch (status) {
      case 'In progress':
        return const Color(0xFFF59E0B);
      case 'Resolved':
        return const Color(0xFF059669);
      case 'Escalated':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF3B82F6); // New
    }
  }

  // ISO date string কে 'Jan 5, 2024' format এ convert করার function
  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
