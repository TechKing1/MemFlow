import 'package:flutter/material.dart';

/// Terminal-like analysis logs widget that simulates a CLI output view.
class AnalysisLogsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> logs;

  const AnalysisLogsWidget({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Header bar (like terminal title bar)
          Row(
            children: [
              const Icon(Icons.terminal, color: Color(0xFF00D9FF), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Analysis Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Terminal dots
              Row(
                children: [
                  _buildDot(const Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  _buildDot(const Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  _buildDot(const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Terminal body
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 350),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs available',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontFamily: 'Consolas',
                        fontSize: 13,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: logs.map((log) => _buildLogLine(log)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(Map<String, dynamic> log) {
    final time = log['time'] as String? ?? '';
    final message = log['message'] as String? ?? '';

    // Color code based on message content
    Color msgColor = const Color(0xFFA0AEC0);
    if (message.contains('✓') ||
        message.contains('complete') ||
        message.contains('success')) {
      msgColor = const Color(0xFF10B981);
    } else if (message.contains('✗') ||
        message.contains('error') ||
        message.contains('failed') ||
        message.contains('no output')) {
      msgColor = const Color(0xFFEF4444);
    } else if (message.contains('Starting') || message.contains('...')) {
      msgColor = const Color(0xFF00D9FF);
    } else if (message.startsWith('  ↳')) {
      msgColor = const Color(0xFF64748B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Consolas',
            fontSize: 13,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '[$time] ',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            TextSpan(
              text: message,
              style: TextStyle(color: msgColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
