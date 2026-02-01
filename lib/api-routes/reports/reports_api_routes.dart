import 'package:http/http.dart' as http;
import 'dart:convert';

/// API routes for Reports Screen
/// Base URL for the backend API
class ReportsApiRoutes {
  // Base URL - Update this with your actual backend URL
  static const String baseUrl = 'http://localhost:5000/api/cases';

  /// Get analysis report for a case
  ///
  /// Endpoint: GET /<case_id>/report
  ///
  /// Parameters:
  /// - caseId: int - ID of the case
  ///
  /// Returns:
  /// - 200: Case report with analysis data
  /// - 404: Case not found
  ///
  /// Example Response:
  /// ```json
  /// {
  ///   "case_id": 1,
  ///   "status": "completed",
  ///   "report": {
  ///     "summary": "Analysis completed successfully",
  ///     "analysis_date": "2024-01-26T10:30:00",
  ///     "file_info": {
  ///       "original_filename": "memory_dump.raw",
  ///       "file_size": 4294967296,
  ///       "checksum": "abc123...",
  ///       "stored_at": "2024-01-26T10:15:30"
  ///     },
  ///     "analysis": {
  ///       "indicators_found": 0,
  ///       "processes_analyzed": 0,
  ///       "network_connections": [],
  ///       "artifacts_found": []
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Note: Currently returns placeholder data. Real analysis will be implemented
  /// in a future update.
  static Future<Map<String, dynamic>> getCaseReport(int caseId) async {
    final uri = Uri.parse('$baseUrl/$caseId/report');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Case not found');
      } else {
        throw Exception('Failed to get case report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching case report: $e');
    }
  }

  /// Get case details (reusing from dashboard routes for convenience)
  ///
  /// Endpoint: GET /<case_id>
  ///
  /// This is useful for getting case metadata to display in the report header
  static Future<Map<String, dynamic>> getCaseDetails(int caseId) async {
    final uri = Uri.parse('$baseUrl/$caseId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Case not found');
      } else {
        throw Exception('Failed to get case details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching case details: $e');
    }
  }

  // TODO: Add these endpoints when backend implements real analysis
  //
  // /// Export report as PDF
  // /// Endpoint: GET /<case_id>/report/pdf
  // static Future<void> exportReportAsPdf(int caseId) async {
  //   // Implementation pending backend endpoint
  // }
  //
  // /// Export report as JSON
  // /// Endpoint: GET /<case_id>/report/json
  // static Future<Map<String, dynamic>> exportReportAsJson(int caseId) async {
  //   // Implementation pending backend endpoint
  // }
  //
  // /// Download analysis artifacts
  // /// Endpoint: GET /<case_id>/artifacts
  // static Future<void> downloadArtifacts(int caseId) async {
  //   // Implementation pending backend endpoint
  // }
}
