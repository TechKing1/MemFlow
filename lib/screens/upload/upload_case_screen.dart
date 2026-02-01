import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';
import '../../api-routes/upload/upload_api_routes.dart';
import 'widgets/upload_drop_zone.dart';

class UploadCaseScreen extends StatefulWidget {
  const UploadCaseScreen({Key? key}) : super(key: key);

  @override
  State<UploadCaseScreen> createState() => _UploadCaseScreenState();
}

class _UploadCaseScreenState extends State<UploadCaseScreen> {
  bool _isDragging = false;
  File? _selectedFile;
  bool _isUploading = false;
  String _caseName = '';
  String _caseDescription = '';
  int _priority = 5;
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['raw', 'dmp', 'vmem', 'lime'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          // Shared Sidebar
          const AppSidebar(currentRoute: '/upload'),
          // Main content
          Expanded(
            child: Column(
              children: [
                const AppTopBar(
                  title: 'Upload Case',
                  subtitle: 'Submit a new memory dump for analysis',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildCaseDetailsForm(),
                        const SizedBox(height: 24),
                        UploadDropZone(
                          isDragging: _isDragging,
                          selectedFile: _selectedFile,
                          isUploading: _isUploading,
                          onFileSelected: (file) {
                            setState(() {
                              _selectedFile = file;
                              _isDragging = false;
                            });
                          },
                          onBrowseFiles: _pickFile,
                          onClearFile: () =>
                              setState(() => _selectedFile = null),
                          onUpload: _handleUpload,
                        ),
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

  Future<void> _handleUpload() async {
    if (_selectedFile == null) {
      _showError('Please select a file to upload');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await UploadApiRoutes.uploadCase(
        file: _selectedFile!,
        name: _caseName,
        description: _caseDescription.isNotEmpty ? _caseDescription : null,
        priority: _priority,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Case "${result['case']['name']}" created successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showError('Upload failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Widget _buildCaseDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Case Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Case Name *',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'Enter a descriptive name for this case',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Case name is required';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _caseName = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'Add any relevant details about this case',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _caseDescription = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _priority.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _priority.toString(),
                        activeColor: const Color(0xFF00D9FF),
                        inactiveColor: const Color(0xFF334155),
                        onChanged: (value) {
                          setState(() {
                            _priority = value.toInt();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        _priority.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supported Formats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Memory dumps in RAW, DMP, VMEM, or LIME formats. Maximum file size: 50 GB.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
