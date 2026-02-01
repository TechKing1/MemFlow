import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// API routes for Upload Screen
/// Base URL for the backend API
class UploadApiRoutes {
  // Base URL - Update this with your actual backend URL
  static const String baseUrl = 'http://localhost:5000/api/cases';

  /// Upload a memory dump file and create a new case
  ///
  /// Endpoint: POST /upload
  ///
  /// Parameters:
  /// - file: File - The memory dump file to upload (raw, mem, vmem, bin)
  /// - name: String - Name for the case (required)
  /// - description: String - Optional case description
  /// - priority: int - Priority of the case (1-10, default 5)
  ///
  /// Returns:
  /// - 201: Case created successfully with case details
  /// - 400: Invalid file or missing parameters
  /// - 500: Server error
  ///
  /// Example Response:
  /// ```json
  /// {
  ///   "message": "Case created successfully",
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
  ///     "files": [
  ///       {
  ///         "id": 1,
  ///         "case_id": 1,
  ///         "file_path": "/uploads/1/raw.raw",
  ///         "file_size": 4294967296,
  ///         "checksum": "abc123...",
  ///         "mime_type": "application/octet-stream",
  ///         "stored_at": "2024-01-26T10:15:30"
  ///       }
  ///     ]
  ///   }
  /// }
  /// ```
  static Future<Map<String, dynamic>> uploadCase({
    required File file,
    required String name,
    String? description,
    int priority = 5,
  }) async {
    final uri = Uri.parse('$baseUrl/upload');

    var request = http.MultipartRequest('POST', uri);

    // Add file
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // Add form fields
    request.fields['name'] = name;
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    request.fields['priority'] = priority.toString();

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload case: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading case: $e');
    }
  }

  /// Allowed file extensions for memory dumps
  static const List<String> allowedExtensions = ['raw', 'mem', 'vmem', 'bin'];

  /// Check if a file has an allowed extension
  static bool isValidFileExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }
}
