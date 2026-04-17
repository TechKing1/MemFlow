import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../config/api_config.dart';
import '../../view_models/notification_provider.dart';
import '../../services/socket_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'widgets/analysis_pipeline_widget.dart';
import 'widgets/analysis_logs_widget.dart';
import 'widgets/analysis_stats_widget.dart';

class CaseViewScreen extends StatefulWidget {
  final int caseId;

  const CaseViewScreen({Key? key, required this.caseId}) : super(key: key);

  @override
  State<CaseViewScreen> createState() => _CaseViewScreenState();
}

class _CaseViewScreenState extends State<CaseViewScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  // Direct WebSocket listener
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _fetchStages();

    // Listen directly to WebSocket case_update events
    _socketService.addListener(_onWebSocketEvent);

    // Ensure socket is connected
    _socketService.connect();
  }

  /// Called on every WebSocket case_update event.
  void _onWebSocketEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final caseId = event['case_id'];
    final caseIdStr = caseId?.toString() ?? '';

    // Only re-fetch if this event is for OUR case
    if (caseIdStr == widget.caseId.toString()) {
      print(
        '[CaseView] WebSocket update for case ${widget.caseId} — re-fetching stages',
      );
      _fetchStages(silent: true);
    }
  }

  @override
  void dispose() {
    _socketService.removeListener(_onWebSocketEvent);
    super.dispose();
  }

  Future<void> _fetchStages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final url = '${ApiConfig.baseUrl}/api/cases/${widget.caseId}/stages';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _data = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (!silent && mounted) {
          setState(() {
            _errorMessage = 'Failed to load: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          const AppSidebar(currentRoute: '/dashboard'),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Case Analysis',
                  subtitle: _data != null
                      ? 'Case ID: CASE-${widget.caseId}'
                      : 'Loading...',
                  showBackButton: true,
                  onBackPressed: () => Navigator.pop(context),
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchStages, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final stages = (_data!['stages'] as List).cast<Map<String, dynamic>>();
    final logs = (_data!['logs'] as List).cast<Map<String, dynamic>>();
    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};
    final status = _data!['status'] as String? ?? 'queued';
    final fileName = _data!['file_name'] as String? ?? 'Unknown';
    final fileSize = _data!['file_size'] as int? ?? 0;
    final progress = (_data!['overall_progress'] as num?)?.toDouble() ?? 0;
    final totalTime = (_data!['total_time'] as num?)?.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header card
          _buildFileHeader(fileName, fileSize, status, progress),
          const SizedBox(height: 24),
          // Main content: pipeline + stats side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Pipeline + Logs
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    AnalysisPipelineWidget(stages: stages),
                    const SizedBox(height: 20),
                    AnalysisLogsWidget(logs: logs),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Stats sidebar
              Expanded(
                flex: 1,
                child: AnalysisStatsWidget(
                  status: status,
                  stats: stats,
                  totalTime: totalTime,
                  caseId: widget.caseId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileHeader(
    String fileName,
    int fileSize,
    String status,
    double progress,
  ) {
    final sizeStr = fileSize > 1024 * 1024 * 1024
        ? '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
        : fileSize > 1024 * 1024
        ? '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(fileSize / 1024).toStringAsFixed(1)} KB';

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sizeStr,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(
                status == 'failed'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF00D9FF),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        bgColor = const Color(0xFF10B981).withOpacity(0.15);
        textColor = const Color(0xFF10B981);
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case 'processing':
        bgColor = const Color(0xFF00D9FF).withOpacity(0.15);
        textColor = const Color(0xFF00D9FF);
        label = 'Analyzing';
        icon = Icons.autorenew;
        break;
      case 'failed':
        bgColor = const Color(0xFFEF4444).withOpacity(0.15);
        textColor = const Color(0xFFEF4444);
        label = 'Failed';
        icon = Icons.error;
        break;
      default:
        bgColor = const Color(0xFFF59E0B).withOpacity(0.15);
        textColor = const Color(0xFFF59E0B);
        label = 'Queued';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
