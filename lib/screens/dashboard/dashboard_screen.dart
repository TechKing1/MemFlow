import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../../../models/case_model.dart';
import '../../../repositories/case_repository.dart';
import '../../../view_models/dashboard_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(
        Provider.of(context, listen: false),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload Memory Dump'),
          centerTitle: true,
        ),
        body: Consumer<DashboardViewModel>(
          builder: (context, viewModel, _) {
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Drag and Drop Area
                        _buildDropZone(viewModel),
                        const SizedBox(height: 24),
                        
                        // Or Divider
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('OR'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Browse Files Button
                        ElevatedButton.icon(
                          onPressed: () => _pickFile(viewModel),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Browse Files'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Selected File Info
                        if (viewModel.hasFileSelected)
                          Column(
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                size: 48,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                viewModel.selectedFile!.path.split('/').last,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: viewModel.isUploading
                                    ? null
                                    : () => _handleUpload(context, viewModel),
                                child: viewModel.isUploading
                                    ? const CircularProgressIndicator()
                                    : const Text('Upload File'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Error Message
                if (viewModel.hasError)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildErrorBanner(viewModel),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropZone(DashboardViewModel viewModel) {
    return DropTarget(
      onDragDone: (details) {
        if (details.files.isNotEmpty) {
          final file = File(details.files.first.path);
          viewModel.setSelectedFile(file);
        }
        setState(() => _isDragging = false);
      },
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: _isDragging ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: _isDragging ? Colors.blue : Colors.grey,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 64,
              color: _isDragging ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Drag & Drop your memory dump file here',
              style: TextStyle(
                fontSize: 18,
                color: _isDragging ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(DashboardViewModel viewModel) {
    return MaterialBanner(
      content: Text(viewModel.uploadError ?? 'An error occurred'),
      backgroundColor: Colors.red.shade100,
      contentTextStyle: const TextStyle(color: Colors.red),
      actions: [
        TextButton(
          onPressed: viewModel.clearError,
          child: const Text(
            'DISMISS',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile(DashboardViewModel viewModel) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        viewModel.setSelectedFile(file);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleUpload(
    BuildContext context,
    DashboardViewModel viewModel,
  ) async {
    final success = await viewModel.uploadFile();
    
    if (success && context.mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File successfully uploaded!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to operations screen
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/operations',
          arguments: viewModel.caseId,
        );
      }
    }
  }
}
