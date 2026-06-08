import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final String viewerRole;

  const ComplaintDetailScreen({
    Key? key,
    required this.complaint,
    required this.viewerRole,
  }) : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Map<String, dynamic> _complaint;
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _officerProfile;
  Map<String, dynamic>? _citizenProfile;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _updatingStatus; // কোন status button এ spinner দেখাবে track করার জন্য
  final _commentController = TextEditingController();

  static const _statuses = ['New', 'In progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _complaint = Map<String, dynamic>.from(widget.complaint);
    _loadDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // showLoading false হলে spinner দেখাবে না — status update এর পরে reload এর জন্য
  Future<void> _loadDetails({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      _history = await NotificationService.fetchStatusHistory(
          _complaint['id'].toString());

      // Officer profile — null safe check
      final officerId = _complaint['assigned_officer_id']?.toString();
      if (officerId != null && officerId.isNotEmpty) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', officerId)
            .maybeSingle();
        _officerProfile = data != null ? Map<String, dynamic>.from(data) : null;
      } else {
        _officerProfile = null;
      }

      final citizenId = _complaint['citizen_id'];
      if (citizenId != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', citizenId)
            .maybeSingle();
        _citizenProfile = data != null ? Map<String, dynamic>.from(data) : null;
      }

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

  Future<void> _updateStatus(String newStatus) async {
    final comment = _commentController.text.trim();
    setState(() {
      _isUpdating = true;
      _updatingStatus = newStatus; // শুধু এই button এ spinner দেখাবে
    });
    try {
      final complaintId = _complaint['id'].toString();
      final officerId = AuthService.currentUser!.id;

      await supabase
          .from('complaints')
          .update({'status': newStatus}).eq('id', complaintId);

      await NotificationService.addStatusHistory(
        complaintId: complaintId,
        status: newStatus,
        comment: comment.isEmpty ? null : comment,
        updatedBy: officerId,
      );

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

      final admins = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'Admin');
      for (final admin in (admins as List)) {
        await NotificationService.send(
          userId: admin['id'].toString(),
          title: 'Complaint Updated by Officer',
          body: 'Complaint "${_complaint['title']}" status changed to $newStatus.',
          type: 'status_update',
          complaintId: complaintId,
        );
      }

      _commentController.clear();
      // showLoading false — status update এর পরে screen spinner দেখাবে না
      await _loadDetails(showLoading: false);

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
      if (mounted) setState(() {
        _isUpdating = false;
        _updatingStatus = null;
      });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(status, statusColor),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  if (_complaint['image_urls'] != null &&
                      (_complaint['image_urls'] as List?)?.isNotEmpty == true)
                    _buildImagesCard(),
                  if (_complaint['image_urls'] != null &&
                      (_complaint['image_urls'] as List?)?.isNotEmpty == true)
                    const SizedBox(height: 16),
                  if (_citizenProfile != null && widget.viewerRole != 'Citizen')
                    _buildCitizenCard(),
                  if (_citizenProfile != null && widget.viewerRole != 'Citizen')
                    const SizedBox(height: 16),
                  if (_officerProfile != null) _buildOfficerCard(),
                  if (_officerProfile != null) const SizedBox(height: 16),
                  _buildTimeline(),
                  const SizedBox(height: 16),
                  if (widget.viewerRole == 'Officer') _buildStatusUpdatePanel(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

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
          Text('Status: $status',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              Text(createdAt,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, location),
          if (dept.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.business_outlined, dept),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    final raw = _complaint['image_urls'];
    if (raw == null) return const SizedBox.shrink();
    final urls = (raw as List)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
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

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      Container(
                        width: 12,
                        height: 12,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
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
                              Text(hStatus,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const Spacer(),
                              Text(hDate,
                                  style: const TextStyle(
                                      color: Color(0xFF9CA3AF), fontSize: 11)),
                            ],
                          ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((s) {
              final isCurrent = _complaint['status'] == s;
              final color = _statusColor(s);
              final isThisUpdating = _updatingStatus == s;
              return GestureDetector(
                onTap: _isUpdating ? null : () => _updateStatus(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  // শুধু tap করা button এ spinner দেখাবে
                  child: isThisUpdating
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

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13))),
      ],
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
