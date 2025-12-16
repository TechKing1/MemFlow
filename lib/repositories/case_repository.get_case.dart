import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/case_model.dart';

Future<CaseModel> getCase({
  required http.Client client,
  required String baseUrl,
  required String caseId,
}) async {
  try {
    final response = await client.get(
      Uri.parse('$baseUrl/api/cases/$caseId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch case: ${response.statusCode}');
    }
    
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return CaseModel.fromJson(jsonData);
  } catch (e) {
    throw Exception('Failed to get case: $e');
  }
}
