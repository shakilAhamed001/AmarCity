import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../citizen/feedback_screen.dart';
import 'complaint_report_screen.dart';
import 'chat_screen.dart';

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
  Map<String, dynamic>? _feedback; // Admin/Officer এর জন্য feedback data
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _updatingStatus;
  final _commentController = TextEditingController();
  bool _feedbackSubmitted = false;
  Uint8List? _afterImageBytes;

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

  Future<void> _pickAfterImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 80);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => _afterImageBytes = bytes);
    }
  }

  Future<String?> _uploadAfterImage(String complaintId) async {
    if (_afterImageBytes == null) return null;
    final fileName = 'after_${complaintId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('complaint-images').uploadBinary(
      fileName,
      _afterImageBytes!,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return supabase.storage.from('complaint-images').getPublicUrl(fileName);
  }

  // showLoading false হলে spinner দেখাবে না — status update এর পরে reload এর জন্য
  Future<void> _loadDetails({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      _history = await NotificationService.fetchStatusHistory(
          _complaint['id'].toString());

      // Citizen হলে আগে feedback দেওয়া হয়েছে কিনা check করা
      if (widget.viewerRole == 'Citizen') {
        final fb = await supabase
            .from('complaint_feedback')
            .select()
            .eq('complaint_id', _complaint['id'].toString())
            .eq('citizen_id', AuthService.currentUser!.id)
            .maybeSingle();
        _feedbackSubmitted = fb != null;
      }

      // Admin ও Officer এর জন্য feedback data load করা
      if (widget.viewerRole == 'Admin' || widget.viewerRole == 'Officer') {
        final fb = await supabase
            .from('complaint_feedback')
            .select()
            .eq('complaint_id', _complaint['id'].toString())
            .maybeSingle();
        _feedback = fb != null ? Map<String, dynamic>.from(fb) : null;
      }

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

      // Resolved হলে after photo upload করা হবে
      String? afterUrl;
      if (newStatus == 'Resolved') {
        afterUrl = await _uploadAfterImage(complaintId);
      }

      final updateData = <String, dynamic>{'status': newStatus};
      if (afterUrl != null) updateData['after_image_url'] = afterUrl;
      await supabase.from('complaints').update(updateData).eq('id', complaintId);

      await NotificationService.addStatusHistory(
        complaintId: complaintId,
        status: newStatus,
        comment: comment.isEmpty ? null : comment,
        updatedBy: officerId,
      );

      final citizenId = _complaint['citizen_id']?.toString();
      if (citizenId != null) {
        final statusMsg = newStatus == 'Resolved'
            ? 'Your complaint "${_complaint['title']}" has been resolved! ✅'
            : newStatus == 'In progress'
                ? 'Your complaint "${_complaint['title']}" is now being worked on. 🔧'
                : 'Your complaint "${_complaint['title']}" status changed to $newStatus.';
        await NotificationService.send(
          userId: citizenId,
          title: 'Complaint Status Updated',
          body: statusMsg,
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
                  if (widget.viewerRole == 'Admin') _buildViewReportButton(),
                  if (widget.viewerRole == 'Citizen' ||
                      widget.viewerRole == 'Officer')
                    _buildChatButton(),
                  if (_complaint['image_urls'] != null ||
                      _complaint['after_image_url'] != null)
                    const SizedBox(height: 16),
                  if (_complaint['image_urls'] != null ||
                      _complaint['after_image_url'] != null)
                    _buildBeforeAfterCard(),
                  if (widget.viewerRole == 'Citizen' &&
                      _complaint['status'] == 'Resolved')
                    _buildFeedbackButton(),
                  if ((widget.viewerRole == 'Admin' ||
                          widget.viewerRole == 'Officer') &&
                      _feedback != null) ...[
                    const SizedBox(height: 16),
                    _buildFeedbackCard(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildBeforeAfterCard() {
    final raw = _complaint['image_urls'];
    final beforeUrls = raw == null
        ? <String>[]
        : (raw as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final afterUrl = _complaint['after_image_url'] as String?;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Before & After',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Before
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('BEFORE',
                          style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    if (beforeUrls.isEmpty)
                      _photoPlaceholder()
                    else
                      GestureDetector(
                        onTap: () => _showFullImage(beforeUrls.first),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            beforeUrls.first,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _photoPlaceholder(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // After
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('AFTER',
                          style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    if (afterUrl == null || afterUrl.isEmpty)
                      _photoPlaceholder(pending: true)
                    else
                      GestureDetector(
                        onTap: () => _showFullImage(afterUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            afterUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _photoPlaceholder(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder({bool pending = false}) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pending ? Icons.hourglass_empty_rounded : Icons.image_outlined,
            color: const Color(0xFF9CA3AF),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            pending ? 'Pending' : 'No photo',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatScreen(
              complaint: _complaint,
              viewerRole: widget.viewerRole,
            ),
          )),
          icon: const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 18),
          label: const Text('Open Chat',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildViewReportButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                ComplaintReportScreen(complaint: _complaint),
          )),
          icon: const Icon(Icons.assessment_outlined,
              color: Color(0xFF1E40AF), size: 18),
          label: const Text('View Full Report',
              style: TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1E40AF)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
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
          // After photo picker — Resolved select করলে দেখাবে
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _complaint['status'] != 'Resolved'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AFTER PHOTO (optional)',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickAfterImage,
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF059669).withOpacity(0.4),
                                style: BorderStyle.solid),
                          ),
                          child: _afterImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(_afterImageBytes!,
                                          fit: BoxFit.cover),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _afterImageBytes = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                                color: Color(0xFFDC2626),
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: Color(0xFF059669), size: 28),
                                    SizedBox(height: 6),
                                    Text('Add after photo',
                                        style: TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
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

  // Feedback button — Citizen + Resolved complaint এ দেখাবে
  Widget _buildFeedbackButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _feedbackSubmitted
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Text('Feedback Submitted',
                      style: TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          FeedbackScreen(complaint: _complaint),
                    ),
                  );
                  // feedback submit হলে state update করা
                  if (result == true && mounted) {
                    setState(() => _feedbackSubmitted = true);
                  }
                },
                icon: const Icon(Icons.star_outline_rounded,
                    color: Colors.white, size: 20),
                label: const Text('Rate & Give Feedback',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
    );
  }

  // Feedback card — Admin ও Officer এর জন্য citizen এর দেওয়া rating দেখাবে
  Widget _buildFeedbackCard() {
    final rating = _feedback!['rating'] as int? ?? 0;
    final comment = _feedback!['comment'] as String? ?? '';
    final date = _formatDate(_feedback!['created_at'] as String?);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 6),
              const Text('Citizen Feedback',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1F2937))),
              const Spacer(),
              Text(date,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          // Star row
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return Icon(
                star <= rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 28,
                color: star <= rating
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFD1D5DB),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _ratingLabel(rating),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ratingColor(rating)),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(comment,
                  style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Very Dissatisfied 😞';
      case 2: return 'Dissatisfied 😕';
      case 3: return 'Neutral 😐';
      case 4: return 'Satisfied 😊';
      case 5: return 'Very Satisfied 🎉';
      default: return '';
    }
  }

  Color _ratingColor(int rating) {
    if (rating <= 2) return const Color(0xFFDC2626);
    if (rating == 3) return const Color(0xFFF59E0B);
    return const Color(0xFF059669);
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
