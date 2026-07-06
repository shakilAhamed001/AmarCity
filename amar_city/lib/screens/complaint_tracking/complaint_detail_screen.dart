import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  Map<String, dynamic>? _feedback;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _updatingStatus;
  final _commentController = TextEditingController();
  bool _feedbackSubmitted = false;
  Uint8List? _afterImageBytes;
  int _upvoteCount = 0;
  bool _hasUpvoted = false;
  bool _isUpvoting = false;

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
  Future<void> _loadUpvotes() async {
    try {
      final complaintId = _complaint['id'].toString();
      final rows = await supabase
          .from('complaint_upvotes')
          .select('user_id')
          .eq('complaint_id', complaintId);
      final list = List<Map<String, dynamic>>.from(rows);
      final uid = AuthService.currentUser?.id;
      if (mounted) {
        setState(() {
          _upvoteCount = list.length;
          _hasUpvoted = uid != null && list.any((r) => r['user_id'] == uid);
        });
      }
    } catch (e) {
      debugPrint('Upvote load error: $e');
    }
  }

  Future<void> _toggleUpvote() async {
    final uid = AuthService.currentUser?.id;
    if (uid == null || _isUpvoting) return;
    // নিজের complaint এ upvote করা যাবে না
    if (_complaint['citizen_id']?.toString() == uid) return;
    setState(() => _isUpvoting = true);
    try {
      final complaintId = _complaint['id'].toString();
      if (_hasUpvoted) {
        await supabase
            .from('complaint_upvotes')
            .delete()
            .eq('complaint_id', complaintId)
            .eq('user_id', uid);
        setState(() {
          _hasUpvoted = false;
          _upvoteCount--;
        });
      } else {
        await supabase.from('complaint_upvotes').insert({
          'complaint_id': complaintId,
          'user_id': uid,
        });
        setState(() {
          _hasUpvoted = true;
          _upvoteCount++;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUpvoting = false);
    }
  }

  Future<void> _loadDetails({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      _history = await NotificationService.fetchStatusHistory(
          _complaint['id'].toString());
      await _loadUpvotes();

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
      floatingActionButton: (widget.viewerRole == 'Citizen' ||
              widget.viewerRole == 'Officer')
          ? FloatingActionButton(
              onPressed: _openChat,
              backgroundColor: const Color(0xFF1E40AF),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 22),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(status, statusColor),
                  const SizedBox(height: 16),
                  _buildUpvoteCard(),
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

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar + header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E40AF),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Complaint Chat',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                _complaint['title'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close,
                              color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chat content
              Expanded(
                child: ChatContent(
                  complaint: _complaint,
                  viewerRole: widget.viewerRole,
                ),
              ),
            ],
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

  Widget _buildUpvoteCard() {
    final uid = AuthService.currentUser?.id;
    final isOwner = _complaint['citizen_id']?.toString() == uid;
    final isResolved = _complaint['status'] == 'Resolved';

    // Admin/Officer এর জন্য শুধু count দেখাবে, upvote button না
    if (widget.viewerRole != 'Citizen') {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF6366F1), size: 20),
            const SizedBox(width: 10),
            Text('$_upvoteCount জন ভুক্তভোগী',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937))),
            const Spacer(),
            if (_upvoteCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor(_upvoteCount).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _priorityLabel(_upvoteCount),
                  style: TextStyle(
                      color: _priorityColor(_upvoteCount),
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      );
    }

    // Citizen এর জন্য upvote button
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 6),
                    Text('$_upvoteCount জন ভুক্তভোগী',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937))),
                    const SizedBox(width: 8),
                    if (_upvoteCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _priorityColor(_upvoteCount).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _priorityLabel(_upvoteCount),
                          style: TextStyle(
                              color: _priorityColor(_upvoteCount),
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (!isOwner && !isResolved)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'আপনিও এই সমস্যায় ভুক্তভোগী হলে জানান',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ),
              ],
            ),
          ),
          if (!isOwner && !isResolved)
            GestureDetector(
              onTap: _isUpvoting ? null : _toggleUpvote,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _hasUpvoted
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                  ),
                ),
                child: _isUpvoting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF6366F1)))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hasUpvoted
                                ? Icons.thumb_up_alt_rounded
                                : Icons.thumb_up_alt_outlined,
                            color: _hasUpvoted ? Colors.white : const Color(0xFF6366F1),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hasUpvoted ? 'ভুক্তভোগী আছি' : 'আমিও ভুক্তভোগী',
                            style: TextStyle(
                                color: _hasUpvoted ? Colors.white : const Color(0xFF6366F1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String _priorityLabel(int count) {
    if (count >= 20) return 'অত্যন্ত জরুরি';
    if (count >= 10) return 'উচ্চ অগ্রাধিকার';
    if (count >= 5)  return 'মধ্যম অগ্রাধিকার';
    return 'সাধারণ';
  }

  Color _priorityColor(int count) {
    if (count >= 20) return const Color(0xFFDC2626);
    if (count >= 10) return const Color(0xFFF59E0B);
    if (count >= 5)  return const Color(0xFF6366F1);
    return const Color(0xFF6B7280);
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
          _locationRow(location),
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

  Widget _locationRow(String location) {
    return GestureDetector(
      onTap: location.isNotEmpty ? () => _showLocationMap(location) : null,
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ),
          if (location.isNotEmpty)
            const Icon(Icons.map_outlined, size: 15, color: Color(0xFF1E40AF)),
        ],
      ),
    );
  }

  void _showLocationMap(String location) {
    // lat,lng format parse করার চেষ্টা
    LatLng center = const LatLng(23.8103, 90.4125);
    bool hasPrecisePin = false;
    final parts = location.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        center = LatLng(lat, lng);
        hasPrecisePin = true;
      }
    }
    final pinLatLng = center;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: hasPrecisePin ? 16 : 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.amarcity.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pinLatLng,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: Color(0xFFDC2626),
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
