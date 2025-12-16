import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../repositories/case_repository.dart';

class OperationsViewModel extends ChangeNotifier {
  final CaseRepository _repository;
  final String caseId;
  
  CaseModel? _caseDetails;
  CaseStatus? _caseStatus;
  Map<String, dynamic>? _caseReport;
  bool _isLoading = false;
  String? _error;

  OperationsViewModel(this._repository, this.caseId);

  CaseModel? get caseDetails => _caseDetails;
  CaseStatus? get caseStatus => _caseStatus;
  Map<String, dynamic>? get caseReport => _caseReport;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> loadCaseDetails() async {
    await _loadData(_fetchCaseDetails);
  }

  Future<void> loadCaseStatus() async {
    await _loadData(_fetchCaseStatus);
  }

  Future<void> loadCaseReport() async {
    await _loadData(_fetchCaseReport);
  }

  Future<void> _loadData(Future<void> Function() fetchFunction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await fetchFunction();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCaseDetails() async {
    _caseDetails = await _repository.getCase(caseId);
  }

  Future<void> _fetchCaseStatus() async {
    _caseStatus = await _repository.getCaseStatus(caseId);
  }

  Future<void> _fetchCaseReport() async {
    _caseReport = await _repository.getCaseReport(caseId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
