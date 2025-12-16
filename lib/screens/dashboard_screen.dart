import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import 'package:cross_file/cross_file.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isHovering = false;

  final List<String> _supportedExtensions = ['.raw', '.mem', '.vmem', '.bin'];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['raw', 'mem', 'vmem', 'bin'],
        dialogTitle: 'Select Memory Dump File',
      );

      if (result != null && result.files.single.path != null) {
        _handleFileSelection(result.files.single);
      }
    } catch (e) {
      _showErrorDialog('Error selecting file: $e');
    }
  }

  void _handleFileSelection(PlatformFile file) {
    final fileExtension = file.extension?.toLowerCase() ?? '';
    
    if (_supportedExtensions.contains('.$fileExtension')) {
      setState(() {
        _selectedFilePath = file.path!;
        _selectedFileName = file.name;
      });
    } else {
      _showErrorSnackBar('Unsupported file type. Please use: ${_supportedExtensions.join(', ')}');
      debugPrint('Unsupported file type: $fileExtension');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up any controllers or listeners here
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    
    // Create a GlobalKey for the snackbar to control its animation
    final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
    
    final snackBar = SnackBar(
      key: _scaffoldKey,
      content: Text(
        '❌ $message',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 4,
      duration: const Duration(seconds: 5),
      // Add smooth fade animation
      animation: CurvedAnimation(
        parent: kAlwaysCompleteAnimation,
        curve: Curves.easeInOut,
      ),
      // Add custom animation for showing/hiding
      dismissDirection: DismissDirection.none, // Disable swipe to dismiss
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          scaffoldMessenger.hideCurrentSnackBar(
            reason: SnackBarClosedReason.dismiss,
          );
        },
      ),
    );
    
    // Show the snackbar with a smooth animation
    scaffoldMessenger.showSnackBar(snackBar).closed.then((reason) {
      // This callback runs when the snackbar is dismissed
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss the current snackbar when tapping anywhere on the screen
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forensense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUploadCard(),
              if (_selectedFilePath != null) ...[
                const SizedBox(height: 24),
                _buildSelectedFileInfo(),
              ],
            ],
          ),
        ),
      ),
    )
    );
  }

  Widget _buildUploadCard() {
    return DropTarget(
      onDragDone: (details) async {
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          _handleFileSelection(PlatformFile(
            name: file.name,
            path: file.path,
            size: await file.length(),
          ));
        }
      },
      onDragEntered: (details) {
        setState(() {
          _isHovering = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isHovering = false;
        });
      },
      child: Card(
        elevation: _isHovering ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _isHovering 
              ? const BorderSide(color: AppTheme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isHovering ? Icons.upload_file : Icons.cloud_upload_outlined,
                size: 64,
                color: _isHovering 
                    ? AppTheme.primaryColor 
                    : AppTheme.primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _isHovering 
                    ? 'Drop your memory dump file here' 
                    : 'Drag & Drop your memory dump file here',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _isHovering ? AppTheme.primaryColor : null,
                      fontWeight: _isHovering ? FontWeight.bold : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'or',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Browse Files'),
              ),
              const SizedBox(height: 16),
              Text(
                'Supported formats: ${_supportedExtensions.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.successDark,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Selected',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successDark,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFileName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.successColor,
                            overflow: TextOverflow.ellipsis,
                          ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Path: $_selectedFilePath',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.successDark,
                  overflow: TextOverflow.ellipsis,
                ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Select Different File'),
            ),
          ),
        ],
      ),
    );
  }
}
