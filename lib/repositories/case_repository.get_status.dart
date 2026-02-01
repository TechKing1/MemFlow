import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/case_model.dart';

Future<CaseStatus> getCaseStatus({
  required http.Client client,
  required String baseUrl,
  required String caseId,
}) async {
  try {
    final response = await client.get(
      Uri.parse('$baseUrl/api/cases/$caseId/status'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch case status: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    // Backend doesn't provide 'progress' field yet, so add a default value
    if (!jsonData.containsKey('progress')) {
      jsonData['progress'] = 0;
    }
    return CaseStatus.fromJson(jsonData);
  } catch (e) {
    throw Exception('Failed to get case status: $e');
  }
}
