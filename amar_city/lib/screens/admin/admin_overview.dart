// Flutter এর material design widgets ব্যবহারের জন্য import
import 'package:flutter/material.dart';
// Supabase database connection এর জন্য import
import '../../services/supabase_service.dart';

// AdminOverview একটি StatefulWidget — কারণ এখানে database থেকে data load হয় এবং UI update হয়
class AdminOverview extends StatefulWidget {
  const AdminOverview({Key? key}) : super(key: key);

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  // Citizen, Officer, Admin এর সংখ্যা রাখার জন্য variable — শুরুতে 0
  int _citizenCount = 0;
  int _officerCount = 0;
  int _adminCount = 0;

  // Data load হচ্ছে কিনা তা track করার জন্য — শুরুতে true মানে loading চলছে
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    // Widget তৈরি হওয়ার সাথে সাথে database থেকে user count আনা শুরু হয়
    _fetchUserCounts();
  }

  // Supabase database থেকে প্রতিটি role এর user সংখ্যা fetch করার function
  Future<void> _fetchUserCounts() async {
    try {
      // 'profiles' table থেকে শুধু 'role' column এর data আনা হচ্ছে
      final data = await supabase.from('profiles').select('role');

      // Supabase থেকে আসা raw data কে Dart এর Map list এ convert করা হচ্ছে
      // Flutter web এ JS interop এর কারণে explicit casting দরকার হয়
      final users = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // UI update করা হচ্ছে নতুন count দিয়ে
      setState(() {
        // role == 'Citizen' এমন user গুলো filter করে count নেওয়া হচ্ছে
        _citizenCount =
            users.where((u) => u['role']?.toString() == 'Citizen').length;
        // role == 'Officer' এমন user গুলো filter করে count নেওয়া হচ্ছে
        _officerCount =
            users.where((u) => u['role']?.toString() == 'Officer').length;
        // role == 'Admin' এমন user গুলো filter করে count নেওয়া হচ্ছে
        _adminCount =
            users.where((u) => u['role']?.toString() == 'Admin').length;
        // Data load শেষ, loading indicator বন্ধ করা হচ্ছে
        _loadingUsers = false;
      });
    } catch (e) {
      // কোনো error হলে শুধু loading বন্ধ করা হয়, error দেখানো হয় না
      setState(() => _loadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // পুরো page scroll করা যাবে
    return SingleChildScrollView(
      child: Column(
        children: [
          // উপরের gradient header section
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ৪টি stat card এর grid (Complaints, Resolved, Pending, Users)
                _buildStatsGrid(),
                const SizedBox(height: 32),
                // সাপ্তাহিক bar chart
                _buildWeeklyChart(),
                const SizedBox(height: 32),
                // যেসব complaint এখনো assign হয়নি সেগুলোর list
                _buildUnassignedComplaints(),
                const SizedBox(height: 32),
                // Citizen, Officer, Admin এর dynamic count section
                _buildUserOverview(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // উপরের header widget — gradient background সহ admin info দেখায়
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        // বেগুনি gradient background
        gradient: LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF2E1065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // শুধু নিচের দুই কোণ গোলাকার
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // সময় দেখানো হচ্ছে
                  const Text(
                    '6:49',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 'ADMIN PANEL' badge/label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B21A8).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFA78BFA),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'ADMIN PANEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              // ডান পাশে notification icon
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Admin কে greeting message
          const Text(
            'Good morning, Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // তারিখ দেখানো হচ্ছে
          const Text(
            'Monday, June 14, 2023',
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

  // ৪টি stat card একসাথে grid layout এ দেখানোর widget
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4, // এক সারিতে ৪টি card
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true, // Column এর ভেতরে থাকায় নিজের height নিজে নেবে
      physics: const NeverScrollableScrollPhysics(), // এই grid নিজে scroll করবে না
      childAspectRatio: 0.9,
      children: [
        // প্রতিটি card এ value, label এবং color দেওয়া হচ্ছে
        _buildStatCard('248', 'Complaints', const Color(0xFF7C3AED)),
        _buildStatCard('87%', 'Resolved', const Color(0xFF10B981)),
        _buildStatCard('32', 'Pending', const Color(0xFFF59E0B)),
        _buildStatCard('8', 'Users', const Color(0xFF3B82F6)),
      ],
    );
  }

  // একটি stat card widget — value, label এবং color নিয়ে তৈরি হয়
  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // হালকা shadow দেওয়া হচ্ছে card কে উঁচু দেখাতে
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // বড় সংখ্যা বা value
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // ছোট label text
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // সাপ্তাহিক complaint এর bar chart widget
  Widget _buildWeeklyChart() {
    // সপ্তাহের দিনগুলোর নাম
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // প্রতিদিনের complaint এর সংখ্যা (static data)
    const values = [40, 35, 60, 50, 75, 55, 45];
    // সবচেয়ে বড় value বের করা হচ্ছে — bar এর height calculate করতে
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Overview',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              // প্রতিটি দিনের জন্য একটি bar তৈরি হচ্ছে
              children: List.generate(
                days.length,
                (index) => Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bar এর height = (ওই দিনের value / সর্বোচ্চ value) * 120
                    // এতে সব bar proportionally দেখায়
                    Container(
                      width: 32,
                      height: (values[index] / maxValue) * 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        // শুধু উপরের দুই কোণ গোলাকার
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bar এর নিচে দিনের নাম
                    Text(
                      days[index],
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // যেসব complaint এখনো কোনো officer কে assign করা হয়নি সেগুলো দেখানোর widget
  Widget _buildUnassignedComplaints() {
    // Static complaint data — পরে database থেকে আনা যাবে
    final complaints = [
      {
        'icon': Icons.construction,
        'title': 'Cave-in near School — Road 3',
        'location': 'Road 2h ago · by Rahim Ahmed',
        'category': 'Road',
      },
      {
        'icon': Icons.water_drop,
        'title': 'Drain overflow — Street 7',
        'location': 'Drainage 3h ago · by Sabikr Hasan',
        'category': 'Drainage',
      },
      {
        'icon': Icons.route,
        'title': 'Pothole — Avenue 4',
        'location': 'Road 3h ago · by Sabiur Hasan',
        'category': 'Road',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unassigned complaints',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 'See all' button — পরে সব complaint এর page এ navigate করবে
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See all >',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // complaints list এর প্রতিটি item কে card হিসেবে দেখানো হচ্ছে
        Column(
          children: complaints.map((complaint) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // বাম পাশে complaint এর category icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      complaint['icon'] as IconData,
                      color: const Color(0xFFD97706),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // মাঝে complaint এর title ও location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint['title'] as String,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint['location'] as String,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ডান পাশে 'Assign' button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Assign >',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // User Overview section — database থেকে আনা dynamic count দেখায়
  Widget _buildUserOverview() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User overview',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 'Manage' button — user management page এ যাবে
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Manage >',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Data load হচ্ছে কিনা check করা হচ্ছে
          // যদি loading চলে তাহলে spinner, না হলে count দেখাবে
          _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Database থেকে আনা dynamic count দেখানো হচ্ছে
                    _buildUserCount('$_citizenCount', 'Citizens'),
                    _buildUserCount('$_officerCount', 'Officers'),
                    _buildUserCount('$_adminCount', 'Admins'),
                  ],
                ),
        ],
      ),
    );
  }

  // একটি user count item — সংখ্যা এবং label দেখায়
  Widget _buildUserCount(String count, String label) {
    return Column(
      children: [
        // বড় সংখ্যা — বেগুনি রঙে
        Text(
          count,
          style: const TextStyle(
            color: Color(0xFF7C3AED),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // নিচে ছোট label (Citizens / Officers / Admins)
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
