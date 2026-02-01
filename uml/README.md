# MemFlow - System Architecture UML Diagrams

This directory contains comprehensive PlantUML diagrams documenting the MemFlow memory forensics automation system architecture.

## 📋 Diagram Overview

### 1. System Overview (`system_overview.puml`)
**Purpose:** Complete system architecture showing all major components and their relationships.

**Contents:**
- **Frontend Layer** - Flutter desktop application with screens, view models, repositories, and models
- **Backend Layer** - Flask REST API with routes, models, services, and database extensions
- **CLI Tool** - Memory analysis engine with format detection, OS detection, and Volatility integration
- **Database** - PostgreSQL schema with cases and case_files tables
- **External Tools** - Volatility3 framework integration
- **File System** - Storage structure for memory dumps and reports

**Key Features:**
- Color-coded components by layer (Frontend, Backend, CLI, Database, External)
- Complete relationship mapping between all components
- Detailed notes explaining each layer's purpose
- Legend explaining communication patterns

---

### 2. Component Flow (`component_flow.puml`)
**Purpose:** Detailed interaction flow showing how components communicate during the complete workflow.

**Flow Stages:**
1. **User Upload** - File selection and upload through Flutter UI
2. **Case Creation** - Backend processing and database storage
3. **Analysis Trigger** - Asynchronous analysis initiation
4. **Format & OS Detection** - Memory dump analysis
5. **Volatility Execution** - Plugin-based forensics analysis
6. **Report Generation** - JSON report creation
7. **Status Polling** - Real-time progress updates
8. **Report Retrieval** - Final results display

**Numbered Steps:** 34 sequential steps showing the complete data flow from user action to report display.

---

### 3. Database Schema (`database_schema.puml`)
**Purpose:** Entity-Relationship Diagram (ERD) showing the PostgreSQL database structure.

**Tables:**
- **cases** - Main case management table
  - Fields: id, name, description, status, priority, created_at, updated_at, metadata (JSONB)
  - Status values: queued, processing, completed, failed
  - Priority range: 1-10

- **case_files** - File tracking and metadata
  - Fields: id, case_id (FK), file_path, file_size, checksum, mime_type, stored_at, report_path, notes
  - SHA-256 checksums for integrity verification

**Relationships:**
- One-to-Many: cases → case_files

**Indexes:** Documented for performance optimization on frequently queried fields.

---

### 4. CLI Architecture (`cli_architecture.puml`)
**Purpose:** Detailed architecture of the memory analysis CLI tool (memflow-cli_v2.py).

**Modules:**
- **CLI Entry Point** - Command-line interface with modes (full, quick, detect)
- **Analyzer Interface** - Main MemflowAnalyzer class
- **Format Detection** - Magic byte signatures and format identification
- **OS Detection** - Signature-based OS identification (Windows/Linux/macOS)
- **Volatility Interface** - Plugin execution and management
- **Plugin Management** - OS-specific plugin sets (essential, network, malware, advanced)
- **Output Parsers** - Structured data extraction from Volatility output
- **Progress & Utilities** - Progress tracking, color output, formatting utilities
- **Error Handling** - Custom exception hierarchy

**Plugin Categories:**
- **Windows:** 13+ plugins (pslist, netscan, malfind, filescan, etc.)
- **Linux:** 7+ plugins (bash, pslist, sockstat, lsmod, etc.)
- **macOS:** 5+ plugins (pslist, netstat, lsmod, etc.)

**Analysis Pipeline:** 8-step process from file validation to JSON report generation.

---

### 5. Sequence Diagram (`sequence_diagram.puml`)
**Purpose:** Time-ordered interaction sequence showing the complete upload and analysis workflow.

**Sequences:**
1. **User Upload Flow** - From file selection to case creation
2. **Background Analysis Flow** - Asynchronous memory analysis process
3. **Status Polling & Report Retrieval** - Real-time updates and final report access

**Participants:**
- User, Landing Screen, Dashboard Screen, Case Repository
- Upload API, Case Controller, File Handler
- PostgreSQL Database, File System
- Memflow Analyzer, Format Detector, OS Detector
- Volatility Runner, Volatility3, Report Generator

**Key Interactions:** Shows activation/deactivation of components and data flow timing.

---

## 🚀 How to Use These Diagrams

### Viewing PlantUML Diagrams

**Option 1: Online Viewer**
1. Visit [PlantUML Online Server](http://www.plantuml.com/plantuml/uml/)
2. Copy and paste the content of any `.puml` file
3. View the rendered diagram

**Option 2: VS Code Extension**
1. Install the "PlantUML" extension by jebbs
2. Open any `.puml` file
3. Press `Alt+D` to preview

**Option 3: Command Line (requires Java & Graphviz)**
```bash
# Install PlantUML
# Download plantuml.jar from https://plantuml.com/download

# Generate PNG images
java -jar plantuml.jar uml/*.puml

# Generate SVG images
java -jar plantuml.jar -tsvg uml/*.puml
```

**Option 4: IntelliJ IDEA / PyCharm**
1. Install the "PlantUML integration" plugin
2. Right-click any `.puml` file
3. Select "Show PlantUML Diagram"

---

## 📊 Architecture Summary

### Technology Stack
- **Frontend:** Flutter (Dart) - Cross-platform desktop application
- **Backend:** Flask (Python) - REST API server
- **Database:** PostgreSQL with SQLAlchemy ORM
- **CLI Tool:** Python 3.x with Volatility3 integration
- **External:** Volatility3 memory forensics framework

### Communication Patterns
- **Frontend ↔ Backend:** HTTP REST API (JSON)
- **Backend ↔ Database:** SQLAlchemy ORM
- **Backend ↔ CLI:** Subprocess invocation (planned async integration)
- **CLI ↔ Volatility3:** Command-line subprocess execution

### Key Design Patterns
- **MVVM** - Frontend architecture (Model-View-ViewModel)
- **Repository Pattern** - Data access abstraction
- **Factory Pattern** - Flask app creation
- **Strategy Pattern** - Plugin selection based on OS type
- **Observer Pattern** - Progress tracking with callbacks

---

## 🔍 Component Details

### Frontend (Flutter)
- **Screens:** Landing, Dashboard, Operations
- **ViewModels:** State management and business logic
- **Repositories:** API communication layer
- **Models:** Data transfer objects (CaseModel, CaseStatus, CaseReport)

### Backend (Flask)
- **Routes:** RESTful API endpoints (`/api/cases/*`)
- **Models:** SQLAlchemy ORM models (Case, CaseFile)
- **Services:** Business logic layer (file handling, validation)
- **Extensions:** Database and migration management

### CLI Tool
- **Analysis Modes:** Full, Quick, Detect
- **Analysis Levels:** Essential, Standard, Advanced, Full
- **Supported Formats:** RAW, Windows Crash Dump, Hibernation, ELF Core, LIME, VMware, VirtualBox
- **Supported OS:** Windows, Linux, macOS
- **Output:** JSON reports with structured analysis data

---

## 📝 File Descriptions

| File | Lines | Purpose |
|------|-------|---------|
| `system_overview.puml` | ~450 | Complete system architecture |
| `component_flow.puml` | ~200 | Component interaction workflow |
| `database_schema.puml` | ~100 | Database ERD |
| `cli_architecture.puml` | ~350 | CLI tool detailed architecture |
| `sequence_diagram.puml` | ~250 | Time-ordered interaction sequence |

---

## 🎨 Color Coding

- **Blue (#E3F2FD)** - Frontend components
- **Orange (#FFF3E0)** - Backend components
- **Green (#E8F5E9)** - CLI tool components
- **Purple (#F3E5F5)** - Database components
- **Red (#FFEBEE)** - External tools/dependencies

---

## 📚 Related Documentation

- **README.md** - Project overview and setup instructions
- **START_HERE.md** - Quick start guide
- **DOCUMENTATION_INDEX.md** - Complete documentation index
- **CODE_SNIPPETS.md** - Code examples and patterns
- **UI_REFERENCE.md** - Frontend UI documentation

---

## 🔄 Diagram Updates

These diagrams should be updated when:
- New components are added to the system
- API endpoints are modified or added
- Database schema changes
- New analysis plugins are integrated
- Architecture patterns change

**Last Updated:** 2026-02-01  
**Version:** 1.0  
**Author:** Generated from codebase analysis

---

## 💡 Tips for Understanding the Architecture

1. **Start with `system_overview.puml`** to get the big picture
2. **Follow `component_flow.puml`** to understand the workflow
3. **Check `sequence_diagram.puml`** for timing and order of operations
4. **Review `database_schema.puml`** for data structure
5. **Dive into `cli_architecture.puml`** for analysis engine details

---

## 🛠️ Future Enhancements

Potential additions to the architecture:
- **Authentication & Authorization** - User management system
- **WebSocket Integration** - Real-time progress updates
- **Queue System** - Redis/Celery for background job processing
- **Caching Layer** - Redis for performance optimization
- **Microservices** - Split backend into smaller services
- **Container Orchestration** - Docker/Kubernetes deployment
- **API Gateway** - Centralized API management
- **Monitoring & Logging** - ELK stack or similar

---

*For questions or clarifications about the architecture, refer to the source code or contact the development team.*
