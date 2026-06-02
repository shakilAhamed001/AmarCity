import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

// ComplaintDetailScreen — একটি complaint এর সব details দেখানোর screen
// Citizen, Officer ও Admin তিনজনই এই screen ব্যবহার করে
class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final String viewerRole; // 'Citizen' | 'Officer' | 'Admin'

  const ComplaintDetailScreen({
    Key? key,
    required this.complaint,
    required this.viewerRole,
  }) : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  // Complaint data — mutable copy রাখা হচ্ছে যাতে update করা যায়
  late Map<String, dynamic> _complaint;
  // Status history list
  List<Map<String, dynamic>> _history = [];
  // Assigned officer এর profile
  Map<String, dynamic>? _officerProfile;
  // Complaint submit করা citizen এর profile
  Map<String, dynamic>? _citizenProfile;
  // Data load হচ্ছে কিনা
  bool _isLoading = true;
  // Status update হচ্ছে কিনা
  bool _isUpdating = false;
  // Officer এর comment field controller
  final _commentController = TextEditingController();

  // Available status options
  static const _statuses = ['New', 'In progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    // Parent থেকে আসা complaint data copy করা হচ্ছে
    _complaint = Map<String, dynamic>.from(widget.complaint);
    _loadDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Complaint এর সব details load করার function
  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      // Status history fetch করা হচ্ছে
      _history = await NotificationService.fetchStatusHistory(
          _complaint['id'].toString());

      // Assigned officer এর profile fetch করা হচ্ছে
      final officerId = _complaint['assigned_officer_id'];
      if (officerId != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', officerId)
            .maybeSingle();
        _officerProfile = data != null ? Map<String, dynamic>.from(data) : null;
      }

      // Citizen এর profile fetch করা হচ্ছে
      final citizenId = _complaint['citizen_id'];
      if (citizenId != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', citizenId)
            .maybeSingle();
        _citizenProfile = data != null ? Map<String, dynamic>.from(data) : null;
      }

      // সর্বশেষ complaint data fetch করা হচ্ছে — fresh data নিশ্চিত করতে
      final fresh = await supabase
          .from('complaints')
          .select()
          .eq('id', _complaint['id'])
          .single();
      _complaint = Map<String, dynamic>.from(fresh);
    } catch (e) {
      debugPrint('Load details error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Officer কর্তৃক complaint status update করার function
  Future<void> _updateStatus(String newStatus) async {
    final comment = _commentController.text.trim();
    setState(() => _isUpdating = true);
    try {
      final complaintId = _complaint['id'].toString();
      final officerId = AuthService.currentUser!.id;

      // Database এ complaint status update করা হচ্ছে
      await supabase
          .from('complaints')
          .update({'status': newStatus}).eq('id', complaintId);

      // Status history তে নতুন entry যোগ করা হচ্ছে
      await NotificationService.addStatusHistory(
        complaintId: complaintId,
        status: newStatus,
        comment: comment.isEmpty ? null : comment,
        updatedBy: officerId,
      );

      // Citizen কে notification পাঠানো হচ্ছে
      final citizenId = _complaint['citizen_id']?.toString();
      if (citizenId != null) {
        await NotificationService.send(
          userId: citizenId,
          title: 'Complaint Status Updated',
          body: 'Your complaint "${_complaint['title']}" is now $newStatus.',
          type: 'status_update',
          complaintId: complaintId,
        );
      }

      // সব Admin কে notification পাঠানো হচ্ছে
      final admins = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'Admin');
      for (final admin in (admins as List)) {
        await NotificationService.send(
          userId: admin['id'].toString(),
          title: 'Complaint Updated by Officer',
          body:
              'Complaint "${_complaint['title']}" status changed to $newStatus.',
          type: 'status_update',
          complaintId: complaintId,
        );
      }

      _commentController.clear();
      // Details reload করা হচ্ছে — fresh data দেখাতে
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _complaint['status'] as String? ?? 'New';
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text('Complaint Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      // Loading হলে spinner, না হলে details দেখানো হচ্ছে
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner — বর্তমান status দেখাচ্ছে
                  _buildStatusBanner(status, statusColor),
                  const SizedBox(height: 16),
                  // Complaint info card — title, description, location
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  // Image attachments — থাকলে দেখাবে
                  if (_complaint['image_urls'] != null &&
                      (_complaint['image_urls'] as List?)?.isNotEmpty == true)
                    _buildImagesCard(),
                  if (_complaint['image_urls'] != null &&
                      (_complaint['image_urls'] as List?)?.isNotEmpty == true)
                    const SizedBox(height: 16),
                  // Citizen info — Citizen ছাড়া অন্যরা দেখতে পাবে
                  if (_citizenProfile != null && widget.viewerRole != 'Citizen')
                    _buildCitizenCard(),
                  if (_citizenProfile != null && widget.viewerRole != 'Citizen')
                    const SizedBox(height: 16),
                  // Officer info — assign হলে দেখাবে
                  if (_officerProfile != null) _buildOfficerCard(),
                  if (_officerProfile != null) const SizedBox(height: 16),
                  // Status timeline — history দেখাচ্ছে
                  _buildTimeline(),
                  const SizedBox(height: 16),
                  // Status update panel — শুধু Officer দেখতে পাবে
                  if (widget.viewerRole == 'Officer') _buildStatusUpdatePanel(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // Status banner widget — বর্তমান status রঙ সহ দেখায়
  Widget _buildStatusBanner(String status, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            'Status: $status',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Complaint info card — category, title, description, location, department
  Widget _buildInfoCard() {
    final category = _complaint['category'] as String? ?? '';
    final title = _complaint['title'] as String? ?? '';
    final description = _complaint['description'] as String? ?? '';
    final location = _complaint['location'] as String? ?? '';
    final dept = _complaint['assigned_department'] as String? ?? '';
    final createdAt = _formatDate(_complaint['created_at'] as String?);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(category,
                    style: const TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              // Submit date
              Text(createdAt,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          // Complaint title
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          // Description
          Text(description,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
          const SizedBox(height: 12),
          // Location row
          _infoRow(Icons.location_on_outlined, location),
          // Department row — থাকলে দেখাবে
          if (dept.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.business_outlined, dept),
          ],
        ],
      ),
    );
  }

  // Image attachments card — complaint এর সাথে দেওয়া ছবি দেখায়
  Widget _buildImagesCard() {
    final raw = _complaint['image_urls'];
    if (raw == null) return const SizedBox.shrink();
    final urls = (raw as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (urls.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attachments',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          // Image grid — 3 column
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: urls.length,
            itemBuilder: (_, i) => GestureDetector(
              // Tap করলে full screen এ দেখাবে
              onTap: () => _showFullImage(urls[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urls[i],
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.broken_image_outlined,
                        color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Full screen image viewer dialog
  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            // Pinch to zoom সহ image দেখানো হচ্ছে
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Citizen information card — নাম, email, phone দেখায়
  Widget _buildCitizenCard() {
    final name = _citizenProfile!['full_name'] as String? ??
        _citizenProfile!['email'] as String? ??
        'Citizen';
    final email = _citizenProfile!['email'] as String? ?? '';
    final phone = _citizenProfile!['phone'] as String? ?? '';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Citizen Information',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 10),
          _infoRow(Icons.person_outline, name),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.email_outlined, email),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.phone_outlined, phone),
          ],
        ],
      ),
    );
  }

  // Assigned officer card — নাম, department, assign date দেখায়
  Widget _buildOfficerCard() {
    final name = _officerProfile!['full_name'] as String? ??
        _officerProfile!['email'] as String? ??
        'Officer';
    final dept = _officerProfile!['department'] as String? ?? '';
    final assignedAt = _formatDate(_complaint['updated_at'] as String?);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assigned Officer',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 10),
          _infoRow(Icons.badge_outlined, name),
          if (dept.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.business_outlined, dept),
          ],
          if (assignedAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.calendar_today_outlined, 'Assigned: $assignedAt'),
          ],
        ],
      ),
    );
  }

  // Status timeline widget — complaint এর সব status change history দেখায়
  Widget _buildTimeline() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Timeline',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Text('No history yet.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))
          else
            // প্রতিটি history entry timeline item হিসেবে দেখানো হচ্ছে
            ...List.generate(_history.length, (i) {
              final h = _history[i];
              final isLast = i == _history.length - 1;
              final hStatus = h['status'] as String? ?? '';
              final hComment = h['comment'] as String? ?? '';
              final hDate = _formatDate(h['created_at'] as String?);
              final color = _statusColor(hStatus);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      // Timeline dot — status color দিয়ে
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      // শেষ item ছাড়া connecting line দেখাবে
                      if (!isLast)
                        Container(
                            width: 2,
                            height: 40,
                            color: const Color(0xFFE5E7EB)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Status text
                              Text(hStatus,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const Spacer(),
                              // Date
                              Text(hDate,
                                  style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 11)),
                            ],
                          ),
                          // Comment — থাকলে দেখাবে
                          if (hComment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(hComment,
                                style: const TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // Status update panel — শুধু Officer দেখতে পাবে
  // Comment field ও status buttons দেখায়
  Widget _buildStatusUpdatePanel() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Update Status',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          // Optional comment field
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)...',
              hintStyle:
                  const TextStyle(color: Color(0xFFB4B4B4), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          // Status buttons — প্রতিটি status এর জন্য একটি button
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((s) {
              // বর্তমান status হলে filled, না হলে outlined style
              final isCurrent = _complaint['status'] == s;
              final color = _statusColor(s);
              return GestureDetector(
                // Update চলাকালীন tap disable থাকবে
                onTap: _isUpdating ? null : () => _updateStatus(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? color
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: _isUpdating
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: color))
                      : Text(s,
                          style: TextStyle(
                              color: isCurrent ? Colors.white : color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Reusable white card container widget
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  // Icon ও text সহ একটি info row widget
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF4B5563), fontSize: 13))),
      ],
    );
  }

  // Status অনুযায়ী রঙ return করার helper
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

  // ISO date string কে 'Jan 5, 2024' format এ convert করার helper
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
