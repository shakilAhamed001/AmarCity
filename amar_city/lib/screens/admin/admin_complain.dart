// Flutter material design import
import 'package:flutter/material.dart';
// Supabase client ব্যবহারের জন্য
import 'package:supabase_flutter/supabase_flutter.dart';

// AdminComplaints — Admin এর complaint management screen
class AdminComplaints extends StatefulWidget {
  const AdminComplaints({Key? key}) : super(key: key);

  @override
  State<AdminComplaints> createState() => _AdminComplaintsState();
}

class _AdminComplaintsState extends State<AdminComplaints> {
  // বর্তমানে কোন filter selected — শুরুতে 'All (52)'
  String _selectedFilter = 'All (52)';
  // Search field এ কী লেখা আছে
  String _searchQuery = '';
  // Database থেকে আনা officer list — assign dialog এ দেখানো হবে
  List<Map<String, dynamic>> _allOfficers = [];

  // Static complaint data — পরে database থেকে আনা যাবে
  final List<Map<String, dynamic>> _allComplaints = [
    {
      'id': 'EAC-3891',
      'icon': Icons.construction,
      'iconColor': const Color(0xFFFCD34D),
      'title': 'Cave-in near School — Road 3',
      'location': 'Motijheel, Dhaka',
      'reporter': 'Rahim Ahmed',
      'priority': 'High',
      'priorityColor': const Color(0xFFEF4444),
      'status': 'New',
      'statusColor': const Color(0xFF7C3AED),
      'timeAgo': '2h ago',
    },
    {
      'id': 'EAC-3889',
      'icon': Icons.water_drop,
      'iconColor': const Color(0xFF3B82F6),
      'title': 'Water main burst — Block C',
      'location': 'Gulshan, Dhaka',
      'reporter': 'Karim Hossain',
      'priority': 'High',
      'priorityColor': const Color(0xFFEF4444),
      'status': 'Escalated',
      'statusColor': const Color(0xFFEF4444),
      'timeAgo': '3h ago',
    },
    {
      'id': 'EAC-3888',
      'icon': Icons.delete_outline,
      'iconColor': const Color(0xFF6B7280),
      'title': 'Drain overflow — Street 7',
      'location': 'Dhanmondi, Dhaka',
      'reporter': 'Sabikr Hasan',
      'priority': 'High',
      'priorityColor': const Color(0xFFEF4444),
      'status': 'New',
      'statusColor': const Color(0xFF7C3AED),
      'timeAgo': '4h ago',
    },
    {
      'id': 'EAC-3884',
      'icon': Icons.lightbulb_outline,
      'iconColor': const Color(0xFFFCD34D),
      'title': 'Street lights not working',
      'location': 'Banani, Dhaka',
      'reporter': 'Fatima Ahmed',
      'priority': 'Medium',
      'priorityColor': const Color(0xFFF59E0B),
      'status': 'In progress',
      'statusColor': const Color(0xFF3B82F6),
      'timeAgo': '4h ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Screen load হলে officer list fetch করা হচ্ছে
    _fetchOfficers();
  }

  // Supabase থেকে সব officer fetch করার function
  Future<void> _fetchOfficers() async {
    try {
      final supabase = Supabase.instance.client;
      // profiles table থেকে শুধু Officer role এর user আনা হচ্ছে
      final data = await supabase
          .from('profiles')
          .select()
          .eq('role', 'officer');
      setState(() {
        _allOfficers = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error fetching officers: $e');
    }
  }

  // Complaint এ officer assign করার dialog দেখানোর function
  Future<void> _assignOfficerDialog(Map<String, dynamic> complaint) async {
    String? selectedOfficerId;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Officer'),
          content: SizedBox(
            width: 300,
            // Officer list থেকে dropdown এ select করা যাবে
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedOfficerId,
              items: _allOfficers.map((officer) {
                return DropdownMenuItem<String>(
                  value: officer['id'],
                  child: Text(
                    // full_name না থাকলে email দেখাবে
                    officer['full_name'] ?? officer['email'] ?? 'Officer',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                selectedOfficerId = val;
              },
              decoration: const InputDecoration(labelText: 'Select Officer'),
            ),
          ),
          actions: [
            // Cancel button — dialog বন্ধ করবে
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            // Assign button — database update করবে
            ElevatedButton(
              onPressed: () async {
                if (selectedOfficerId != null) {
                  try {
                    final supabase = Supabase.instance.client;
                    // complaints table এ assigned_officer_id update করা হচ্ছে
                    await supabase
                        .from('complaints')
                        .update({'assigned_officer_id': selectedOfficerId})
                        .eq('id', complaint['id']);
                    setState(() {
                      complaint['assigned_officer_id'] = selectedOfficerId;
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Officer assigned successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error assigning officer: $e');
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // উপরের gradient header
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter chips — All, Unassigned, New, In progress
                _buildFilters(),
                const SizedBox(height: 20),
                // Search field
                _buildSearchField(),
                const SizedBox(height: 20),
                // Complaint card list
                _buildComplaintsList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header widget — gradient background সহ
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              // Notification icon
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // সময় দেখানো হচ্ছে
          const Text(
            '8:50',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          // Page title
          const Text(
            'Complaints',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'View all reported issues',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Filter chips — horizontally scrollable
  Widget _buildFilters() {
    final filters = ['All (52)', 'Unassigned (4)', 'New', 'In progress'];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == filters[index];
          return GestureDetector(
            // tap করলে filter পরিবর্তন হবে
            onTap: () {
              setState(() {
                _selectedFilter = filters[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // selected হলে বেগুনি background
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Search field widget
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        // টাইপ করলে search query update হবে
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search complaint or location...',
          hintStyle: const TextStyle(
            color: Color(0xFFB4B4B4),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Complaint list — search query দিয়ে filter করা হচ্ছে
  Widget _buildComplaintsList() {
    // title বা location এ search query আছে কিনা check করে filter
    List<Map<String, dynamic>> filteredComplaints = _allComplaints.where((
      complaint,
    ) {
      final title = complaint['title'].toString().toLowerCase();
      final location = complaint['location'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || location.contains(query);
    }).toList();

    return Column(
      children: filteredComplaints.map((complaint) {
        return GestureDetector(
          onTap: () {
            // complaint tap করলে ID দেখানো হচ্ছে
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Viewing ${complaint['id']}')),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Category icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (complaint['iconColor'] as Color).withOpacity(
                          0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        complaint['icon'],
                        color: complaint['iconColor'],
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
                              // Complaint ID
                              Expanded(
                                child: Text(
                                  complaint['id'],
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (complaint['statusColor'] as Color)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  complaint['status'],
                                  style: TextStyle(
                                    color: complaint['statusColor'],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Complaint title
                          Text(
                            complaint['title'],
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 56),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location
                          Text(
                            complaint['location'],
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Reporter name
                          Text(
                            'Reporter: ${complaint['reporter']}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 56),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (complaint['priorityColor'] as Color)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint['priority'],
                        style: TextStyle(
                          color: complaint['priorityColor'],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // কতক্ষণ আগে submit হয়েছে
                    Text(
                      complaint['timeAgo'],
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    // Officer assign করার button
                    GestureDetector(
                      onTap: () => _assignOfficerDialog(complaint),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Assign officer >',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
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
      }).toList(),
    );
  }
}
