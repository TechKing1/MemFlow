import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<String> uploadCase({
  required http.Client client,
  required String baseUrl,
  required File file,
  required String caseName,
  String? description,
}) async {
  try {
    // Get file extension and check if it's supported
    // Must match backend's ALLOWED_EXTENSIONS in app/routes/cases.py
    final fileExtension = file.path.split('.').last.toLowerCase();
    final supportedExtensions = ['raw', 'mem', 'vmem', 'bin'];

    if (!supportedExtensions.contains(fileExtension)) {
      throw Exception(
        'Unsupported file type. Please upload a memory dump file (.raw, .mem, .vmem, .bin)',
      );
    }

    final uri = Uri.parse('$baseUrl/api/cases/upload');
    final request = http.MultipartRequest('POST', uri);

    // Add the file
    final fileStream = http.ByteStream(file.openRead());
    final fileLength = await file.length();

    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: file.path.split(Platform.pathSeparator).last,
    );

    request.files.add(multipartFile);
    request.fields['name'] = caseName;

    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }

    request.headers['Accept'] = 'application/json';

    final response = await client.send(request);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode >= 400) {
      throw Exception(
        'Failed to upload case: ${response.statusCode} - $responseBody',
      );
    }

    try {
      // Parse the JSON response
      final jsonResponse = jsonDecode(responseBody);

      // Extract the case ID from the response
      if (jsonResponse is Map &&
          jsonResponse['case'] is Map &&
          jsonResponse['case']['id'] != null) {
        return jsonResponse['case']['id'].toString();
      } else {
        throw Exception('Invalid response format: missing case ID');
      }
    } catch (e) {
      throw Exception('Failed to parse server response: $e');
    }
  } catch (e) {
    print('Error in uploadCase: $e');
    throw Exception('Failed to upload case: $e');
  }
}
