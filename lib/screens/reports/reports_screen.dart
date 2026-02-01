import 'package:flutter/material.dart';
import '../../widgets/common/app_sidebar.dart';
import 'widgets/report_stats_card.dart';
import 'widgets/security_alert_card.dart';
import 'widgets/severity_distribution_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          // Shared Sidebar
          const AppSidebar(currentRoute: '/reports'),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildCustomTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        _buildChartsSection(),
                        const SizedBox(height: 24),
                        _buildSecurityAlerts(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'CASE-2024-001',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00D9FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'memory_dump_win10.raw',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Search bar
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, minWidth: 150),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search cases...',
                    hintStyle: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notification icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // User avatar
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00D9FF),
            child: Text(
              'A',
              style: TextStyle(
                color: Color(0xFF0A0E1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Export PDF Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: const Color(0xFF0A0E1A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.code, size: 18),
          label: const Text('Export JSON'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFF1E293B)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Download Artifacts'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFF1E293B)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return const Row(
      children: [
        Expanded(
          child: ReportStatsCard(
            value: '97',
            label: 'Total Findings',
            icon: Icons.search_outlined,
            color: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ReportStatsCard(
            value: '11',
            label: 'Critical/High',
            icon: Icons.dangerous_outlined,
            color: Color(0xFFEF4444),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ReportStatsCard(
            value: '234',
            label: 'Processes',
            icon: Icons.memory_outlined,
            color: Color(0xFF00D9FF),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ReportStatsCard(
            value: '156',
            label: 'Connections',
            icon: Icons.hub_outlined,
            color: Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSeverityDistribution()),
        const SizedBox(width: 16),
        Expanded(child: _buildTopProcesses()),
        const SizedBox(width: 16),
        Expanded(child: _buildNetworkTimeline()),
      ],
    );
  }

  Widget _buildSeverityDistribution() {
    return const SeverityDistributionChart(
      criticalCount: 3,
      highCount: 8,
      mediumCount: 15,
      lowCount: 24,
      infoCount: 47,
    );
  }
  }

  Widget _buildTopProcesses() {
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
          const Text(
            'Top Processes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildProcessBar('svchost.exe', 0.85),
          _buildProcessBar('chrome.exe', 0.65),
          _buildProcessBar('explorer.exe', 0.45),
          _buildProcessBar('cmd.exe', 0.35),
          _buildProcessBar('powershell.exe', 0.28),
          _buildProcessBar('csrss.exe', 0.15),
        ],
      ),
    );
  }

  Widget _buildProcessBar(String name, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTimeline() {
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
          const Text(
            'Network Activity Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.show_chart, size: 60, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['00:05', '00:10', '00:15', '00:20', '00:25']
                .map(
                  (time) => Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAlerts() {
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
          const Text(
            'Security Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detected threats and suspicious activities',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SecurityAlertCard(
            title: 'Suspicious process injection detected',
            subtitle: 'unknown.exe → svchost.exe',
            severity: 'Critical',
            severityColor: const Color(0xFFEF4444),
            timestamp: '14:24:15',
          ),
          SecurityAlertCard(
            title: 'Unusual network connection to known C2',
            subtitle: '185.234.72.xxx',
            severity: 'High',
            severityColor: const Color(0xFFF59E0B),
            timestamp: '14:33:01',
          ),
          SecurityAlertCard(
            title: 'Registry persistence mechanism found',
            subtitle: 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run',
            severity: 'High',
            severityColor: const Color(0xFFF59E0B),
            timestamp: '14:33:45',
          ),
          SecurityAlertCard(
            title: 'PowerShell encoded command execution',
            subtitle: 'powershell.exe',
            severity: 'Medium',
            severityColor: const Color(0xFF3B82F6),
            timestamp: '14:34:22',
          ),
          SecurityAlertCard(
            title: 'Credentials access attempt detected',
            subtitle: 'lsass.exe',
            severity: 'Medium',
            severityColor: const Color(0xFF3B82F6),
            timestamp: '14:35:08',
          ),
        ],
      ),
    );
  }

