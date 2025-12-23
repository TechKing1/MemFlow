# Memory Forensics Automation Tool

A modern Flutter Desktop application for memory dump analysis and forensics automation.

## Features

- **Clean, Modern Dashboard**: Optimized for large desktop screens (Windows, macOS, Linux)
- **Drag & Drop Support**: Drag memory dump files directly onto the drop zone
- **File Browser**: Browse and select memory dump files using native file picker
- **Supported Formats**: `.raw`, `.mem`, `.vmem`, `.bin`
- **Real-time Feedback**: Visual feedback on hover and file selection
- **Light Theme**: Clean, professional UI with blue accent colors
  
## Status
Active development — core modules under construction.

## Project Structure

```
lib/
├── main.dart              # Main application entry point and dashboard UI
pubspec.yaml              # Project dependencies
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.10.1 or higher)
- Dart SDK (included with Flutter)
- A desktop platform: Windows, macOS, or Linux

### Installation

1. **Clone or navigate to the project directory**:
   ```bash
   cd c:\Users\oem\StudioProjects\memoryforensics
   ```

2. **Get Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Enable desktop support** (if not already enabled):
   ```bash
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   flutter config --enable-linux-desktop
   ```

## Running the Application

### Windows

```bash
flutter run -d windows
```

### macOS

```bash
flutter run -d macos
```

### Linux

```bash
flutter run -d linux
```

### Build for Release

**Windows**:
```bash
flutter build windows --release
```

**macOS**:
```bash
flutter build macos --release
```

**Linux**:
```bash
flutter build linux --release
```

## Usage

1. **Launch the application** - The dashboard opens with a centered upload card
2. **Upload a file** - Choose one of two methods:
   - **Drag & Drop**: Drag a memory dump file onto the drop zone (the zone highlights on hover)
   - **Browse**: Click "Browse Dump File" button to open a native file picker
3. **File Selection**: After selecting a file, the app displays:
   - File name
   - Full file path
   - Option to select a different file

## Supported File Formats

- `.raw` - Raw memory dump
- `.mem` - Memory dump file
- `.vmem` - Virtual machine memory dump
- `.bin` - Binary memory dump

## Dependencies

- **file_picker** (^8.1.0): Native file picker for desktop platforms
- **desktop_drop** (^0.4.4): Drag & drop support for desktop
- **flutter**: Core Flutter framework
- **cupertino_icons**: Icon set

## Architecture

### DashboardScreen (StatefulWidget)
Main dashboard screen managing:
- File selection state
- Hover state for drag-and-drop
- UI rendering and user interactions

### Key Methods

- `_pickFile()`: Opens native file picker dialog
- `_onFileSelected()`: Callback when file is selected (placeholder for backend integration)
- `_buildUploadCard()`: Renders the drag-and-drop upload area
- `_buildSelectedFileInfo()`: Displays selected file information

## Future Integration

The application includes TODO comments for backend integration:
- `_onFileSelected()` in `main.dart` - This is where you'll connect to the Flask backend API
- File upload logic will be implemented here

## Color Scheme

- **Primary Blue**: `#2563EB` - Main accent color
- **Success Green**: `#16A34A` - File selection confirmation
- **Background**: `#F8FAFC` - Light slate background
- **Text Dark**: `#1E293B` - Primary text
- **Text Light**: `#64748B` - Secondary text

## Notes

- The application is **frontend-only** at this stage
- No backend API calls are implemented yet
- File paths are logged to console for debugging
- All UI is responsive and optimized for desktop screens

## Troubleshooting

### File picker not working
- Ensure `file_picker` package is properly installed: `flutter pub get`
- Check that the platform-specific permissions are configured

### Drag-and-drop not working
- Verify `desktop_drop` package is installed
- Ensure the app window has focus when dragging files

### Build errors
- Run `flutter clean` and then `flutter pub get`
- Check that your Flutter SDK is up to date: `flutter upgrade`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

## License
MIT License
>>>>>>> d6209ec05745d015038bd208ea65ab52fa355c85


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
