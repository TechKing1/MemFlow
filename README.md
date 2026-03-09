# MemFlow

> Memory forensics automation — CLI analysis engine + Flutter desktop UI

MemFlow combines a Python-based CLI analysis engine (powered by **Volatility3**) with a cross-platform **Flutter desktop application**. Drop a memory dump in and get back format detection, OS fingerprinting, threat detection with **MITRE ATT&CK** mappings, and a structured JSON report.

---

## Features

### CLI Analysis Engine (`cli_tool/`)
- **Auto format detection** — Windows crash dump, ELF core, LiME, VMware, VirtualBox, raw
- **Multi-OS support** — Windows, Linux, macOS memory dumps
- **Parallel Volatility3 execution** — up to 4 plugins run concurrently with per-plugin timeouts
- **Structured JSON output** — machine-readable reports for downstream tooling

### Rule Engine — 10 Detection Rules
Each alert is tagged with **MITRE ATT&CK** technique IDs, names, tactics, and URLs.

| ID | Rule | Severity | MITRE Techniques |
|----|------|----------|-----------------|
| ORF-001 | Orphan Process | HIGH | T1055, T1134.004 |
| HID-001 | Hidden Process (DKOM) | CRITICAL | T1014, T1564.001 |
| INJ-001 | Injected Memory Region | CRITICAL/HIGH | T1055, T1055.012 |
| NET-001 | External Network Connection | CRITICAL/HIGH | T1071.001, T1041, T1048 |
| DLL-001 | Suspicious DLL Load Path | HIGH | T1574.001, T1574.002 |
| PROC-001 | Process Masquerading | HIGH | T1036, T1036.005 |
| CMD-001 | Suspicious PowerShell | HIGH | T1059.001, T1027, T1140 |
| SVC-001 | Suspicious Service Path | HIGH | T1543.003, T1574.001 |
| PPID-001 | Suspicious Parent-Child | HIGH/MEDIUM | T1566.001, T1204.002, T1059 |
| CRED-001 | Credential Dumping | CRITICAL | T1003, T1003.001 |

Rules are registered in `RULE_REGISTRY` — the foundation for future user-selectable rule sets.

### Flutter Desktop UI (`lib/`)
- Drag-and-drop memory dump ingestion
- Native file picker for Windows, macOS, Linux
- Dashboard designed for large desktop screens

---

## Project Structure

```
MemFlow/
├── cli_tool/
│   ├── memflow-cli_v2.py    # CLI entry point & full analysis workflow
│   ├── rule_engine.py       # Detection rules + MITRE ATT&CK mapping
│   └── test_rule_engine.py  # Unit tests (44 tests)
├── lib/                     # Flutter application source
├── BackEnd/                 # Flask/backend integration layer
└── uml/                     # Architecture diagrams
```

---

## Requirements

### CLI Engine
- Python 3.8+
- [Volatility3](https://github.com/volatilityfoundation/volatility3) — must be on `PATH` or installed as a module

### Flutter UI
- Flutter SDK 3.10+
- Desktop target: Windows, macOS, or Linux

---

## CLI Quick Start

### Full Analysis
```bash
python cli_tool/memflow-cli_v2.py full memory.dmp
```

### With JSON Report + Advanced Plugins
```bash
python cli_tool/memflow-cli_v2.py full memory.dmp --level advanced --json report.json
```

### Quick Scan (format + OS detection only)
```bash
python cli_tool/memflow-cli_v2.py quick memory.dmp
```

### Format Detection Only
```bash
python cli_tool/memflow-cli_v2.py detect memory.dmp
```

### Analysis Levels

| Level | Plugins | Use Case |
|-------|---------|----------|
| `essential` | pslist, info, cmdline, pstree | Fast triage |
| `standard` | + netscan, netstat | Network visibility |
| `advanced` | + malfind, dlllist, handles, psscan, svcscan | Malware hunting |
| `full` | + filescan, driverscan, modscan, registry | Deep-dive forensics |

---

## Sample Output

```
[DETECTION ALERTS]
----------------------------------------------------------------------
 CRITICAL  [HID-001] Hidden Process (DKOM Rootkit Indicator)
  Process 'rootkit.exe' (PID 1337) found in psscan but absent from pslist.
  ↳ A process unlinked from ActiveProcessLinks — classic DKOM technique.
    • PID 1337 present in psscan
    • PID 1337 absent from pslist (52 processes)

 HIGH  [PPID-001] Suspicious Parent-Child Process Relationship
  'powershell.exe' (PID 4120) spawned by document/office application
  'winword.exe' (PID 2440).
  ↳ Office apps spawning command interpreters — typical macro/phishing indicator.

  Summary: 2 alert(s) — 1 CRITICAL  1 HIGH  0 MEDIUM  0 LOW
```

---

## Running Tests

```bash
python cli_tool/test_rule_engine.py
# or
python -m pytest cli_tool/test_rule_engine.py -v
```

**44 tests**, covering all 10 detection rules with MITRE technique assertions.

---

## Flutter UI Setup

```bash
# Install dependencies
flutter pub get

# Run on desktop
flutter run -d windows   # or macos / linux
```

---

## Supported Dump Formats

| Format | Extensions |
|--------|-----------|
| Raw memory | `.raw`, `.mem`, `.bin` |
| Windows Crash Dump | `.dmp` |
| Windows Hibernation | `hiberfil.sys` |
| ELF Core | `.core` |
| LiME | `.lime` |
| VMware | `.vmem`, `.vmss` |
| VirtualBox | `.elf` |

---

## License

MIT
