import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

// FeedbackScreen — Resolved complaint এ citizen এর feedback দেওয়ার screen
class FeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const FeedbackScreen({Key? key, required this.complaint}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0; // 1–5 star rating
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _alreadySubmitted = false;
  Map<String, dynamic>? _existingFeedback;

  @override
  void initState() {
    super.initState();
    _loadExistingFeedback();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // আগে feedback দেওয়া আছে কিনা check করা
  Future<void> _loadExistingFeedback() async {
    try {
      final data = await supabase
          .from('complaint_feedback')
          .select()
          .eq('complaint_id', widget.complaint['id'].toString())
          .eq('citizen_id', AuthService.currentUser!.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _existingFeedback = Map<String, dynamic>.from(data);
          _rating = data['rating'] as int? ?? 0;
          _commentController.text = data['comment'] as String? ?? '';
          _alreadySubmitted = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await supabase.from('complaint_feedback').upsert({
        'complaint_id': widget.complaint['id'].toString(),
        'citizen_id': AuthService.currentUser!.id,
        'rating': _rating,
        'comment': _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      }, onConflict: 'complaint_id,citizen_id');

      // Assigned officer কে notification পাঠানো
      final officerId = widget.complaint['assigned_officer_id']?.toString();
      if (officerId != null && officerId.isNotEmpty) {
        final stars = '⭐' * _rating;
        final title = widget.complaint['title'] as String? ?? 'Complaint';
        await NotificationService.send(
          userId: officerId,
          title: 'New Feedback Received',
          body: 'Citizen rated "$title" $stars ($_rating/5).',
          type: 'feedback',
          complaintId: widget.complaint['id'].toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted! Thank you.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.complaint['title'] as String? ?? 'Complaint';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text('Rate & Feedback',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Resolved banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF059669), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Complaint Resolved!',
                            style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(title,
                            style: const TextStyle(
                                color: Color(0xFF4B5563), fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Feedback card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('How satisfied are you?',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 6),
                  const Text('Your feedback helps us improve city services.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // Star rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: _alreadySubmitted
                            ? null
                            : () => setState(() => _rating = star),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: star <= _rating
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  // Rating label
                  if (_rating > 0)
                    Text(
                      _ratingLabel(_rating),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ratingColor(_rating)),
                    ),
                  const SizedBox(height: 24),

                  // Comment field
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    readOnly: _alreadySubmitted,
                    decoration: InputDecoration(
                      hintText: 'Share your experience (optional)...',
                      hintStyle: const TextStyle(
                          color: Color(0xFFB4B4B4), fontSize: 13),
                      filled: true,
                      fillColor: _alreadySubmitted
                          ? const Color(0xFFF9FAFB)
                          : Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF1E40AF), width: 1.5)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button বা already submitted message
                  if (_alreadySubmitted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle,
                            color: Color(0xFF059669), size: 18),
                        SizedBox(width: 6),
                        Text('Feedback already submitted',
                            style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Submit Feedback',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
}
