# UI Reference Guide - Memory Forensics Automation Tool

## 🎨 Visual Layout

### Main Dashboard Screen

```
┌─────────────────────────────────────────────────────────────┐
│  🧠 Memory Forensics Automation Tool                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│                                                               │
│                    Upload Memory Dump                         │
│          Drag and drop your memory dump file or              │
│              browse to select one                            │
│                                                               │
│                                                               │
│        ┌──────────────────────────────────────┐              │
│        │                                      │              │
│        │        ☁️  (Cloud Upload Icon)       │              │
│        │                                      │              │
│        │  Drag and drop your file here        │              │
│        │  Supported formats: .raw, .mem,      │              │
│        │                    .vmem, .bin       │              │
│        │                                      │              │
│        │              or                      │              │
│        │                                      │              │
│        │  ┌──────────────────────────────┐   │              │
│        │  │  📁 Browse Dump File         │   │              │
│        │  └──────────────────────────────┘   │              │
│        │                                      │              │
│        └──────────────────────────────────────┘              │
│                                                               │
│                                                               │
│        ┌──────────────────────────────────────┐              │
│        │ ✓ File Selected                      │              │
│        │   example_dump.raw                   │              │
│        │                                      │              │
│        │ Path: /path/to/example_dump.raw      │              │
│        │                                      │              │
│        │ ┌──────────────────────────────────┐ │              │
│        │ │ Select Different File            │ │              │
│        │ └──────────────────────────────────┘ │              │
│        └──────────────────────────────────────┘              │
│                                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Component Breakdown

### 1. AppBar (Header)
```
┌─────────────────────────────────────────────────────────────┐
│  🧠 Memory Forensics Automation Tool                         │
└─────────────────────────────────────────────────────────────┘
```
- **Icon**: Memory chip icon (Material Icons)
- **Color**: Blue (#2563EB) background
- **Text**: White, 20pt, bold
- **Spacing**: 12px between icon and text

### 2. Upload Card (Drag & Drop Zone)
```
        ┌──────────────────────────────────────┐
        │                                      │
        │        ☁️  (Cloud Upload Icon)       │
        │                                      │
        │  Drag and drop your file here        │
        │  Supported formats: .raw, .mem,      │
        │                    .vmem, .bin       │
        │                                      │
        │              or                      │
        │                                      │
        │  ┌──────────────────────────────┐   │
        │  │  📁 Browse Dump File         │   │
        │  └──────────────────────────────┘   │
        │                                      │
        └──────────────────────────────────────┘
```

**Dimensions**:
- Width: 500px
- Padding: 60px vertical, 40px horizontal
- Border Radius: 16px

**States**:
- **Normal**: White background, light gray border
- **Hover**: Light blue background, blue border (2px)
- **Animation**: 200ms smooth transition

**Content**:
- Icon: 80x80px, cloud upload icon
- Title: "Drag and drop your file here"
- Subtitle: "Supported formats: .raw, .mem, .vmem, .bin"
- Button: "Browse Dump File" (blue, 32x16px padding)

### 3. Selected File Info Card
```
        ┌──────────────────────────────────────┐
        │ ✓ File Selected                      │
        │   example_dump.raw                   │
        │                                      │
        │ Path: /path/to/example_dump.raw      │
        │                                      │
        │ ┌──────────────────────────────────┐ │
        │ │ Select Different File            │ │
        │ └──────────────────────────────────┘ │
        └──────────────────────────────────────┘
```

**Dimensions**:
- Width: 500px
- Padding: 20px all sides
- Border Radius: 12px

**Colors**:
- Background: Light green (#F0FDF4)
- Border: Green (#BBF7D0)
- Text: Dark green (#15803D)

**Content**:
- Icon: 48x48px, check circle (green)
- Title: "File Selected" (bold, dark green)
- File Name: Displayed with ellipsis
- Path: Full file path with ellipsis
- Button: "Select Different File" (green, full width)

---

## 🎨 Color Palette

### Primary Colors
```
Primary Blue:     #2563EB  ████████████████████
Success Green:    #16A34A  ████████████████████
Background:       #F8FAFC  ████████████████████
```

### Text Colors
```
Dark Text:        #1E293B  ████████████████████
Light Text:       #64748B  ████████████████████
Muted Text:       #94A3B8  ████████████████████
```

### Border & Hover Colors
```
Light Border:     #E2E8F0  ████████████████████
Hover Blue BG:    #EFF6FF  ████████████████████
Hover Blue Border:#2563EB  ████████████████████
Success BG:       #F0FDF4  ████████████████████
Success Border:   #BBF7D0  ████████████████████
```

---

## 📐 Spacing System

All spacing follows an 8px grid:

```
Micro:    4px   (half grid)
Small:    8px   (1 grid)
Medium:   16px  (2 grids)
Large:    24px  (3 grids)
XL:       32px  (4 grids)
2XL:      48px  (6 grids)
3XL:      60px  (7.5 grids)
```

### Applied Spacing
- **AppBar**: 12px between icon and text
- **Main padding**: 24px
- **Card padding**: 20-60px
- **Element spacing**: 8-24px
- **Button padding**: 16px vertical, 32px horizontal

---

## 🔤 Typography

### Font Sizes
```
Headline Medium:  32px, bold (#1E293B)
Title Large:      20px, semi-bold (#1E293B)
Title Medium:     16px, semi-bold (#166534 for success)
Body Large:       16px, regular (#64748B)
Body Medium:      14px, regular (#15803D for success)
Body Small:       12px, regular (#15803D for success)
```

### Font Weights
- **Bold**: 700 (Headlines)
- **Semi-bold**: 600 (Titles)
- **Regular**: 400 (Body text)

---

## 🎬 Animations

### Hover Effects
- **Duration**: 200ms
- **Curve**: Linear
- **Properties**:
  - Background color change
  - Border color change
  - Border width change (1.5px → 2px)

### Transitions
- **Upload Card**: Smooth color/border transition on hover
- **Icon Color**: Changes with background
- **Button**: Standard Material elevation on hover

---

## 🖱️ Interactive Elements

### Buttons

#### Browse Dump File (Primary)
```
┌──────────────────────────────────────┐
│  📁 Browse Dump File                 │
└──────────────────────────────────────┘
```
- **Background**: Blue (#2563EB)
- **Text**: White
- **Icon**: Folder open
- **Padding**: 16px vertical, 32px horizontal
- **Border Radius**: 8px
- **Action**: Opens file picker

#### Select Different File (Secondary)
```
┌──────────────────────────────────────┐
│ Select Different File                │
└──────────────────────────────────────┘
```
- **Background**: Green (#16A34A)
- **Text**: White
- **Padding**: 12px vertical, full width
- **Border Radius**: 8px
- **Action**: Opens file picker again

### Drag & Drop Zone
- **Hover State**: Background changes to light blue, border becomes blue
- **Drop State**: File is processed and validated
- **Error State**: Error dialog appears for unsupported formats

---

## 📱 Responsive Behavior

### Desktop (Large Screens)
- **Layout**: Centered, single column
- **Card Width**: 500px
- **Padding**: 24px all sides
- **Scrollable**: Yes (for very small windows)

### Adaptations
- **Very Small Windows**: Content scrolls vertically
- **Very Large Screens**: Content remains centered
- **Landscape**: Optimal layout maintained

---

## 🎯 User Interaction Flow

### Drag & Drop Flow
```
1. User hovers over drop zone
   ↓ Zone highlights (light blue)
   
2. User drags file over zone
   ↓ Zone remains highlighted
   
3. User drops file
   ↓ File validated
   ↓ If valid: Display file info card
   ↓ If invalid: Show error dialog
```

### Browse Flow
```
1. User clicks "Browse Dump File"
   ↓ Native file picker opens
   
2. User selects file
   ↓ File validated
   ↓ If valid: Display file info card
   ↓ If invalid: Show error dialog
```

### File Change Flow
```
1. User clicks "Select Different File"
   ↓ File picker opens
   
2. User selects new file
   ↓ Previous file info replaced
   ↓ New file info displayed
```

---

## 🎨 Dark Mode (Future)

When implementing dark mode:

```
Dark Background:   #0F172A
Dark Card:         #1E293B
Dark Border:       #334155
Light Text:        #F1F5F9
Accent Blue:       #3B82F6 (lighter)
```

---

## 📋 Accessibility

### Color Contrast
- Text on background: 7:1+ contrast ratio
- Buttons: 4.5:1+ contrast ratio
- Borders: Visible and distinct

### Focus States
- All interactive elements have visible focus indicators
- Tab navigation works smoothly
- Keyboard shortcuts supported

### Screen Reader
- Semantic HTML structure
- Descriptive labels
- ARIA attributes (if needed)

---

## 🔍 Error States

### Unsupported File Type
```
┌─────────────────────────────────────┐
│ Error                               │
├─────────────────────────────────────┤
│ Unsupported file type: .txt         │
│                                     │
│ Supported formats: .raw, .mem,      │
│                   .vmem, .bin       │
│                                     │
│              [OK]                   │
└─────────────────────────────────────┘
```

### File Picker Error
```
┌─────────────────────────────────────┐
│ Error                               │
├─────────────────────────────────────┤
│ Error picking file: [error message] │
│                                     │
│              [OK]                   │
└─────────────────────────────────────┘
```

---

## 📐 Component Dimensions

| Component | Width | Height | Notes |
|-----------|-------|--------|-------|
| AppBar | Full | 56px | Standard Material |
| Upload Card | 500px | Auto | Centered, responsive |
| Icon (Upload) | 80px | 80px | Centered |
| Icon (Success) | 48px | 48px | Centered |
| Button (Primary) | Auto | 48px | With padding |
| Button (Secondary) | Full | 44px | Full width |
| File Info Card | 500px | Auto | Centered, responsive |

---

## 🎬 State Transitions

### Upload Card States
```
NORMAL
  ↓ (hover)
HOVER
  ↓ (drop valid file)
FILE_SELECTED
  ↓ (click select different)
NORMAL
```

### File Info Card States
```
HIDDEN
  ↓ (file selected)
VISIBLE
  ↓ (click select different)
HIDDEN
```

---

**Last Updated**: November 29, 2025
**Version**: 1.0
**Status**: Complete
