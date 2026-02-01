import 'package:http/http.dart' as http;
import 'dart:convert';

/// API routes for Dashboard Screen
/// Base URL for the backend API
class DashboardApiRoutes {
  // Base URL - Update this with your actual backend URL
  static const String baseUrl = 'http://localhost:5000/api/cases';

  /// Get list of all cases with optional filtering and pagination
  ///
  /// Endpoint: GET /
  ///
  /// Parameters:
  /// - status: String? - Filter by case status (queued, processing, completed, failed)
  /// - page: int - Page number for pagination (default: 1)
  /// - limit: int - Number of cases per page (default: 10, max: 100)
  ///
  /// Returns:
  /// - 200: List of cases with pagination info
  /// - 500: Server error
  ///
  /// Example Response:
  /// ```json
  /// {
  ///   "cases": [
  ///     {
  ///       "id": 1,
  ///       "name": "Investigation Case",
  ///       "description": "Memory dump analysis",
  ///       "status": "completed",
  ///       "priority": 8,
  ///       "created_at": "2024-01-26T10:15:30",
  ///       "updated_at": "2024-01-26T10:20:30",
  ///       "metadata": {...},
  ///       "files": [...]
  ///     }
  ///   ],
  ///   "pagination": {
  ///     "page": 1,
  ///     "limit": 10,
  ///     "total": 25,
  ///     "pages": 3,
  ///     "has_next": true,
  ///     "has_prev": false
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> getAllCases({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get cases: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching cases: $e');
    }
  }

  /// Get case details by ID
  ///
  /// Endpoint: GET /<case_id>
  ///
  /// Parameters:
  /// - caseId: int - ID of the case to retrieve
  ///
  /// Returns:
  /// - 200: Case details
  /// - 404: Case not found
  ///
  /// Example Response:
  /// ```json
  /// {
  ///   "case": {
  ///     "id": 1,
  ///     "name": "Suspicious Activity Investigation",
  ///     "description": "Memory dump from compromised workstation",
  ///     "status": "queued",
  ///     "priority": 8,
  ///     "created_at": "2024-01-26T10:15:30",
  ///     "updated_at": "2024-01-26T10:15:30",
  ///     "metadata": {
  ///       "original_filename": "memory_dump.raw"
  ///     },
  ///     "files": [...]
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> getCaseById(int caseId) async {
    final uri = Uri.parse('$baseUrl/$caseId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Case not found');
      } else {
        throw Exception('Failed to get case: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching case: $e');
    }
  }

  /// Get processing status of a case
  ///
  /// Endpoint: GET /<case_id>/status
  ///
  /// Parameters:
  /// - caseId: int - ID of the case
  ///
  /// Returns:
  /// - 200: Case status
  /// - 404: Case not found
  ///
  /// Example Response:
  /// ```json
  /// {
  ///   "case_id": 1,
  ///   "status": "processing",
  ///   "updated_at": "2024-01-26T10:20:30"
  /// }
  /// ```
  static Future<Map<String, dynamic>> getCaseStatus(int caseId) async {
    final uri = Uri.parse('$baseUrl/$caseId/status');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Case not found');
      } else {
        throw Exception('Failed to get case status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching case status: $e');
    }
  }

  // TODO: Add these endpoints when backend is ready
  //
  // /// Delete a case by ID
  // /// Endpoint: DELETE /<case_id>
  // static Future<void> deleteCase(int caseId) async {
  //   // Implementation pending backend endpoint
  // }
  //
  // /// Download case file
  // /// Endpoint: GET /<case_id>/download
  // static Future<void> downloadCaseFile(int caseId) async {
  //   // Implementation pending backend endpoint
  // }
}
