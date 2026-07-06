import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/supabase_service.dart';

class DepartmentReportScreen extends StatefulWidget {
  final String department;
  const DepartmentReportScreen({Key? key, required this.department})
    : super(key: key);

  @override
  State<DepartmentReportScreen> createState() => _DepartmentReportScreenState();
}

class _DepartmentReportScreenState extends State<DepartmentReportScreen> {
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _officers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final complaints = await supabase
          .from('complaints')
          .select()
          .eq('assigned_department', widget.department)
          .order('created_at', ascending: false);

      final officers = await supabase
          .from('profiles')
          .select()
          .eq('role', 'Officer')
          .eq('department', widget.department);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(complaints);
        _officers = List<Map<String, dynamic>>.from(officers);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // একটি officer এর assigned complaints গুলো return করে
  List<Map<String, dynamic>> _complaintsForOfficer(String officerId) =>
      _complaints
          .where((c) => c['assigned_officer_id']?.toString() == officerId)
          .toList();

  int get _newCount => _complaints.where((c) => c['status'] == 'New').length;
  int get _inProgressCount =>
      _complaints.where((c) => c['status'] == 'In progress').length;
  int get _resolvedCount =>
      _complaints.where((c) => c['status'] == 'Resolved').length;
  int get _unassignedCount =>
      _complaints.where((c) => c['assigned_officer_id'] == null).length;

  // PDF generate করার function
  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) => [
          // Title
          pw.Text(
            'Department Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            widget.department,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.purple700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated: ${_formatDate(DateTime.now().toIso8601String())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Divider(height: 24),

          // Summary stats
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _pdfStatBox('Total', '${_complaints.length}', PdfColors.blue700),
              pw.SizedBox(width: 8),
              _pdfStatBox('New', '$_newCount', PdfColors.blue400),
              pw.SizedBox(width: 8),
              _pdfStatBox(
                'In Progress',
                '$_inProgressCount',
                PdfColors.amber700,
              ),
              pw.SizedBox(width: 8),
              _pdfStatBox('Resolved', '$_resolvedCount', PdfColors.green700),
              pw.SizedBox(width: 8),
              _pdfStatBox('Unassigned', '$_unassignedCount', PdfColors.red400),
            ],
          ),
          pw.SizedBox(height: 16),

          // Officers section
          pw.Text(
            'Officers (${_officers.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (_officers.isEmpty)
            pw.Text(
              'No officers assigned to this department.',
              style: const pw.TextStyle(color: PdfColors.grey600),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Name', bold: true),
                    _pdfCell('Email', bold: true),
                    _pdfCell('Assigned', bold: true),
                  ],
                ),
                ..._officers.map((o) {
                  final name =
                      o['full_name'] as String? ?? o['email'] as String? ?? '-';
                  final email = o['email'] as String? ?? '-';
                  final count = _complaintsForOfficer(
                    o['id'].toString(),
                  ).length;
                  return pw.TableRow(
                    children: [
                      _pdfCell(name),
                      _pdfCell(email),
                      _pdfCell('$count'),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // Complaints section
          pw.Text(
            'Complaints (${_complaints.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (_complaints.isEmpty)
            pw.Text(
              'No complaints found.',
              style: const pw.TextStyle(color: PdfColors.grey600),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Title', bold: true),
                    _pdfCell('Status', bold: true),
                    _pdfCell('Officer', bold: true),
                    _pdfCell('Date', bold: true),
                  ],
                ),
                ..._complaints.map((c) {
                  final title = c['title'] as String? ?? '-';
                  final status = c['status'] as String? ?? '-';
                  final officerId = c['assigned_officer_id']?.toString();
                  final officer = officerId != null
                      ? _officers.firstWhere(
                          (o) => o['id'].toString() == officerId,
                          orElse: () => {},
                        )
                      : <String, dynamic>{};
                  final officerName = officer.isNotEmpty
                      ? (officer['full_name'] ?? officer['email'] ?? 'Unknown')
                            .toString()
                      : 'Unassigned';
                  final date = _formatDate(c['created_at'] as String?);
                  return pw.TableRow(
                    children: [
                      _pdfCell(title),
                      _pdfCell(status),
                      _pdfCell(officerName),
                      _pdfCell(date),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  pw.Widget _pdfStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
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
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C1D95),
        foregroundColor: Colors.white,
        title: Text(
          widget.department,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Download PDF',
              onPressed: _generateAndSharePdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildOfficersSection(),
                    const SizedBox(height: 20),
                    _buildComplaintsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              '${_complaints.length}',
              'Total',
              const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 10),
            _statCard('$_newCount', 'New', const Color(0xFF3B82F6)),
            const SizedBox(width: 10),
            _statCard(
              '$_inProgressCount',
              'In Progress',
              const Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard('$_resolvedCount', 'Resolved', const Color(0xFF059669)),
            const SizedBox(width: 10),
            _statCard(
              '$_unassignedCount',
              'Unassigned',
              const Color(0xFFDC2626),
            ),
            const SizedBox(width: 10),
            _statCard(
              '${_officers.length}',
              'Officers',
              const Color(0xFF0891B2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Officers (${_officers.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        if (_officers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Text(
                'No officers in this department.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          )
        else
          ...(_officers.map((o) {
            final name =
                o['full_name'] as String? ?? o['email'] as String? ?? 'Officer';
            final email = o['email'] as String? ?? '';
            final assigned = _complaintsForOfficer(o['id'].toString());
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4C1D95).withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'O',
                      style: const TextStyle(
                        color: Color(0xFF4C1D95),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C1D95).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${assigned.length} complaints',
                      style: const TextStyle(
                        color: Color(0xFF4C1D95),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }

  Widget _buildComplaintsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complaints (${_complaints.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        if (_complaints.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Text(
                'No complaints yet.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          )
        else
          ...(_complaints.map((c) {
            final title = c['title'] as String? ?? '';
            final status = c['status'] as String? ?? 'New';
            final location = c['location'] as String? ?? '';
            final date = _formatDate(c['created_at'] as String?);
            final officerId = c['assigned_officer_id']?.toString();
            final officer = officerId != null
                ? _officers.firstWhere(
                    (o) => o['id'].toString() == officerId,
                    orElse: () => {},
                  )
                : <String, dynamic>{};
            final officerName = officer.isNotEmpty
                ? (officer['full_name'] ?? officer['email'] ?? 'Unknown')
                      .toString()
                : 'Unassigned';
            final statusColor = _statusColor(status);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        officerName,
                        style: TextStyle(
                          fontSize: 11,
                          color: officer.isNotEmpty
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }
}
