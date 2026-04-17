import 'package:flutter/material.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../api-routes/reports/reports_api_routes.dart';
import '../../api-routes/dashboard/dashboard_api_routes.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert' as convert;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _reportData;
  List<Map<String, dynamic>> _completedCases = [];
  int? _selectedCaseId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCompletedCases();
  }

  Future<void> _fetchCompletedCases() async {
    try {
      final result = await DashboardApiRoutes.getAllCases(
        page: 1,
        limit: 100,
        status: 'completed',
      );
      final cases = (result['cases'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _completedCases = cases;
        if (cases.isNotEmpty && _selectedCaseId == null) {
          _selectedCaseId = cases.first['id'] as int;
          _fetchReport(_selectedCaseId!);
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load cases: $e');
    }
  }

  Future<void> _fetchReport(int caseId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ReportsApiRoutes.getCaseReport(caseId);
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report: $e';
        _isLoading = false;
      });
    }
  }

  String _getDownloadsPath() {
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    return '$home${Platform.pathSeparator}Downloads';
  }

  Future<void> _exportJson() async {
    if (_selectedCaseId == null) return;
    try {
      final data = await ReportsApiRoutes.getCaseReport(_selectedCaseId!);
      final dir = _getDownloadsPath();
      final file = File(
        '$dir${Platform.pathSeparator}memflow_report_case_$_selectedCaseId.json',
      );
      final encoder = convert.JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('JSON saved to ${file.path}'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedCaseId == null) return;
    try {
      final url = '${ApiConfig.baseUrl}/api/cases/$_selectedCaseId/report/pdf';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = _getDownloadsPath();
        final file = File(
          '$dir${Platform.pathSeparator}memflow_report_case_$_selectedCaseId.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to ${file.path}'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          const AppSidebar(currentRoute: '/reports'),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(
                  title: 'Reports',
                  subtitle: 'View and export analysis reports',
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Case selector + export buttons
        _buildToolbar(),
        const Divider(color: Color(0xFF1E293B), height: 1),
        // Report content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                )
              : _errorMessage != null
              ? _buildError()
              : _reportData == null || _reportData!['report'] == null
              ? _buildEmptyState()
              : _buildReportContent(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Case selector dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCaseId,
                hint: const Text(
                  'Select case',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF64748B),
                ),
                items: _completedCases.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(
                      'Case #${c['id']} — ${c['name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() => _selectedCaseId = id);
                    _fetchReport(id);
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          // Export JSON
          _buildExportButton(
            icon: Icons.data_object,
            label: 'Export JSON',
            onPressed: _selectedCaseId != null ? _exportJson : null,
          ),
          const SizedBox(width: 8),
          // Export PDF
          _buildExportButton(
            icon: Icons.picture_as_pdf,
            label: 'Export PDF',
            onPressed: _selectedCaseId != null ? _exportPdf : null,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? const Color(0xFF00D9FF)
            : const Color(0xFF1E293B),
        foregroundColor: isPrimary
            ? const Color(0xFF0A0E1A)
            : const Color(0xFF94A3B8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: const Color(0xFF64748B).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No report available',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a completed case to view its report',
            style: TextStyle(color: Color(0xFF475569), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selectedCaseId != null) _fetchReport(_selectedCaseId!);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    final report = _reportData!['report'] as Map<String, dynamic>;
    final metadata = report['analysis_metadata'] as Map<String, dynamic>? ?? {};
    final fileInfo = report['file_information'] as Map<String, dynamic>? ?? {};
    final osInfo = report['os_detection'] as Map<String, dynamic>? ?? {};
    final processInfo =
        report['process_analysis'] as Map<String, dynamic>? ?? {};
    final networkInfo =
        report['network_analysis'] as Map<String, dynamic>? ?? {};
    final performance = report['performance'] as Map<String, dynamic>? ?? {};
    final pluginFailures =
        report['plugin_failures'] as Map<String, dynamic>? ?? {};
    final threatAlerts =
        (report['threat_alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final threatSummary =
        report['threat_summary'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          _buildStatsRow(
            metadata,
            osInfo,
            processInfo,
            networkInfo,
            performance,
            threatSummary,
          ),
          const SizedBox(height: 24),
          // Threat alerts section (shown first if any)
          if (threatAlerts.isNotEmpty) ...[
            _buildThreatAlertsSection(threatAlerts, threatSummary),
            const SizedBox(height: 16),
          ],
          // Sections
          _buildSection('📋 Analysis Metadata', [
            _kvRow('Analyzer', metadata['analyzer']?.toString() ?? 'Unknown'),
            _kvRow(
              'Analysis Date',
              _formatDate(metadata['analysis_date']?.toString()),
            ),
            _kvRow(
              'Plugin Level',
              metadata['plugin_level']?.toString() ?? 'Unknown',
            ),
            _kvRow('Plugins Executed', '${metadata['plugins_executed'] ?? 0}'),
            _kvRow(
              'Plugins Successful',
              '${metadata['plugins_successful'] ?? 0}',
            ),
          ]),
          const SizedBox(height: 16),
          _buildFileInfoSection(fileInfo),
          const SizedBox(height: 16),
          _buildOsSection(osInfo),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildProcessSection(processInfo)),
              const SizedBox(width: 16),
              Expanded(child: _buildNetworkSection(networkInfo)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPerformanceSection(performance),
          const SizedBox(height: 16),
          if (pluginFailures.isNotEmpty)
            _buildPluginFailuresSection(pluginFailures),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    Map<String, dynamic> metadata,
    Map<String, dynamic> osInfo,
    Map<String, dynamic> processInfo,
    Map<String, dynamic> networkInfo,
    Map<String, dynamic> performance,
    Map<String, dynamic> threatSummary,
  ) {
    final totalTime = performance['total_time'] as num? ?? 0;
    final timeStr = totalTime > 60
        ? '${(totalTime / 60).toStringAsFixed(1)} min'
        : '${totalTime.toStringAsFixed(1)}s';
    final threatTotal = (threatSummary['total'] as num? ?? 0).toInt();
    final criticalCount = (threatSummary['critical'] as num? ?? 0).toInt();

    return Row(
      children: [
        _buildStatCard(
          'OS',
          osInfo['operating_system']?.toString() ?? '?',
          Icons.desktop_windows,
          const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Confidence',
          '${osInfo['confidence_score'] ?? 0}%',
          Icons.verified,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Processes',
          '${processInfo['total_count'] ?? processInfo['count'] ?? 0}',
          Icons.memory,
          const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          threatTotal == 0 ? 'No Threats' : '$threatTotal Threats',
          criticalCount > 0 ? '$criticalCount CRITICAL' : threatTotal == 0 ? 'Clean' : 'Detected',
          Icons.shield_outlined,
          threatTotal == 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Analysis Time',
          timeStr,
          Icons.timer,
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1419),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00D9FF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoSection(Map<String, dynamic> fileInfo) {
    final hashes = fileInfo['hashes'] as Map<String, dynamic>? ?? {};
    return _buildSection('📁 File Information', [
      _kvRow('Size', fileInfo['size_human']?.toString() ?? 'Unknown'),
      _kvRow(
        'Format',
        (fileInfo['format']?['type']?.toString() ?? 'Unknown').toUpperCase(),
      ),
      _kvRow('Format Confidence', '${fileInfo['format']?['confidence'] ?? 0}%'),
      if (hashes['md5'] != null) _buildHashRow('MD5', hashes['md5'].toString()),
      if (hashes['sha256'] != null)
        _buildHashRow('SHA256', hashes['sha256'].toString()),
    ]);
  }

  Widget _buildHashRow(String label, String hash) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              hash,
              style: const TextStyle(
                fontFamily: 'Consolas',
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOsSection(Map<String, dynamic> osInfo) {
    final confidence = (osInfo['confidence_score'] as num?)?.toDouble() ?? 0;
    final evidence = (osInfo['evidence'] as List?)?.cast<String>() ?? [];

    return _buildSection('🖥 OS Detection', [
      _kvRow(
        'Operating System',
        osInfo['operating_system']?.toString() ?? 'Unknown',
      ),
      _kvRow(
        'Confidence',
        '${confidence.toInt()}% — ${osInfo['confidence_level'] ?? 'Unknown'}',
      ),
      const SizedBox(height: 8),
      // Confidence bar
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: confidence / 100,
          backgroundColor: const Color(0xFF1E293B),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
          minHeight: 6,
        ),
      ),
      _kvRow(
        'Detection Method',
        osInfo['detection_method']?.toString() ?? 'Unknown',
      ),
      if (evidence.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text(
          'Evidence:',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        ...evidence.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Row(
              children: [
                const Text(
                  '› ',
                  style: TextStyle(
                    color: Color(0xFF00D9FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildProcessSection(Map<String, dynamic> processInfo) {
    final detected = processInfo['detected'] as bool? ?? false;
    return _buildSection('⚙ Process Analysis', [
      _kvRow('Status', detected ? 'Detected' : 'Not detected'),
      _kvRow('Process Count', '${processInfo['count'] ?? 0}'),
    ]);
  }

  Widget _buildNetworkSection(Map<String, dynamic> networkInfo) {
    final detected = networkInfo['detected'] as bool? ?? false;
    return _buildSection('🌐 Network Analysis', [
      _kvRow('Status', detected ? 'Detected' : 'Not detected'),
      _kvRow('Connection Count', '${networkInfo['count'] ?? 0}'),
      if (networkInfo['failure_reason'] != null)
        _kvRow('Failure Reason', networkInfo['failure_reason'].toString()),
    ]);
  }

  Widget _buildPerformanceSection(Map<String, dynamic> performance) {
    final totalTime = performance['total_time'] as num? ?? 0;
    final stages = performance['stage_timings'] as Map<String, dynamic>? ?? {};

    return _buildSection('⏱ Performance', [
      _kvRow(
        'Total Analysis Time',
        totalTime > 60
            ? '${(totalTime / 60).toStringAsFixed(1)} min'
            : '${totalTime.toStringAsFixed(1)}s',
      ),
      if (stages.isNotEmpty) ...[
        const SizedBox(height: 8),
        ...stages.entries.map((e) {
          final name = e.key.replaceAll('_', ' ');
          final seconds = (e.value as num).toStringAsFixed(2);
          return _kvRow(
            name[0].toUpperCase() + name.substring(1),
            '${seconds}s',
          );
        }),
      ],
    ]);
  }

  // ── Threat Alerts Section ──────────────────────────────────────────────────

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFFDC2626);
      case 'HIGH':     return const Color(0xFFF97316);
      case 'MEDIUM':   return const Color(0xFFF59E0B);
      case 'LOW':      return const Color(0xFF3B82F6);
      default:         return const Color(0xFF64748B);
    }
  }

  Widget _buildThreatAlertsSection(
    List<Map<String, dynamic>> alerts,
    Map<String, dynamic> summary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7F1D1D).withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              const Text(
                '🚨 Threat Alerts',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Severity summary chips
              _buildSummaryChip('CRITICAL',
                  (summary['critical'] as num? ?? 0).toInt(),
                  const Color(0xFFDC2626)),
              const SizedBox(width: 6),
              _buildSummaryChip('HIGH',
                  (summary['high'] as num? ?? 0).toInt(),
                  const Color(0xFFF97316)),
              const SizedBox(width: 6),
              _buildSummaryChip('MEDIUM',
                  (summary['medium'] as num? ?? 0).toInt(),
                  const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 16),
          // Alert cards
          ...alerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity  = alert['severity']?.toString() ?? 'INFO';
    final sevColor  = _severityColor(severity);
    final title     = alert['title']?.toString() ?? 'Unknown Alert';
    final desc      = alert['description']?.toString() ?? '';
    final dfir      = alert['dfir_explanation']?.toString() ?? '';
    final evidence  = (alert['evidence'] as List?)?.cast<String>() ?? [];
    final mitre     = (alert['mitre_techniques'] as List?)
                          ?.cast<Map<String, dynamic>>() ?? [];
    final ruleId    = alert['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sevColor.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sevColor.withOpacity(0.4)),
            ),
            child: Text(
              severity,
              style: TextStyle(
                color: sevColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (ruleId.isNotEmpty)
                Text(
                  ruleId,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontFamily: 'Consolas',
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              desc,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          iconColor: const Color(0xFF64748B),
          collapsedIconColor: const Color(0xFF64748B),
          children: [
            // Evidence
            if (evidence.isNotEmpty) ...[
              const Text(
                'Evidence:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...evidence.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('› ',
                        style: TextStyle(
                            color: sevColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(e,
                          style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontFamily: 'Consolas')),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 10),
            ],
            // MITRE ATT&CK
            if (mitre.isNotEmpty) ...[
              const Text(
                'MITRE ATT&CK:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mitre.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      '${t['id']} · ${t['name']}',
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            // DFIR Explanation
            if (dfir.isNotEmpty) ...[
              const Text(
                'DFIR Investigation Guidance:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  dfir,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPluginFailuresSection(Map<String, dynamic> failures) {
    return _buildSection('🔌 Plugin Results', [
      ...failures.entries.map(
        (e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.close, color: Color(0xFFEF4444), size: 14),
              const SizedBox(width: 8),
              Text(
                e.key,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  e.value.toString(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
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
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
