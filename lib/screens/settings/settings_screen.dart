import 'package:flutter/material.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';
import 'widgets/profile_card.dart';
import 'widgets/setting_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedProfile = 'balanced';
  bool _mlPoweredAnalysis = true;
  bool _deepMemoryScan = false;
  bool _networkArtifactAnalysis = true;
  bool _malwareDetection = true;
  bool _customYaraRules = true;
  bool _autoExportReports = false;
  bool _emailNotifications = true;
  bool _slackIntegration = false;
  final _emailController = TextEditingController(text: 'analyst@company.com');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          // Shared Sidebar
          const AppSidebar(currentRoute: '/settings'),
          // Main content
          Expanded(
            child: Column(
              children: [
                const AppTopBar(
                  title: 'Settings',
                  subtitle: 'Configure analysis preferences and notifications',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnalysisProfile(),
                        const SizedBox(height: 32),
                        _buildAnalysisOptions(),
                        const SizedBox(height: 32),
                        _buildNotifications(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
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

  Widget _buildAnalysisProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Analysis Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ProfileCard(
                  title: 'Quick Scan',
                  subtitle: 'Fast analysis for initial triage',
                  icon: Icons.flash_on_outlined,
                  isSelected: _selectedProfile == 'quick',
                  onTap: () => setState(() => _selectedProfile = 'quick'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProfileCard(
                  title: 'Balanced',
                  subtitle: 'Recommended for most cases',
                  icon: Icons.shield_outlined,
                  isSelected: _selectedProfile == 'balanced',
                  onTap: () => setState(() => _selectedProfile = 'balanced'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProfileCard(
                  title: 'Deep Analysis',
                  subtitle: 'Comprehensive scan, slower',
                  icon: Icons.search_outlined,
                  isSelected: _selectedProfile == 'deep',
                  onTap: () => setState(() => _selectedProfile = 'deep'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisOptions() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Analysis Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingToggle(
            title: 'ML-Powered Analysis',
            subtitle:
                'Use machine learning models for enhanced threat detection',
            value: _mlPoweredAnalysis,
            onChanged: (value) => setState(() => _mlPoweredAnalysis = value),
          ),
          SettingToggle(
            title: 'Deep Memory Scan',
            subtitle:
                'Perform exhaustive memory scanning (increases analysis time)',
            value: _deepMemoryScan,
            onChanged: (value) => setState(() => _deepMemoryScan = value),
          ),
          SettingToggle(
            title: 'Network Artifact Analysis',
            subtitle: 'Extract and analyze network connections and DNS cache',
            value: _networkArtifactAnalysis,
            onChanged: (value) =>
                setState(() => _networkArtifactAnalysis = value),
          ),
          SettingToggle(
            title: 'Malware Detection',
            subtitle:
                'Scan for known malware signatures and suspicious patterns',
            value: _malwareDetection,
            onChanged: (value) => setState(() => _malwareDetection = value),
          ),
          SettingToggle(
            title: 'Custom YARA Rules',
            subtitle: 'Apply custom YARA rules during analysis',
            value: _customYaraRules,
            onChanged: (value) => setState(() => _customYaraRules = value),
          ),
          SettingToggle(
            title: 'Auto-Export Reports',
            subtitle: 'Automatically export reports when analysis completes',
            value: _autoExportReports,
            onChanged: (value) => setState(() => _autoExportReports = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingToggle(
            title: 'Email Notifications',
            subtitle: 'Receive email alerts when analysis completes',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          SettingToggle(
            title: 'Slack Integration',
            subtitle: 'Send notifications to Slack channel',
            value: _slackIntegration,
            onChanged: (value) => setState(() => _slackIntegration = value),
          ),
          const SizedBox(height: 20),
          const Text(
            'Notification Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'analyst@company.com',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
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
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // Reset to defaults
            setState(() {
              _selectedProfile = 'balanced';
              _mlPoweredAnalysis = true;
              _deepMemoryScan = false;
              _networkArtifactAnalysis = true;
              _malwareDetection = true;
              _customYaraRules = true;
              _autoExportReports = false;
              _emailNotifications = true;
              _slackIntegration = false;
              _emailController.text = 'analyst@company.com';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings reset to defaults'),
                backgroundColor: Color(0xFF64748B),
              ),
            );
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reset to Defaults'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFF1E293B)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Save settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved successfully'),
                backgroundColor: Color(0xFF00D9FF),
              ),
            );
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Save Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: const Color(0xFF0A0E1A),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
