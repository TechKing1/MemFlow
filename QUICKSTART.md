# Quick Start Guide - Memory Forensics Automation Tool

## 🚀 Get Started in 3 Steps

### Step 1: Install Dependencies
```bash
cd c:\Users\oem\StudioProjects\memoryforensics
flutter pub get
```

### Step 2: Run the Application
```bash
flutter run -d windows
```

For macOS:
```bash
flutter run -d macos
```

For Linux:
```bash
flutter run -d linux
```

### Step 3: Test the Features
1. **Drag & Drop**: Try dragging a `.raw`, `.mem`, `.vmem`, or `.bin` file onto the drop zone
2. **Browse**: Click "Browse Dump File" to select a file using the file picker
3. **Verify**: The app displays the selected file name and path

## 📁 File Structure

```
lib/
└── main.dart                 # Complete dashboard UI (all-in-one file)
pubspec.yaml                  # Dependencies configuration
README.md                     # Full documentation
QUICKSTART.md                 # This file
```

## ✨ Key Features Implemented

✅ **Clean, Modern Dashboard**
- Centered layout optimized for desktop screens
- Professional light theme with blue accents
- Responsive design

✅ **Drag & Drop Zone**
- Visual feedback on hover (color change + border highlight)
- Accepts `.raw`, `.mem`, `.vmem`, `.bin` files
- Error handling for unsupported formats

✅ **File Browser**
- Native file picker dialog
- Filters for supported memory dump formats
- Works on Windows, macOS, and Linux

✅ **File Selection Display**
- Shows selected file name
- Displays full file path
- Option to select a different file
- Green success indicator

## 🎨 UI Components

### Main Dashboard
- **AppBar**: Logo + title with memory icon
- **Upload Card**: Drag-and-drop zone with visual feedback
- **Browse Button**: Opens native file picker
- **Selected File Info**: Green confirmation card with file details

## 🔧 Code Organization

All code is in `lib/main.dart`:

- `MyApp`: Root widget with theme configuration
- `DashboardScreen`: Main stateful widget
- `_DashboardScreenState`: State management for file selection
  - `_pickFile()`: File picker logic
  - `_onFileSelected()`: Callback (placeholder for backend)
  - `_buildUploadCard()`: Drag-and-drop UI
  - `_buildSelectedFileInfo()`: File confirmation UI

## 📝 TODO: Backend Integration

When ready to connect to Flask backend, update `_onFileSelected()` method:

```dart
void _onFileSelected() {
  // TODO: connect to backend API later
  // Example:
  // - Send file to Flask API
  // - Show loading indicator
  // - Handle response
}
```

## 🐛 Troubleshooting

**Dependencies not found?**
```bash
flutter pub get
flutter pub upgrade
```

**Build errors?**
```bash
flutter clean
flutter pub get
flutter run -d windows
```

**Drag-and-drop not working?**
- Ensure the app window has focus
- Try dragging from file explorer

**File picker not opening?**
- Check platform-specific permissions
- Verify `file_picker` package is installed

## 📦 Dependencies Used

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | sdk | Core framework |
| file_picker | ^8.1.0 | Native file picker |
| desktop_drop | ^0.4.4 | Drag & drop support |
| cupertino_icons | ^1.0.8 | Icon set |

## 🎯 Next Steps

1. Test the UI on your target platform (Windows/macOS/Linux)
2. Verify drag-and-drop and file picker work correctly
3. When ready, implement backend API integration in `_onFileSelected()`
4. Add progress indicators for file upload
5. Implement analysis results display

## 💡 Tips

- Use `flutter run -d windows --debug` for debugging
- Use `flutter run -d windows --release` for performance testing
- Check console output for file path logging
- Hot reload works for UI changes (press `r` in terminal)

---

**Status**: ✅ Frontend complete and ready to run
**Next**: Backend API integration when Flask backend is ready
