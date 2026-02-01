import 'package:flutter/material.dart';
import '../../../models/case_model.dart';
import '../../../config/api_config.dart';

class CasesTable extends StatelessWidget {
  final List<CaseModel> cases;
  final VoidCallback? onRefresh;

  const CasesTable({Key? key, required this.cases, this.onRefresh})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          // Table header
          _buildTableHeader(),
          const Divider(color: Color(0xFF1E293B), height: 1),
          // Table rows
          ...cases.map((caseModel) => _buildCaseRow(caseModel)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'Case ID',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Case Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'File',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Created',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Actions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseRow(CaseModel caseModel) {
    // Determine status color
    Color statusColor;
    switch (caseModel.status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        break;
      case 'processing':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'failed':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFF64748B);
    }

    // Get file info from metadata
    final fileName = caseModel.metadata?['original_filename'] ?? 'Unknown';

    // Format date
    final createdDate =
        '${caseModel.createdAt.year}-${caseModel.createdAt.month.toString().padLeft(2, '0')}-${caseModel.createdAt.day.toString().padLeft(2, '0')} ${caseModel.createdAt.hour.toString().padLeft(2, '0')}:${caseModel.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'CASE-${caseModel.id}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D9FF),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              caseModel.name,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                caseModel.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              createdDate,
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Wrap(
              spacing: 8,
              children: [
                _buildActionButton(Icons.visibility_outlined, 'View'),
                _buildActionButton(Icons.download_outlined, 'Download'),
                _buildActionButton(Icons.delete_outline, 'Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
