import 'package:flutter/material.dart';

/// Sidebar widget showing analysis statistics and actions.
class AnalysisStatsWidget extends StatelessWidget {
  final String status;
  final Map<String, dynamic> stats;
  final double? totalTime;
  final int caseId;

  const AnalysisStatsWidget({
    Key? key,
    required this.status,
    required this.stats,
    this.totalTime,
    required this.caseId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Analysis Stats card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1419),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analysis Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                'Processes Found',
                '${stats['processes_found'] ?? 0}',
              ),
              _buildStatRow(
                'Network Connections',
                stats['network_connections']?.toString() ?? '—',
              ),
              _buildStatRow(
                'OS Detected',
                stats['os_detected']?.toString() ?? '—',
              ),
              if (totalTime != null)
                _buildStatRow('Time Elapsed', _formatTime(totalTime!)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Actions card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1419),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: status == 'completed'
                      ? () => Navigator.pushNamed(context, '/reports')
                      : null,
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('View Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final min = (seconds / 60).floor();
    final sec = (seconds % 60).toInt();
    return '${min}m ${sec}s';
  }
}
