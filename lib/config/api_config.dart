/// API Configuration
///
/// Centralized configuration for API endpoints and settings

class ApiConfig {
  // Base URL for the backend API
  // TODO: Update this for production deployment
  static const String baseUrl = 'http://localhost:5000';

  // API endpoints
  static const String casesEndpoint = '$baseUrl/api/cases';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Allowed file extensions for memory dumps
  static const List<String> allowedFileExtensions = [
    'raw',
    'mem',
    'vmem',
    'bin',
  ];

  // Maximum file size (in bytes) - 10GB
  static const int maxFileSize = 10 * 1024 * 1024 * 1024;

  // Pagination defaults
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  /// Check if a file extension is allowed
  static bool isValidFileExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedFileExtensions.contains(extension);
  }

  /// Format file size to human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
