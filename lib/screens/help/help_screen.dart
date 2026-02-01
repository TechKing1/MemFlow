import 'package:flutter/material.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';
import 'widgets/feature_card.dart';
import 'widgets/step_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          // Shared Sidebar
          const AppSidebar(currentRoute: '/help'),
          // Main content
          Expanded(
            child: Column(
              children: [
                const AppTopBar(
                  title: 'Help & About',
                  subtitle: 'Learn about MemForensics and how to use it',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        _buildWhatThisSystemDoes(),
                        const SizedBox(height: 32),
                        _buildHowItWorks(),
                        const SizedBox(height: 32),
                        _buildTechnologiesUsed(),
                        const SizedBox(height: 32),
                        _buildEducationalDisclaimer(),
                        const SizedBox(height: 32),
                        _buildNeedHelp(),
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

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 60,
              color: Color(0xFF00D9FF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'MemForensics',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Advanced Digital Forensics Memory Analysis Platform for cybersecurity\nprofessionals and incident responders. Analyze Windows memory dumps to\ndetect malware, extract artifacts, and investigate security incidents.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Version 1.0.0 • Graduation Project 2024',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhatThisSystemDoes() {
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
                  Icons.menu_book_outlined,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'What This System Does',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FeatureCard(
                  title: 'Memory Dump Analysis',
                  description:
                      'Upload and analyze Windows memory dumps in RAW, DMP, or VMEM formats.',
                  icon: Icons.upload_file_outlined,
                  iconColor: const Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FeatureCard(
                  title: 'Process Detection',
                  description:
                      'Identify running processes, threads, and detect hidden or injected code.',
                  icon: Icons.memory_outlined,
                  iconColor: const Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FeatureCard(
                  title: 'Network Forensics',
                  description:
                      'Extract network connections, DNS cache, and identify C2 communications.',
                  icon: Icons.hub_outlined,
                  iconColor: const Color(0xFF00D9FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FeatureCard(
                  title: 'Malware Detection',
                  description:
                      'Scan for known malware signatures and suspicious behavioral patterns.',
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FeatureCard(
                  title: 'Artifact Extraction',
                  description:
                      'Extract registry keys, file handles, and other forensic artifacts.',
                  icon: Icons.folder_outlined,
                  iconColor: const Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FeatureCard(
                  title: 'ML-Powered Analysis',
                  description:
                      'Advanced machine learning models for enhanced threat detection.',
                  icon: Icons.auto_awesome_outlined,
                  iconColor: const Color(0xFF00D9FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
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
                  Icons.info_outline,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How It Works',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Expanded(
                child: StepCard(
                  stepNumber: '1',
                  title: 'Upload Memory Dump',
                  description:
                      'Select and upload your memory dump file for analysis',
                ),
              ),
              Container(width: 40, height: 2, color: const Color(0xFF1E293B)),
              const Expanded(
                child: StepCard(
                  stepNumber: '2',
                  title: 'Automated Analysis',
                  description: 'System processes dump using multiple plugins',
                ),
              ),
              Container(width: 40, height: 2, color: const Color(0xFF1E293B)),
              const Expanded(
                child: StepCard(
                  stepNumber: '3',
                  title: 'Extract Artifacts',
                  description:
                      'Identify processes, network connections, and artifacts',
                ),
              ),
              Container(width: 40, height: 2, color: const Color(0xFF1E293B)),
              const Expanded(
                child: StepCard(
                  stepNumber: '4',
                  title: 'Generate Report',
                  description: 'View detailed reports for documentation',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnologiesUsed() {
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
                  Icons.code_outlined,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Technologies Used',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTechChip('Volatility 3 Framework'),
              _buildTechChip('YARA Rule Engine'),
              _buildTechChip('TensorFlow ML Models'),
              _buildTechChip('Flutter + Dart'),
              _buildTechChip('PostgreSQL Database'),
              _buildTechChip('Docker Containers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildEducationalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational Disclaimer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This is a graduation project developed for educational purposes in the field of Cybersecurity and Software Engineering. The system demonstrates concepts of digital forensics and memory analysis. Always follow proper legal and ethical guidelines when conducting forensic investigations.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelp() {
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
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildHelpButton(
                icon: Icons.menu_book_outlined,
                label: 'Documentation',
                onTap: () {},
              ),
              _buildHelpButton(
                icon: Icons.code_outlined,
                label: 'GitHub Repository',
                onTap: () {},
              ),
              _buildHelpButton(
                icon: Icons.email_outlined,
                label: 'Contact Support',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00D9FF), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, color: Color(0xFF64748B), size: 16),
          ],
        ),
      ),
    );
  }
}
