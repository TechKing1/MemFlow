# MemFlow - System Architecture UML Diagrams

This directory contains comprehensive PlantUML diagrams documenting the MemFlow memory forensics automation system architecture.

## 📋 Diagram Overview

### 1. System Overview (`system_overview.puml`)
**Purpose:** Complete system architecture showing all major components and their relationships.

**Contents:**
- **Frontend Layer** - Flutter desktop application with 7 screens (Login, Dashboard, Upload, Operations, Reports, Settings, Help), view models, repositories, API route modules, common widgets, and theme
- **Backend Layer** - Flask REST API with routes, models, services, Redis/RQ task queue system, and database extensions
- **Worker Process** - RQ worker for background job processing
- **CLI Tool** - Memory analysis engine with format detection, OS detection, and Volatility integration
- **Database** - PostgreSQL schema with cases and case_files tables
- **External Tools** - Volatility3 framework and Redis server
- **File System** - Storage structure for memory dumps and reports

**Key Features:**
- Shows async task queue architecture
- Displays all 7 frontend screens
- Includes Redis/RQ worker process
- Complete component relationships

---

### 2. Component Flow (`component_flow.puml`)
**Purpose:** Detailed interaction flow showing the step-by-step communication between components.

**Flow Steps:**
1. User authentication via Login screen
2. Dashboard navigation and case listing
3. File upload through dedicated Upload screen
4. **Async job queuing** to Redis Queue (NEW)
5. **Worker picks up job** from queue (NEW)
6. Background analysis execution
7. Status polling from Operations screen
8. Report retrieval and display

**Key Updates:**
- Added Redis Queue component
- Added RQ Worker process
- Shows async job processing flow
- Updated with new frontend screens

---

### 3. Database Schema (`database_schema.puml`)
**Purpose:** Entity-Relationship Diagram (ERD) for the PostgreSQL database.

**Tables:**
- **cases** - Case metadata, status, priority, JSONB metadata
- **case_files** - File information, checksums, report paths

**Relationships:**
- One case has many files (1:N)

**No changes** - Database schema remains accurate

---

### 4. CLI Architecture (`cli_architecture.puml`)
**Purpose:** In-depth architecture of the CLI memory analysis tool.

**Modules:**
- CLI Entry Point (main)
- Analyzer Interface
- Format Detection Module
- OS Detection Module
- Volatility Interface
- Plugin Management
- Output Parsers
- Progress & Utilities

**No changes** - CLI architecture remains accurate

---

### 5. Sequence Diagram (`sequence_diagram.puml`)
**Purpose:** Time-ordered sequence showing the complete workflow from upload to report generation.

**Updated Sequences:**
1. **User Authentication** - Login flow (NEW)
2. **Upload Flow** - File upload with validation
3. **Async Job Queuing** - Controller enqueues job to Redis (NEW)
4. **Background Worker Processing** - Worker polls queue and executes analysis (NEW)
5. **Status Polling** - Real-time status updates
6. **Report Retrieval** - Fetch and display results

**Key Updates:**
- Added Login screen sequence
- Added Redis Queue participant
- Added RQ Worker participant
- Shows async job processing flow

---

## 🎯 How to View Diagrams

### Option 1: PlantUML Online Server
1. Visit http://www.plantuml.com/plantuml/uml/
2. Copy the content of any `.puml` file
3. Paste into the editor
4. View the rendered diagram

### Option 2: VS Code Extension
1. Install "PlantUML" extension by jebbs
2. Open any `.puml` file
3. Press `Alt+D` to preview
4. Or right-click → "Preview Current Diagram"

### Option 3: Command Line
```bash
# Install PlantUML
# Download from: https://plantuml.com/download

# Generate PNG images
java -jar plantuml.jar uml/*.puml

# Generate SVG images
java -jar plantuml.jar -tsvg uml/*.puml
```

---

## 🏗️ Architecture Summary

### Technology Stack

**Frontend:**
- Flutter (Desktop - Windows, macOS, Linux)
- Provider (State Management)
- HTTP package (API communication)
- Custom widgets and themes

**Backend:**
- Flask (REST API)
- SQLAlchemy (ORM)
- PostgreSQL (Database)
- **Redis (Message Broker)** ⭐ NEW
- **RQ (Redis Queue - Job Queue)** ⭐ NEW
- Flask-Migrate (Database migrations)

**CLI Tool:**
- Python 3.x
- Volatility3 (Memory analysis framework)
- Concurrent execution (ThreadPoolExecutor)

**Infrastructure:**
- PostgreSQL database
- Redis server
- File system storage
- **Background worker process** ⭐ NEW

### System Flow

1. **User Authentication** → Login screen validates credentials
2. **Upload** → User uploads memory dump via dedicated Upload screen
3. **Storage** → Backend saves file and creates case record
4. **Job Queuing** → Backend enqueues analysis job to Redis Queue ⭐ NEW
5. **Background Processing** → Worker picks up job and executes analysis ⭐ NEW
6. **Analysis** → CLI tool detects format, OS, and runs Volatility plugins
7. **Reporting** → Results saved as JSON report
8. **Retrieval** → User views results in Operations/Reports screen

---

## 📦 Component Details

### Frontend Components

**Screens (7 total):**
- `LoginScreen` - User authentication ⭐ NEW
- `NewDashboardScreen` - Main dashboard with case overview ⭐ UPDATED
- `UploadCaseScreen` - Dedicated file upload interface ⭐ NEW
- `OperationsScreen` - Case analysis and monitoring
- `ReportsScreen` - View all analysis reports ⭐ NEW
- `SettingsScreen` - Application settings ⭐ NEW
- `HelpScreen` - Help and documentation ⭐ NEW

**API Route Modules:** ⭐ NEW
- `DashboardAPIRoutes` - Dashboard-specific API calls
- `UploadAPIRoutes` - Upload-specific API calls
- `ReportsAPIRoutes` - Reports-specific API calls
- `SettingsAPIRoutes` - Settings-specific API calls

**Common Widgets:** ⭐ NEW
- `AppSidebar` - Navigation sidebar
- `AppTopBar` - Top navigation bar

**View Models:**
- `LandingViewModel`
- `DashboardViewModel`
- `OperationsViewModel`

**Repositories:**
- `CaseRepository` - Handles all API communication

**Models:**
- `CaseModel` - Case data structure

### Backend Components

**Routes:**
- `POST /api/cases/upload` - Upload memory dump
- `GET /api/cases/` - List all cases with filtering ⭐ NEW
- `GET /api/cases/{id}` - Get case details
- `GET /api/cases/{id}/status` - Get case status
- `GET /api/cases/{id}/report` - Get analysis report

**Models:**
- `Case` - Case metadata and status
- `CaseFile` - File information and checksums

**Services:**
- `FileService` - File handling operations

**Extensions:**
- `db` - SQLAlchemy database
- `migrate` - Database migrations
- `redis_client` - Redis connection ⭐ NEW
- `task_queue` - RQ queue instance ⭐ NEW

**Tasks:** ⭐ NEW
- `analyze_memory_dump` - Background analysis task

**Worker Process:** ⭐ NEW
- `worker.py` - RQ worker for processing jobs
- Polls Redis queue continuously
- Executes analysis tasks asynchronously
- Windows-compatible with graceful shutdown

### CLI Components

**Core Modules:**
- `MemflowAnalyzer` - Main analysis orchestrator
- `FormatDetection` - Dump format detection
- `OSDetection` - Operating system detection
- `VolatilityInterface` - Volatility3 integration
- `PluginManager` - Plugin selection and management

**Supported Formats:**
- RAW, Windows Crash Dump, Windows Hibernation, ELF Core, LiME, VMware, VirtualBox

**Supported OS:**
- Windows (XP - 11)
- Linux (2.6.x - 6.x)
- macOS (10.x - 13.x)

---

## 📄 File Descriptions

| File | Lines | Description |
|------|-------|-------------|
| `system_overview.puml` | ~350 | Complete system architecture with all components |
| `component_flow.puml` | ~200 | Component interaction flow with async queue |
| `database_schema.puml` | ~90 | PostgreSQL database ERD |
| `cli_architecture.puml` | ~315 | CLI tool architecture and modules |
| `sequence_diagram.puml` | ~280 | Time-ordered sequence with worker process |
| `README.md` | This file | Documentation for all diagrams |
| `SYNTAX_FIXES.md` | ~75 | PlantUML syntax fixes applied |

---

## 🔄 Recent Updates

### Version 2.0 (2026-02-01)
- ✅ Added Redis/RQ task queue system
- ✅ Added background worker process
- ✅ Added 6 new frontend screens
- ✅ Added API route modules
- ✅ Added common widgets
- ✅ Updated all diagrams with async architecture
- ✅ Fixed PlantUML syntax errors

### Version 1.0 (Initial)
- ✅ Created initial system architecture diagrams
- ✅ Documented database schema
- ✅ Detailed CLI tool architecture
- ✅ Created component flow and sequence diagrams

---

## 📝 Notes

> [!IMPORTANT]
> The system now uses **asynchronous job processing** via Redis Queue. This is a major architectural change that decouples file upload from analysis execution, allowing for better scalability and user experience.

> [!NOTE]
> All diagrams have been validated against the current codebase (as of 2026-02-01) and accurately reflect the implemented architecture.

---

**Last Updated:** 2026-02-01  
**Version:** 2.0  
**Status:** ✅ All diagrams current and validated