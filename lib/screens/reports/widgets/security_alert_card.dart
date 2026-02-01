import 'package:flutter/material.dart';

class SecurityAlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String severity;
  final Color severityColor;
  final String timestamp;
  final VoidCallback? onTap;

  const SecurityAlertCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.severityColor,
    required this.timestamp,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getSeverityIcon(), color: severityColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              severity,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: severityColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timestamp,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: const Color(0xFF64748B), size: 20),
        ],
      ),
    );
  }

  IconData _getSeverityIcon() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.dangerous_outlined;
      case 'high':
        return Icons.warning_amber_outlined;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }
}
