import 'package:flutter/material.dart';
import 'department_report_screen.dart';

class ExportReportScreen extends StatelessWidget {
  const ExportReportScreen({Key? key}) : super(key: key);

  static const List<Map<String, dynamic>> _departments = [
    {
      'name': 'Engineering Department',
      'icon': Icons.engineering_outlined,
      'color': Color(0xFF3B82F6),
    },
    {
      'name': 'Waste Management Department',
      'icon': Icons.delete_outline,
      'color': Color(0xFF6B7280),
    },
    {
      'name': 'Public Health & Sanitation Department',
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF60A5FA),
    },
    {
      'name': 'Trade License Issuance & Registration Department',
      'icon': Icons.description_outlined,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Power/Electricity Department',
      'icon': Icons.electric_bolt_outlined,
      'color': Color(0xFFF97316),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
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
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Export Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Select a department to view details & export PDF',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Department cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _departments.length,
              itemBuilder: (context, i) {
                final dept = _departments[i];
                final color = dept['color'] as Color;
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DepartmentReportScreen(
                        department: dept['name'] as String),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(dept['icon'] as IconData,
                              color: color, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(dept['name'] as String,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937))),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
