import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../complaint_tracking/complaint_detail_screen.dart';

// AdminComplaints — Admin এর complaint management screen
class AdminComplaints extends StatefulWidget {
  const AdminComplaints({Key? key}) : super(key: key);

  @override
  State<AdminComplaints> createState() => _AdminComplaintsState();
}

class _AdminComplaintsState extends State<AdminComplaints> {
  // Status filter — শুরুতে সব complaint দেখাবে
  String _selectedFilter = 'All';
  // Department filter — শুরুতে সব department দেখাবে
  String _selectedDepartment = 'All';
  // Search query — title বা location দিয়ে খোঁজার জন্য
  String _searchQuery = '';
  // Database থেকে আনা সব complaint
  List<Map<String, dynamic>> _allComplaints = [];
  // Database থেকে আনা সব officer
  List<Map<String, dynamic>> _allOfficers = [];
  // Data load হচ্ছে কিনা
  bool _isLoading = true;

  // Available department list
  final List<String> _departments = [
    'All',
    'Engineering Department',
    'Waste Management Department',
    'Public Health & Sanitation Department',
    'Trade License Issuance & Registration Department',
    'Power/Electricity Department',
  ];

  @override
  void initState() {
    super.initState();
    // Screen load হলে complaints ও officers fetch করা হচ্ছে
    _fetchComplaints();
    _fetchOfficers();
  }

  // Supabase থেকে সব complaint fetch করার function — নতুন আগে
  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('complaints')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _allComplaints = (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Supabase profiles table থেকে সরাসরি Officer role filter করে fetch করার function
  // এটি dialog open হওয়ার আগেও call হয় — সবসময় fresh data পাওয়ার জন্য
  Future<void> _fetchOfficers() async {
    try {
      // Database এ role = 'Officer' দিয়ে সরাসরি filter করা হচ্ছে
      // এতে নতুন create করা officer রাও আসবে
      final data = await supabase
          .from('profiles')
          .select()
          .eq('role', 'Officer');
      final officers = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _allOfficers = officers);
    } catch (e) {
      debugPrint('Officers error: $e');
    }
  }

  // Officer assign করার dialog দেখানোর function
  Future<void> _showAssignDialog(Map<String, dynamic> complaint) async {
    // Dialog open হওয়ার আগে সবসময় fresh officer data fetch করা হচ্ছে
    // এতে নতুন create করা officer রাও list এ দেখাবে
    await _fetchOfficers();

    final dept = complaint['assigned_department'] as String? ?? '';

    // Complaint এর department অনুযায়ী officer filter করা হচ্ছে
    // dept match করে এমন + department null/empty এমন officers উভয়ই দেখাবে
    final deptOfficers = dept.isEmpty
        ? _allOfficers
        : _allOfficers.where((o) {
            final oDept = (o['department'] as String? ?? '').trim();
            // department match করলে অথবা officer এর department null/empty হলে দেখাবে
            return oDept == dept.trim() || oDept.isEmpty;
          }).toList();
    String? selectedOfficerId = complaint['assigned_officer_id'] as String?;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign Officer'),
          content: deptOfficers.isEmpty
              ? Text(
                  'No officers found for "$dept"',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                )
              : DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedOfficerId,
                  decoration: const InputDecoration(
                    labelText: 'Select Officer',
                  ),
                  items: deptOfficers.map((o) {
                    final oDept = (o['department'] as String? ?? '').trim();
                    final name = (o['full_name'] ?? o['email'] ?? 'Officer')
                        .toString();
                    // department null হলে label এ জানিয়ে দেওয়া হচ্ছে
                    final label = oDept.isEmpty ? '$name (no dept)' : name;
                    return DropdownMenuItem<String>(
                      value: o['id']?.toString(),
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedOfficerId = val),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (deptOfficers.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                onPressed: () async {
                  if (selectedOfficerId == null) return;
                  try {
                    final complaintId = complaint['id'].toString();
                    final complaintTitle =
                        complaint['title']?.toString() ?? 'Complaint';

                    // Complaint এ officer assign করা হচ্ছে
                    await supabase
                        .from('complaints')
                        .update({'assigned_officer_id': selectedOfficerId})
                        .eq('id', complaint['id']);

                    // Assigned officer কে notification পাঠানো হচ্ছে
                    await NotificationService.send(
                      userId: selectedOfficerId!,
                      title: 'New Complaint Assigned',
                      body: 'You have been assigned: "$complaintTitle".',
                      type: 'assignment',
                      complaintId: complaintId,
                    );

                    // Citizen কেও notification পাঠানো হচ্ছে
                    final citizenId = complaint['citizen_id']?.toString();
                    if (citizenId != null) {
                      await NotificationService.send(
                        userId: citizenId,
                        title: 'Officer Assigned to Your Complaint',
                        body:
                            'An officer has been assigned to "$complaintTitle".',
                        type: 'assignment',
                        complaintId: complaintId,
                      );
                    }

                    // Status history তে entry যোগ করা হচ্ছে
                    await NotificationService.addStatusHistory(
                      complaintId: complaintId,
                      status: complaint['status']?.toString() ?? 'New',
                      comment: 'Officer assigned by Admin.',
                      updatedBy: 'admin',
                    );

                    // Local list update করা হচ্ছে — database call ছাড়াই UI refresh
                    final idx = _allComplaints.indexWhere(
                      (c) => c['id'] == complaint['id'],
                    );
                    if (idx != -1) {
                      setState(
                        () => _allComplaints[idx]['assigned_officer_id'] =
                            selectedOfficerId,
                      );
                    }
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Officer assigned & notified!'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Assign error: $e');
                  }
                },
                child: const Text(
                  'Assign',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Filter ও search অনুযায়ী complaint list return করার getter
  List<Map<String, dynamic>> get _filtered {
    return _allComplaints.where((c) {
      final title = (c['title'] as String? ?? '').toLowerCase();
      final location = (c['location'] as String? ?? '').toLowerCase();
      final status = c['status'] as String? ?? '';
      final dept = c['assigned_department'] as String? ?? '';
      final query = _searchQuery.toLowerCase();
      // Search query match করা হচ্ছে
      final matchSearch = title.contains(query) || location.contains(query);
      // Status filter match করা হচ্ছে
      final matchStatus = _selectedFilter == 'All' || status == _selectedFilter;
      // Department filter match করা হচ্ছে
      final matchDept =
          _selectedDepartment == 'All' || dept == _selectedDepartment;
      return matchSearch && matchStatus && matchDept;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchComplaints,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status filter chips
                    _buildStatusFilters(),
                    const SizedBox(height: 12),
                    // Department dropdown filter
                    _buildDepartmentFilter(),
                    const SizedBox(height: 12),
                    // Search field
                    _buildSearchField(),
                    const SizedBox(height: 16),
                    // Loading, empty বা complaint list দেখানো হচ্ছে
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_allComplaints.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No complaints found in database.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      )
                    else if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No complaints match the filter.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _filtered.map((c) => _buildCard(c)).toList(),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header widget — gradient background, title ও total count
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF2E1065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complaints',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // মোট complaint সংখ্যা dynamically দেখানো হচ্ছে
          Text(
            '${_allComplaints.length} total complaints',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Status filter chips — All, New, In progress, Resolved
  Widget _buildStatusFilters() {
    final filters = ['All', 'New', 'In progress', 'Resolved'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return GestureDetector(
            // Tap করলে filter পরিবর্তন হবে
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // Selected হলে বেগুনি, না হলে সাদা
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Department dropdown filter widget
  Widget _buildDepartmentFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDepartment,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF7C3AED)),
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13),
          items: _departments
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedDepartment = val);
          },
        ),
      ),
    );
  }

  // Search field widget — title বা location দিয়ে খোঁজা যাবে
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search complaint or location...',
          hintStyle: TextStyle(color: Color(0xFFB4B4B4), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // একটি complaint card widget
  Widget _buildCard(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? 'New';
    final statusColor = _statusColor(status);
    final category = c['category'] as String? ?? 'OTHER';
    final title = c['title'] as String? ?? '';
    final location = c['location'] as String? ?? '';
    final dept = c['assigned_department'] as String? ?? '';
    final date = _formatDate(c['created_at'] as String?);
    // Officer assign হয়েছে কিনা check করা হচ্ছে
    final isAssigned = c['assigned_officer_id'] != null;

    // Assigned officer এর নাম খোঁজা হচ্ছে
    final assignedOfficer = isAssigned
        ? _allOfficers.firstWhere(
            (o) => o['id']?.toString() == c['assigned_officer_id']?.toString(),
            orElse: () => {},
          )
        : <String, dynamic>{};
    final officerName = assignedOfficer.isNotEmpty
        ? (assignedOfficer['full_name'] ?? assignedOfficer['email'] ?? '')
              .toString()
        : '';

    return GestureDetector(
      // Tap করলে complaint detail screen এ navigate করবে
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ComplaintDetailScreen(complaint: c, viewerRole: 'Admin'),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _categoryColor(category).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _categoryIcon(category),
                    color: _categoryColor(category),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category label
                          Text(
                            category,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Complaint title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ),
                // Submit date
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            // Department badge — department থাকলে দেখাবে
            if (dept.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dept,
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Officer নাম বা 'Unassigned' দেখানো হচ্ছে
                if (officerName.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            officerName,
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'Unassigned',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                // Assign বা Reassign button
                GestureDetector(
                  onTap: () => _showAssignDialog(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      // Assigned হলে সবুজ, না হলে বেগুনি background
                      color: isAssigned
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAssigned ? 'Reassign >' : 'Assign >',
                      style: TextStyle(
                        color: isAssigned
                            ? const Color(0xFF059669)
                            : const Color(0xFF7C3AED),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  // ISO date string কে 'Jan 5' format এ convert করার helper
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
    return '${m[dt.month - 1]} ${dt.day}';
  }
}
