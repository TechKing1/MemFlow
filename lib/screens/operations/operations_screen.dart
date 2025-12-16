import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/case_model.dart';
import '../../../repositories/case_repository.dart';
import '../../../view_models/operations_viewmodel.dart';

class OperationsScreen extends StatelessWidget {
  final String caseId;

  const OperationsScreen({Key? key, required this.caseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OperationsViewModel(
        Provider.of(context, listen: false),
        caseId,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Case Operations'),
          centerTitle: true,
        ),
        body: Consumer<OperationsViewModel>(
          builder: (context, viewModel, _) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Case ID Display
                          const Text(
                            'Case ID:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            caseId,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          // Operation Buttons
                          _buildOperationButton(
                            context,
                            title: 'Show File Details',
                            icon: Icons.info_outline,
                            onPressed: () => _navigateToDetails(context, viewModel),
                          ),
                          const SizedBox(height: 16),
                          _buildOperationButton(
                            context,
                            title: 'Show File Status',
                            icon: Icons.query_builder,
                            onPressed: () => _navigateToStatus(context, viewModel),
                          ),
                          const SizedBox(height: 16),
                          _buildOperationButton(
                            context,
                            title: 'Show File Report',
                            icon: Icons.assignment,
                            onPressed: () => _navigateToReport(context, viewModel),
                          ),
                          
                          // Loading Indicator
                          if (viewModel.isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 24.0),
                              child: CircularProgressIndicator(),
                            ),
                          
                          // Error Message
                          if (viewModel.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                viewModel.error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOperationButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(
    BuildContext context,
    OperationsViewModel viewModel,
  ) async {
    await viewModel.loadCaseDetails();
    if (context.mounted) {
      _showDetailsDialog(context, viewModel);
    }
  }

  void _navigateToStatus(
    BuildContext context,
    OperationsViewModel viewModel,
  ) async {
    await viewModel.loadCaseStatus();
    if (context.mounted) {
      _showStatusDialog(context, viewModel);
    }
  }

  void _navigateToReport(
    BuildContext context,
    OperationsViewModel viewModel,
  ) async {
    await viewModel.loadCaseReport();
    if (context.mounted) {
      _showReportDialog(context, viewModel);
    }
  }

  void _showDetailsDialog(
    BuildContext context,
    OperationsViewModel viewModel,
  ) {
    if (viewModel.caseDetails == null) return;

    final details = viewModel.caseDetails!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Case Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', details.name),
              if (details.description != null)
                _buildDetailRow('Description', details.description!),
              _buildDetailRow('Status', details.status),
              _buildDetailRow('Created',
                  '${details.createdAt.toLocal()}'.split('.')[0]),
              if (details.metadata != null)
                ...details.metadata!.entries
                    .map((e) => _buildDetailRow(e.key, e.value.toString()))
                    .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(
    BuildContext context,
    OperationsViewModel viewModel,
  ) {
    if (viewModel.caseStatus == null) return;

    final status = viewModel.caseStatus!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Case Status'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', status.status),
              _buildDetailRow('Progress', '${status.progress}%'),
              if (status.currentTask != null)
                _buildDetailRow('Current Task', status.currentTask!),
              if (status.startedAt != null)
                _buildDetailRow(
                  'Started',
                  '${status.startedAt!.toLocal()}'.split('.')[0],
                ),
              if (status.completedAt != null)
                _buildDetailRow(
                  'Completed',
                  '${status.completedAt!.toLocal()}'.split('.')[0],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    OperationsViewModel viewModel,
  ) {
    if (viewModel.caseReport == null) return;

    final report = viewModel.caseReport!;
    final reportData = _formatJson(report['report_data'] ?? {});
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Case Report',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow('Case ID', report['case_id']?.toString() ?? 'N/A'),
                      if (report['generated_at'] != null)
                        _buildDetailRow(
                          'Generated',
                          '${DateTime.parse(report['generated_at']).toLocal()}'.split('.')[0],
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Report Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            reportData,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // Convert JSON data into a human-readable format
  String _formatJson(dynamic json, {int indent = 0}) {
    if (json == null) return 'No data available';
    if (json is String) return json;
    
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    if (json is Map) {
      json.forEach((key, value) {
        buffer.writeln('$indentStr• ${_formatKey(key)}: ${_formatValue(value, indent: indent + 1)}');
      });
    } else if (json is List) {
      for (var i = 0; i < json.length; i++) {
        buffer.writeln('$indentStr${i + 1}. ${_formatValue(json[i], indent: indent + 1)}');
      }
    } else {
      return json.toString();
    }
    
    return buffer.toString().trim();
  }
  
  String _formatKey(String key) {
    // Convert snake_case to Title Case
    return key.split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
  
  String _formatValue(dynamic value, {required int indent}) {
    if (value is DateTime) {
      return _formatDateTime(value);
    } else if (value is Map || value is List) {
      return '\n${_formatJson(value, indent: indent)}';
    } else if (value is String) {
      // If it's a date string, format it nicely
      try {
        final date = DateTime.parse(value);
        return _formatDateTime(date);
      } catch (_) {
        return value;
      }
    }
    return value.toString();
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
  }
  
  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
