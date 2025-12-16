import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:memoryforensics/models/case_model.dart';

// Import the endpoint files
import 'case_repository.upload.dart' as upload;
import 'case_repository.get_case.dart' as get_case;
import 'case_repository.get_status.dart' as get_status;
import 'case_repository.get_report.dart' as get_report;

class CaseRepository {
  static const String _baseUrl = 'http://127.0.0.1:5000';
  final http.Client client;

  CaseRepository({http.Client? client}) : client = client ?? http.Client();

  Future<String> uploadCase({
    required File file,
    required String caseName,
    String? description,
  }) async {
    return await upload.uploadCase(
      client: client,
      baseUrl: _baseUrl,
      file: file,
      caseName: caseName,
      description: description,
    );
  }

  Future<CaseModel> getCase(String caseId) async {
    return await get_case.getCase(
      client: client,
      baseUrl: _baseUrl,
      caseId: caseId,
    );
  }

  Future<CaseStatus> getCaseStatus(String caseId) async {
    return await get_status.getCaseStatus(
      client: client,
      baseUrl: _baseUrl,
      caseId: caseId,
    );
  }

  Future<Map<String, dynamic>> getCaseReport(String caseId) async {
    return await get_report.getCaseReport(
      client: client,
      baseUrl: _baseUrl,
      caseId: caseId,
    );
  }

  void dispose() {
    client.close();
  }
}
