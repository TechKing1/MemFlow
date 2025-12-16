import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getCaseReport({
  required http.Client client,
  required String baseUrl,
  required String caseId,
}) async {
  try {
    final response = await client.get(
      Uri.parse('$baseUrl/api/cases/$caseId/report'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch case report: ${response.statusCode}');
    }
    
    return jsonDecode(response.body) as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Failed to get case report: $e');
  }
}
