import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

class ComplaintReportScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintReportScreen({Key? key, required this.complaint})
      : super(key: key);

  @override
  State<ComplaintReportScreen> createState() => _ComplaintReportScreenState();
}

class _ComplaintReportScreenState extends State<ComplaintReportScreen> {
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _citizenProfile;
  Map<String, dynamic>? _officerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _history = await NotificationService.fetchStatusHistory(
          widget.complaint['id'].toString());

      final citizenId = widget.complaint['citizen_id']?.toString();
      if (citizenId != null) {
        final d = await supabase
            .from('profiles')
            .select()
            .eq('id', citizenId)
            .maybeSingle();
        _citizenProfile = d != null ? Map<String, dynamic>.from(d) : null;
      }

      final officerId =
          widget.complaint['assigned_officer_id']?.toString();
      if (officerId != null && officerId.isNotEmpty) {
        final d = await supabase
            .from('profiles')
            .select()
            .eq('id', officerId)
            .maybeSingle();
        _officerProfile = d != null ? Map<String, dynamic>.from(d) : null;
      }
    } catch (e) {
      debugPrint('Report load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final status = c['status'] as String? ?? 'New';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text('Complaint Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Download PDF',
              onPressed: _generatePdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildComplaintInfoCard(c, status),
                  const SizedBox(height: 16),
                  if (_citizenProfile != null) ...[
                    _buildInfoCard(
                      title: 'Submitted By',
                      icon: Icons.person_outline,
                      rows: [
                        _row(Icons.person_outline,
                            _citizenProfile!['full_name'] as String? ?? 'N/A'),
                        _row(Icons.email_outlined,
                            _citizenProfile!['email'] as String? ?? ''),
                        if ((_citizenProfile!['phone'] as String? ?? '')
                            .isNotEmpty)
                          _row(Icons.phone_outlined,
                              _citizenProfile!['phone'] as String),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_officerProfile != null) ...[
                    _buildInfoCard(
                      title: 'Assigned Officer',
                      icon: Icons.badge_outlined,
                      rows: [
                        _row(Icons.badge_outlined,
                            _officerProfile!['full_name'] as String? ?? 'N/A'),
                        _row(Icons.business_outlined,
                            _officerProfile!['department'] as String? ?? ''),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTimelineCard(status),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildComplaintInfoCard(Map<String, dynamic> c, String status) {
    final statusColor = _statusColor(status);
    final submittedAt = _formatDateTime(c['created_at'] as String?);
    final resolvedEntry = _history.lastWhere(
      (h) => h['status'] == 'Resolved',
      orElse: () => {},
    );
    final resolvedAt = resolvedEntry.isNotEmpty
        ? _formatDateTime(resolvedEntry['created_at'] as String?)
        : null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(c['category'] as String? ?? '',
                    style: const TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(c['title'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          if ((c['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(c['description'] as String,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
          ],
          const SizedBox(height: 12),
          _row(Icons.location_on_outlined, c['location'] as String? ?? ''),
          const SizedBox(height: 6),
          _row(Icons.business_outlined,
              c['assigned_department'] as String? ?? ''),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          // Key timestamps
          _timestampRow('Submitted', submittedAt, const Color(0xFF3B82F6)),
          if (resolvedAt != null) ...[
            const SizedBox(height: 8),
            _timestampRow('Resolved', resolvedAt, const Color(0xFF059669)),
          ],
          const SizedBox(height: 8),
          _timestampRow(
              'Status Updates',
              '${_history.length} time${_history.length != 1 ? 's' : ''}',
              const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String currentStatus) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 16, color: Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              const Text('Status History',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1F2937))),
              const Spacer(),
              Text('${_history.length} update${_history.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (_history.isEmpty)
            const Text('No updates yet.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))
          else
            ...List.generate(_history.length, (i) {
              final h = _history[i];
              final isLast = i == _history.length - 1;
              final hStatus = h['status'] as String? ?? '';
              final hComment = h['comment'] as String? ?? '';
              final hDate = _formatDateTime(h['created_at'] as String?);
              final color = _statusColor(hStatus);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot & line
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      if (!isLast)
                        Container(
                            width: 2,
                            height: 52,
                            color: const Color(0xFFE5E7EB)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(hStatus,
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              // Update number badge
                              Text('#${i + 1}',
                                  style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(hDate,
                              style: const TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 12)),
                          if (hComment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(hComment,
                                  style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 12)),
                            ),
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

  Future<void> _generatePdf() async {
    final c = widget.complaint;
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final status = c['status'] as String? ?? 'New';

    final resolvedEntry = _history.lastWhere(
      (h) => h['status'] == 'Resolved',
      orElse: () => {},
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context ctx) => [
          pw.Text('Complaint Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated: ${_formatDateTime(DateTime.now().toIso8601String())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(height: 24),

          // Complaint info
          pw.Text('Complaint Details',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              _pdfRow('Title', c['title'] as String? ?? '-'),
              _pdfRow('Category', c['category'] as String? ?? '-'),
              _pdfRow('Status', status),
              _pdfRow('Location', c['location'] as String? ?? '-'),
              _pdfRow('Department', c['assigned_department'] as String? ?? '-'),
              _pdfRow('Submitted On', _formatDateTime(c['created_at'] as String?)),
              if (resolvedEntry.isNotEmpty)
                _pdfRow('Resolved On', _formatDateTime(resolvedEntry['created_at'] as String?)),
              _pdfRow('Total Status Updates', '${_history.length}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Citizen info
          if (_citizenProfile != null) ...[
            pw.Text('Submitted By',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _pdfRow('Name', _citizenProfile!['full_name'] as String? ?? '-'),
                _pdfRow('Email', _citizenProfile!['email'] as String? ?? '-'),
                if ((_citizenProfile!['phone'] as String? ?? '').isNotEmpty)
                  _pdfRow('Phone', _citizenProfile!['phone'] as String),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Officer info
          if (_officerProfile != null) ...[
            pw.Text('Assigned Officer',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _pdfRow('Name', _officerProfile!['full_name'] as String? ?? '-'),
                _pdfRow('Department', _officerProfile!['department'] as String? ?? '-'),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Status history
          pw.Text('Status History (${_history.length} updates)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (_history.isEmpty)
            pw.Text('No updates yet.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('#', bold: true),
                    _pdfCell('Status', bold: true),
                    _pdfCell('Date & Time', bold: true),
                    _pdfCell('Comment', bold: true),
                  ],
                ),
                ...List.generate(_history.length, (i) {
                  final h = _history[i];
                  return pw.TableRow(children: [
                    _pdfCell('${i + 1}'),
                    _pdfCell(h['status'] as String? ?? '-'),
                    _pdfCell(_formatDateTime(h['created_at'] as String?)),
                    _pdfCell(h['comment'] as String? ?? '-'),
                  ]);
                }),
              ],
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(children: [
      _pdfCell(label, bold: true),
      _pdfCell(value),
    ]);
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

  Widget _timestampRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563))),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFF4B5563), fontSize: 13))),
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

  String _formatDateTime(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '-';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}  $hour:$min';
  }
}
