import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

class UploadDropZone extends StatelessWidget {
  final bool isDragging;
  final File? selectedFile;
  final bool isUploading;
  final Function(File) onFileSelected;
  final VoidCallback onBrowseFiles;
  final VoidCallback? onClearFile;
  final VoidCallback? onUpload;

  const UploadDropZone({
    Key? key,
    required this.isDragging,
    required this.selectedFile,
    this.isUploading = false,
    required this.onFileSelected,
    required this.onBrowseFiles,
    this.onClearFile,
    this.onUpload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) {
        if (details.files.isNotEmpty) {
          onFileSelected(File(details.files.first.path));
        }
      },
      onDragEntered: (details) {},
      onDragExited: (details) {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1419),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDragging
                ? const Color(0xFF00D9FF)
                : const Color(0xFF1E293B),
            width: 2,
          ),
        ),
        child: selectedFile == null
            ? _buildEmptyState()
            : _buildFileSelectedState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Color(0xFF00D9FF),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Drag & drop your memory dump',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'or click to browse files',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onBrowseFiles,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Browse Files',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          children: [
            _buildFormatChip('.raw'),
            _buildFormatChip('.dmp'),
            _buildFormatChip('.vmem'),
            _buildFormatChip('.lime'),
          ],
        ),
      ],
    );
  }

  Widget _buildFileSelectedState() {
    return Column(
      children: [
        if (isUploading)
          const Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              ),
              SizedBox(height: 16),
              Text(
                'Uploading...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          )
        else
          const Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
        const SizedBox(height: 16),
        if (!isUploading) ...[
          const Text(
            'File Selected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          selectedFile!.path.split(Platform.pathSeparator).last,
          style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: isUploading ? null : onClearFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: const BorderSide(color: Color(0xFF1E293B)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text('Change File'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isUploading ? null : onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: const Color(0xFF0A0E1A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Upload & Analyze',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatChip(String format) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        format,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
