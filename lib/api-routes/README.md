# API Routes Documentation

This directory contains API route integration files for each screen in the MemForensics Flutter application.

## Directory Structure

```
api-routes/
├── upload/
│   └── upload_api_routes.dart      # Upload screen API routes
├── dashboard/
│   └── dashboard_api_routes.dart   # Dashboard screen API routes
├── reports/
│   └── reports_api_routes.dart     # Reports screen API routes
└── settings/
    └── settings_api_routes.dart    # Settings screen API routes (placeholder)
```

## Available API Routes

### Upload Screen
- **POST /upload** - Upload memory dump and create case
  - File: `upload/upload_api_routes.dart`
  - Method: `UploadApiRoutes.uploadCase()`
  - Status: ✅ Ready to integrate

### Dashboard Screen
- **GET /<case_id>** - Get case details by ID
  - File: `dashboard/dashboard_api_routes.dart`
  - Method: `DashboardApiRoutes.getCaseById()`
  - Status: ✅ Ready to integrate

- **GET /<case_id>/status** - Get case processing status
  - File: `dashboard/dashboard_api_routes.dart`
  - Method: `DashboardApiRoutes.getCaseStatus()`
  - Status: ✅ Ready to integrate

### Reports Screen
- **GET /<case_id>/report** - Get analysis report
  - File: `reports/reports_api_routes.dart`
  - Method: `ReportsApiRoutes.getCaseReport()`
  - Status: ✅ Ready to integrate (placeholder data)

- **GET /<case_id>** - Get case details
  - File: `reports/reports_api_routes.dart`
  - Method: `ReportsApiRoutes.getCaseDetails()`
  - Status: ✅ Ready to integrate

### Settings Screen
- No endpoints available yet
  - File: `settings/settings_api_routes.dart`
  - Status: ⏳ Waiting for backend implementation

## Configuration

Update the `baseUrl` in each API routes file to match your backend server:

```dart
static const String baseUrl = 'http://localhost:5000/cases';
```

For production, you might want to use environment variables or a config file.

## Dependencies

Add the `http` package to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
```

Then run:
```bash
flutter pub get
```

## Usage Example

### Upload a Case

```dart
import 'package:memoryforensics/api-routes/upload/upload_api_routes.dart';
import 'dart:io';

Future<void> uploadMemoryDump() async {
  try {
    final file = File('/path/to/memory_dump.raw');
    final result = await UploadApiRoutes.uploadCase(
      file: file,
      name: 'Suspicious Activity Investigation',
      description: 'Memory dump from compromised workstation',
      priority: 8,
    );
    
    print('Case created: ${result['case']['id']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Get Case Status

```dart
import 'package:memoryforensics/api-routes/dashboard/dashboard_api_routes.dart';

Future<void> checkCaseStatus(int caseId) async {
  try {
    final status = await DashboardApiRoutes.getCaseStatus(caseId);
    print('Status: ${status['status']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Get Case Report

```dart
import 'package:memoryforensics/api-routes/reports/reports_api_routes.dart';

Future<void> fetchReport(int caseId) async {
  try {
    final report = await ReportsApiRoutes.getCaseReport(caseId);
    print('Indicators found: ${report['report']['analysis']['indicators_found']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

## Future Endpoints (TODO)

The following endpoints are marked as TODO and will be added when the backend is ready:

### Dashboard
- `GET /cases` - List all cases with filters
- `DELETE /<case_id>` - Delete a case
- `GET /<case_id>/download` - Download case file

### Reports
- `GET /<case_id>/report/pdf` - Export report as PDF
- `GET /<case_id>/report/json` - Export report as JSON
- `GET /<case_id>/artifacts` - Download analysis artifacts

### Settings
- `GET /settings` - Get user settings
- `PUT /settings` - Update user settings
- `GET /profiles` - Get analysis profiles
- `POST /profiles` - Create custom profile
- `PUT /profiles/<id>` - Update profile
- `DELETE /profiles/<id>` - Delete profile

## Notes

- All API routes include comprehensive documentation with example responses
- Error handling is implemented for common HTTP status codes
- The backend currently returns placeholder data for analysis results
- Real memory analysis will be implemented in future updates
