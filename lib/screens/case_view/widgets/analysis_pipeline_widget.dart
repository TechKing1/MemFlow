import 'package:flutter/material.dart';

/// Displays the analysis pipeline as a vertical stepper with stage status icons.
class AnalysisPipelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stages;

  const AnalysisPipelineWidget({Key? key, required this.stages})
    : super(key: key);

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
          for (int i = 0; i < stages.length; i++) ...[
            _buildStageRow(stages[i], i, i == stages.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildStageRow(Map<String, dynamic> stage, int index, bool isLast) {
    final status = stage['status'] as String? ?? 'pending';
    final name = stage['name'] as String? ?? '';
    final description = stage['description'] as String? ?? '';
    final timeTaken = stage['time_taken'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: icon + connector line
        Column(
          children: [
            _buildStatusIcon(status),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: status == 'completed'
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1E293B),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Right: name + description + timing
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: status == 'pending'
                              ? const Color(0xFF64748B)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (timeTaken != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(timeTaken),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: status == 'pending'
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        );
      case 'running':
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00D9FF), width: 2),
          ),
          child: const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
            ),
          ),
        );
      case 'failed':
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 14),
        );
      default: // pending
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155), width: 2),
          ),
        );
    }
  }

  String _formatTime(dynamic seconds) {
    if (seconds == null) return '';
    final secs = (seconds is num) ? seconds.toDouble() : 0.0;
    if (secs < 60) return '${secs.toStringAsFixed(1)}s';
    final min = (secs / 60).floor();
    final sec = (secs % 60).toInt();
    return '${min}m ${sec}s';
  }
}
