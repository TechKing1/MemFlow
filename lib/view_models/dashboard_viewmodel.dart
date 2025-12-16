import 'dart:io';
import 'package:flutter/material.dart';
import '../repositories/case_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final CaseRepository _repository;
  
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;
  String? _caseId;

  DashboardViewModel(this._repository);

  File? get selectedFile => _selectedFile;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;
  bool get hasFileSelected => _selectedFile != null;
  bool get hasError => _uploadError != null;
  String? get caseId => _caseId;

  void setSelectedFile(File? file) {
    _selectedFile = file;
    _uploadError = null; // Reset error when a new file is selected
    notifyListeners();
  }

  Future<bool> uploadFile() async {
    if (_selectedFile == null) return false;
    
    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      _caseId = await _repository.uploadCase(
        file: _selectedFile!,
        caseName: _selectedFile!.path.split(Platform.pathSeparator).last,
      );
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _uploadError = e.toString();
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _uploadError = null;
    notifyListeners();
  }
}
