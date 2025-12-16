# Code Snippets & Examples

## Quick Reference for Developers

---

## 📦 Project Setup

### 1. Get Dependencies
```bash
flutter pub get
```

### 2. Run on Windows
```bash
flutter run -d windows
```

### 3. Run on macOS
```bash
flutter run -d macos
```

### 4. Run on Linux
```bash
flutter run -d linux
```

---

## 🔧 Key Code Sections

### Main Application Entry Point
```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Forensics Automation Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
```

### Dashboard State Variables
```dart
class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isHovering = false;

  final List<String> _supportedExtensions = ['.raw', '.mem', '.vmem', '.bin'];
  
  // ... rest of code
}
```

### File Picker Implementation
```dart
Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['raw', 'mem', 'vmem', 'bin'],
      dialogTitle: 'Select Memory Dump File',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path!;
        _selectedFileName = result.files.single.name;
      });
      _onFileSelected();
    }
  } catch (e) {
    _showErrorDialog('Error picking file: $e');
  }
}
```

### Drag & Drop Implementation
```dart
DropTarget(
  onDragEntered: (details) {
    setState(() {
      _isHovering = true;
    });
  },
  onDragExited: (details) {
    setState(() {
      _isHovering = false;
    });
  },
  onDragDone: (details) {
    setState(() {
      _isHovering = false;
    });

    if (details.files.isNotEmpty) {
      final file = details.files.first;
      final fileName = file.name;
      final fileExtension = '.' + fileName.split('.').last.toLowerCase();

      if (_supportedExtensions.contains(fileExtension)) {
        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = fileName;
        });
        _onFileSelected();
      } else {
        _showErrorDialog(
          'Unsupported file type: $fileExtension\n\n'
          'Supported formats: ${_supportedExtensions.join(", ")}',
        );
      }
    }
  },
  child: // ... UI widget
)
```

### Error Dialog
```dart
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
```

### Upload Card Widget
```dart
Widget _buildUploadCard() {
  return DropTarget(
    onDragEntered: (details) {
      setState(() {
        _isHovering = true;
      });
    },
    onDragExited: (details) {
      setState(() {
        _isHovering = false;
      });
    },
    onDragDone: (details) {
      // Handle file drop
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isHovering ? const Color(0xFFEFF6FF) : Colors.white,
        border: Border.all(
          color: _isHovering
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: _isHovering ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isHovering
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: _isHovering
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Drag and drop your file here',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Supported formats: ${_supportedExtensions.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 24),
            // Or text
            Text(
              'or',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
            ),
            const SizedBox(height: 24),
            // Browse button
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse Dump File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Selected File Info Widget
```dart
Widget _buildSelectedFileInfo() {
  return Container(
    width: 500,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      border: Border.all(color: const Color(0xFFBBF7D0)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF16A34A),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFileName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF15803D),
                          overflow: TextOverflow.ellipsis,
                        ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Path: $_selectedFilePath',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF15803D),
                overflow: TextOverflow.ellipsis,
              ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _pickFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Select Different File'),
          ),
        ),
      ],
    ),
  );
}
```

---

## 🔌 Backend Integration Template

### Add HTTP Dependency
```yaml
dependencies:
  http: ^1.1.0
```

### File Upload Function (Template)
```dart
Future<void> _uploadFileToBackend() async {
  // TODO: Implement backend API call
  
  final uri = Uri.parse('http://localhost:5000/api/upload');
  
  try {
    var request = http.MultipartRequest('POST', uri);
    
    // Add file to request
    request.files.add(
      await http.MultipartFile.fromPath('file', _selectedFilePath!),
    );
    
    // Send request
    var response = await request.send();
    
    if (response.statusCode == 200) {
      // Handle success
      print('File uploaded successfully');
      // TODO: Navigate to results screen
    } else {
      // Handle error
      _showErrorDialog('Upload failed: ${response.statusCode}');
    }
  } catch (e) {
    _showErrorDialog('Error uploading file: $e');
  }
}
```

### Update _onFileSelected() for Backend
```dart
void _onFileSelected() {
  // TODO: connect to backend API later
  // Uncomment when backend is ready:
  // _uploadFileToBackend();
  
  print('File selected: $_selectedFileName');
  print('File path: $_selectedFilePath');
}
```

---

## 🎨 Color Constants

```dart
// Primary Colors
const Color primaryBlue = Color(0xFF2563EB);
const Color successGreen = Color(0xFF16A34A);
const Color lightBackground = Color(0xFFF8FAFC);

// Text Colors
const Color darkText = Color(0xFF1E293B);
const Color lightText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);

// Border & Hover Colors
const Color lightBorder = Color(0xFFE2E8F0);
const Color hoverBlueBg = Color(0xFFEFF6FF);
const Color hoverBlueBorder = Color(0xFF2563EB);
const Color successBg = Color(0xFFF0FDF4);
const Color successBorder = Color(0xFFBBF7D0);
```

---

## 📐 Spacing Constants

```dart
// Spacing system (8px grid)
const double spacingXs = 4;    // Half grid
const double spacingSm = 8;    // 1 grid
const double spacingMd = 16;   // 2 grids
const double spacingLg = 24;   // 3 grids
const double spacingXl = 32;   // 4 grids
const double spacing2xl = 48;  // 6 grids
const double spacing3xl = 60;  // 7.5 grids
```

---

## 🧪 Testing Code

### Test File Picker
```dart
void _testFilePicker() {
  print('Testing file picker...');
  _pickFile();
}
```

### Test Drag & Drop
```dart
void _testDragDrop() {
  print('Testing drag & drop...');
  print('Hover state: $_isHovering');
}
```

### Test File Validation
```dart
void _testFileValidation(String filePath) {
  final fileName = filePath.split('/').last;
  final fileExtension = '.' + fileName.split('.').last.toLowerCase();
  
  if (_supportedExtensions.contains(fileExtension)) {
    print('✓ File is valid: $fileName');
  } else {
    print('✗ File is invalid: $fileName');
  }
}
```

---

## 🐛 Debugging

### Enable Debug Logging
```dart
void _onFileSelected() {
  print('DEBUG: File selected: $_selectedFileName');
  print('DEBUG: File path: $_selectedFilePath');
  print('DEBUG: File size: ${File(_selectedFilePath!).lengthSync()} bytes');
}
```

### Check Hover State
```dart
void _debugHoverState() {
  print('Hover state: $_isHovering');
}
```

### List Supported Formats
```dart
void _debugSupportedFormats() {
  print('Supported formats: $_supportedExtensions');
}
```

---

## 📱 Responsive Design

### Adapt to Screen Size
```dart
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final cardWidth = screenWidth > 600 ? 500.0 : screenWidth - 48;
  
  return Container(
    width: cardWidth,
    // ... rest of widget
  );
}
```

### Adapt to Orientation
```dart
final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

if (isPortrait) {
  // Portrait layout
} else {
  // Landscape layout
}
```

---

## 🎯 Common Tasks

### Change Primary Color
```dart
// In MyApp theme
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF3B82F6), // Change this
  brightness: Brightness.light,
),
```

### Change Upload Card Size
```dart
// In _buildUploadCard()
child: Container(
  width: 600, // Change this
  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
  // ...
)
```

### Add Loading Indicator
```dart
if (_isLoading) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}
```

### Add Progress Bar
```dart
LinearProgressIndicator(
  value: _uploadProgress,
  minHeight: 4,
)
```

---

## 📚 Useful Resources

### Flutter Documentation
- [Flutter Widgets](https://flutter.dev/docs/development/ui/widgets)
- [Material Design](https://material.io/design)
- [Flutter Packages](https://pub.dev)

### Packages Used
- [file_picker](https://pub.dev/packages/file_picker)
- [desktop_drop](https://pub.dev/packages/desktop_drop)

### Learning Resources
- [Flutter Codelab](https://codelabs.developers.google.com/codelabs/flutter)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## ✅ Checklist for Modifications

- [ ] Update color constants if changing theme
- [ ] Update spacing constants if changing layout
- [ ] Test on all platforms after changes
- [ ] Update documentation
- [ ] Run `flutter analyze` for lint errors
- [ ] Test file picker functionality
- [ ] Test drag-and-drop functionality
- [ ] Verify error handling

---

**Last Updated**: November 29, 2025
**Version**: 1.0
**Status**: Complete
