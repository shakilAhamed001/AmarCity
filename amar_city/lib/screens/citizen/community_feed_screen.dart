import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../complaint_tracking/complaint_detail_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<Map<String, dynamic>> _complaints = [];
  // current user যেসব complaint এ upvote করেছে
  Set<String> _upvotedIds = {};
  // upvoting in progress এর complaint ids
  Set<String> _upvotingIds = {};
  bool _isLoading = true;
  String _selectedCategory = 'All';

  static const _categories = [
    'All', 'ROAD', 'LIGHTING', 'GARBAGE', 'DRAINAGE', 'WATER', 'ELECTRICITY',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final uid = AuthService.currentUser!.id;

      // সব complaint আনা হচ্ছে — নিজেরটা বাদে, upvote count সহ
      final data = await supabase
          .from('complaints')
          .select('*, complaint_upvotes(user_id)')
          .neq('citizen_id', uid)
          .neq('status', 'Resolved')
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);

      // current user কোন কোন complaint এ upvote করেছে
      final upvoted = <String>{};
      for (final c in list) {
        final votes = c['complaint_upvotes'] as List? ?? [];
        if (votes.any((v) => v['user_id'] == uid)) {
          upvoted.add(c['id'].toString());
        }
      }

      // upvote count অনুযায়ী sort — বেশি vote আগে
      list.sort((a, b) {
        final aCount = (a['complaint_upvotes'] as List? ?? []).length;
        final bCount = (b['complaint_upvotes'] as List? ?? []).length;
        return bCount.compareTo(aCount);
      });

      if (mounted) {
        setState(() {
          _complaints = list;
          _upvotedIds = upvoted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUpvote(String complaintId) async {
    if (_upvotingIds.contains(complaintId)) return;
    final uid = AuthService.currentUser!.id;
    setState(() => _upvotingIds.add(complaintId));

    try {
      final hasVoted = _upvotedIds.contains(complaintId);
      if (hasVoted) {
        await supabase
            .from('complaint_upvotes')
            .delete()
            .eq('complaint_id', complaintId)
            .eq('user_id', uid);
        setState(() {
          _upvotedIds.remove(complaintId);
          // local count update
          final idx = _complaints.indexWhere((c) => c['id'].toString() == complaintId);
          if (idx != -1) {
            final votes = List.from(_complaints[idx]['complaint_upvotes'] as List? ?? []);
            votes.removeWhere((v) => v['user_id'] == uid);
            _complaints[idx] = {..._complaints[idx], 'complaint_upvotes': votes};
          }
        });
      } else {
        await supabase.from('complaint_upvotes').insert({
          'complaint_id': complaintId,
          'user_id': uid,
        });
        setState(() {
          _upvotedIds.add(complaintId);
          final idx = _complaints.indexWhere((c) => c['id'].toString() == complaintId);
          if (idx != -1) {
            final votes = List.from(_complaints[idx]['complaint_upvotes'] as List? ?? []);
            votes.add({'user_id': uid});
            _complaints[idx] = {..._complaints[idx], 'complaint_upvotes': votes};
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _upvotingIds.remove(complaintId));
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedCategory == 'All') return _complaints;
    return _complaints
        .where((c) => c['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'কোনো complaint পাওয়া যায়নি',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Community Feed',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_complaints.length}টি সমস্যা রিপোর্ট হয়েছে',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat == 'All' ? 'সব' : cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final complaintId = c['id'].toString();
    final votes = c['complaint_upvotes'] as List? ?? [];
    final voteCount = votes.length;
    final hasVoted = _upvotedIds.contains(complaintId);
    final isUpvoting = _upvotingIds.contains(complaintId);
    final status = c['status'] as String? ?? 'New';
    final category = c['category'] as String? ?? 'OTHER';
    final title = c['title'] as String? ?? '';
    final location = c['location'] as String? ?? '';
    final date = _formatDate(c['created_at'] as String?);
    final statusColor = _statusColor(status);
    final catColor = _categoryColor(category);

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (_) =>
                ComplaintDetailScreen(complaint: c, viewerRole: 'Citizen'),
          ))
          .then((_) => _fetchData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasVoted
                ? const Color(0xFF6366F1).withOpacity(0.4)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row — category + status
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_categoryIcon(category),
                            size: 11, color: catColor),
                        const SizedBox(width: 4),
                        Text(category,
                            style: TextStyle(
                                color: catColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 6),

              // Location + date
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(location,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                  ),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom row — priority badge + upvote button
              Row(
                children: [
                  if (voteCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _priorityColor(voteCount).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 12,
                              color: _priorityColor(voteCount)),
                          const SizedBox(width: 4),
                          Text(
                            _priorityLabel(voteCount),
                            style: TextStyle(
                                color: _priorityColor(voteCount),
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),

                  // Upvote button
                  GestureDetector(
                    onTap: () => _toggleUpvote(complaintId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasVoted
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                        ),
                      ),
                      child: isUpvoting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6366F1)))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasVoted
                                      ? Icons.thumb_up_alt_rounded
                                      : Icons.thumb_up_alt_outlined,
                                  size: 14,
                                  color: hasVoted
                                      ? Colors.white
                                      : const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hasVoted
                                      ? 'ভুক্তভোগী আছি ($voteCount)'
                                      : 'আমিও ভুক্তভোগী${voteCount > 0 ? ' ($voteCount)' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasVoted
                                        ? Colors.white
                                        : const Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(int count) {
    if (count >= 20) return 'অত্যন্ত জরুরি';
    if (count >= 10) return 'উচ্চ অগ্রাধিকার';
    if (count >= 5) return 'মধ্যম অগ্রাধিকার';
    return '$count জন ভুক্তভোগী';
  }

  Color _priorityColor(int count) {
    if (count >= 20) return const Color(0xFFDC2626);
    if (count >= 10) return const Color(0xFFF59E0B);
    if (count >= 5) return const Color(0xFF6366F1);
    return const Color(0xFF6B7280);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In progress': return const Color(0xFFF59E0B);
      case 'Resolved':    return const Color(0xFF059669);
      case 'Escalated':   return const Color(0xFFDC2626);
      default:            return const Color(0xFF3B82F6);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ROAD':        return Icons.warning_amber;
      case 'LIGHTING':    return Icons.lightbulb_outline;
      case 'GARBAGE':     return Icons.delete_outline;
      case 'DRAINAGE':
      case 'WATER':       return Icons.water_drop_outlined;
      case 'ELECTRICITY': return Icons.electric_bolt_outlined;
      default:            return Icons.report_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'ROAD':
      case 'LIGHTING':    return const Color(0xFFFCD34D);
      case 'GARBAGE':     return const Color(0xFF6B7280);
      case 'DRAINAGE':    return const Color(0xFF3B82F6);
      case 'WATER':       return const Color(0xFF60A5FA);
      case 'ELECTRICITY': return const Color(0xFFF97316);
      default:            return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }
}
