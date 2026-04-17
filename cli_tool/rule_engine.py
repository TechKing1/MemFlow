#!/usr/bin/env python3
"""
MemFlow Rule Engine
===================
Evaluates parsed Volatility3 plugin output and emits structured, severity-tagged
detection alerts with DFIR-style explanations and MITRE ATT&CK technique mappings.

Rules implemented:
  ORF-001  Orphan Processes             - PPID with no matching PID in pslist
  HID-001  Hidden Processes (DKOM)      - PID in psscan but absent from pslist
  INJ-001  Injected Memory Regions      - RWX VAD regions with PE header (malfind)
  NET-001  External Network Connections - ESTABLISHED connections to public IPs
  DLL-001  Suspicious DLL Load Paths    - DLLs from user-writable / temp paths
  PROC-001 Process Masquerading         - system binary names via digit/letter swap
  CMD-001  Suspicious PowerShell        - encoded commands, download cradles
  SVC-001  Suspicious Service Paths     - services with binaries in temp/user dirs
  PPID-001 Suspicious Parent-Child      - office/browser apps spawning shells
  CRED-001 Credential Dumping           - known tools or LSASS-targeting patterns
"""

import re
from dataclasses import dataclass, field, asdict
from enum import Enum
from typing import Any, Dict, List, Optional

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class Severity(str, Enum):
    CRITICAL = "CRITICAL"
    HIGH     = "HIGH"
    MEDIUM   = "MEDIUM"
    LOW      = "LOW"
    INFO     = "INFO"


class AlertCategory(str, Enum):
    PROCESS     = "Process"
    MEMORY      = "Memory"
    NETWORK     = "Network"
    MODULE      = "Module"
    SYSTEM      = "System"
    CREDENTIAL  = "Credential"
    PERSISTENCE = "Persistence"


# ---------------------------------------------------------------------------
# MITRE ATT&CK helpers
# ---------------------------------------------------------------------------

def _mitre(tid: str, name: str, tactic: str) -> Dict[str, str]:
    """Build a MITRE ATT&CK technique reference dict."""
    parts = tid.split(".")
    url = (f"https://attack.mitre.org/techniques/{parts[0]}/"
           + (f"{parts[1]}/" if len(parts) > 1 else ""))
    return {"id": tid, "name": name, "tactic": tactic, "url": url}


# Technique lookup — reference with _T["T1055"] etc.
_T: Dict[str, Dict[str, str]] = {
    "T1055":     _mitre("T1055",     "Process Injection",                          "Defense Evasion"),
    "T1055.012": _mitre("T1055.012", "Process Hollowing",                          "Defense Evasion"),
    "T1134.004": _mitre("T1134.004", "Parent PID Spoofing",                        "Defense Evasion"),
    "T1014":     _mitre("T1014",     "Rootkit",                                    "Defense Evasion"),
    "T1564.001": _mitre("T1564.001", "Hide Artifacts: Hidden Files",               "Defense Evasion"),
    "T1071.001": _mitre("T1071.001", "Application Layer Protocol: Web",            "Command and Control"),
    "T1041":     _mitre("T1041",     "Exfiltration Over C2 Channel",               "Exfiltration"),
    "T1048":     _mitre("T1048",     "Exfiltration Over Alternative Protocol",     "Exfiltration"),
    "T1574.001": _mitre("T1574.001", "DLL Search Order Hijacking",                 "Persistence"),
    "T1574.002": _mitre("T1574.002", "DLL Side-Loading",                           "Defense Evasion"),
    "T1036":     _mitre("T1036",     "Masquerading",                               "Defense Evasion"),
    "T1036.003": _mitre("T1036.003", "Rename System Utilities",                    "Defense Evasion"),
    "T1036.005": _mitre("T1036.005", "Match Legitimate Name or Location",          "Defense Evasion"),
    "T1059":     _mitre("T1059",     "Command and Scripting Interpreter",          "Execution"),
    "T1059.001": _mitre("T1059.001", "PowerShell",                                 "Execution"),
    "T1027":     _mitre("T1027",     "Obfuscated Files or Information",            "Defense Evasion"),
    "T1140":     _mitre("T1140",     "Deobfuscate/Decode Files or Information",    "Defense Evasion"),
    "T1543.003": _mitre("T1543.003", "Create or Modify System Process: Windows Service", "Persistence"),
    "T1566.001": _mitre("T1566.001", "Spearphishing Attachment",                   "Initial Access"),
    "T1204.002": _mitre("T1204.002", "User Execution: Malicious File",             "Execution"),
    "T1003":     _mitre("T1003",     "OS Credential Dumping",                      "Credential Access"),
    "T1003.001": _mitre("T1003.001", "OS Credential Dumping: LSASS Memory",        "Credential Access"),
}


# ---------------------------------------------------------------------------
# Alert dataclass
# ---------------------------------------------------------------------------

@dataclass
class Alert:
    """A single forensic detection alert with MITRE ATT&CK mapping."""
    id:                 str              # Unique rule identifier, e.g. "ORF-001"
    severity:           Severity
    category:           AlertCategory
    title:              str
    description:        str              # Short one-liner of what was found
    dfir_explanation:   str              # Forensic context and investigation guidance
    evidence:           List[str]        # Raw strings that triggered the alert
    affected_artifacts: List[str]        # PIDs, IPs, DLL paths, etc.
    mitre_techniques:   List[Dict[str, str]] = field(default_factory=list)
    # Each element: {"id": "T1055", "name": "...", "tactic": "...", "url": "..."}

    def to_dict(self) -> Dict[str, Any]:
        d = asdict(self)
        d["severity"] = self.severity.value
        d["category"] = self.category.value
        return d


# ---------------------------------------------------------------------------
# Known-good baselines
# ---------------------------------------------------------------------------

# PIDs that are legitimately parentless in Windows
_WINDOWS_ROOT_PIDS: set = {0, 4}

# Windows Vista+ boot process lineage whitelist
# -------------------------------------------------
# On Vista+, smss.exe (the session manager) spawns short-lived *child* smss.exe
# instances once per session. Each child creates csrss.exe + wininit.exe (or
# winlogon.exe for session 1), then exits. By the time a memory dump is taken
# the parent smss instances are gone, so pslist shows these as "orphans".
# This is 100% normal and must not be flagged.
#
# Format: {child_name_lower: {set of legitimate parent names (lower)}}
_WINDOWS_BOOT_LINEAGE: Dict[str, set] = {
    # Spawned by short-lived smss child instances that self-terminate
    "csrss.exe":    {"smss.exe"},
    "wininit.exe":  {"smss.exe"},
    "winlogon.exe": {"smss.exe"},
    # Services may be spawned by wininit in some configs; lsass by wininit
    "lsass.exe":    {"wininit.exe"},
    "lsm.exe":      {"wininit.exe"},
    # services.exe itself is also spawned by wininit
    "services.exe": {"wininit.exe"},
}

# Process names that are allowed to appear orphaned under certain OS conditions
# (e.g. System Idle Process, Registry hive loader on Win10+)
_ALWAYS_ALLOWED_ORPHAN_NAMES: set = {
    "system idle process",
    "registry",
    "memory compression",
    "secure system",
}

# RFC-1918 private address ranges (rough prefix check)
_PRIVATE_PREFIXES = (
    "10.",
    "172.16.", "172.17.", "172.18.", "172.19.",
    "172.20.", "172.21.", "172.22.", "172.23.",
    "172.24.", "172.25.", "172.26.", "172.27.",
    "172.28.", "172.29.", "172.30.", "172.31.",
    "192.168.",
    "127.",
    "169.254.",   # APIPA
    "::1",        # IPv6 loopback
    "fe80:",      # IPv6 link-local
    "*",          # unresolved
    "0.0.0.0",
)

# Suspicious DLL load path patterns (case-insensitive)
_SUSPICIOUS_DLL_PATTERNS = [
    r"\\temp\\",
    r"\\tmp\\",
    r"\\appdata\\local\\temp\\",
    r"\\appdata\\roaming\\",
    r"\\users\\.*\\downloads\\",
    r"\\users\\.*\\desktop\\",
    r"\\programdata\\.*\\",     # Uncommon – flag for review
    r"\\recycle",
    r"[a-z]:\\[a-z0-9]{6,12}\.dll",   # random-name DLL in root
]
_SUSPICIOUS_DLL_RE = [re.compile(p, re.IGNORECASE) for p in _SUSPICIOUS_DLL_PATTERNS]

# Expected system DLL base paths
_KNOWN_GOOD_DLL_PREFIXES = (
    "c:\\windows\\system32\\",
    "c:\\windows\\syswow64\\",
    "c:\\windows\\winsxs\\",
    "c:\\windows\\assembly\\",
    "c:\\program files\\",
    "c:\\program files (x86)\\",
)


# ---------------------------------------------------------------------------
# Rule implementations
# ---------------------------------------------------------------------------

def detect_orphan_processes(
    processes: Optional[List[Dict[str, str]]]
) -> List[Alert]:
    """
    RULE: Orphan Processes
    ----------------------
    A process whose PPID does not correspond to any living PID in the process
    list is called an orphan (beyond legitimate root-level PIDs like System).

    Malware often spawns child processes after the parent has exited or
    manipulates the PPID field to disguise its lineage.

    NOTE: Windows Vista+ boot processes (csrss, wininit, winlogon) legitimately
    appear orphaned because their parent smss instances self-terminate after
    spawning them. These are filtered via _WINDOWS_BOOT_LINEAGE whitelist.
    """
    if not processes:
        return []

    alerts: List[Alert] = []
    pid_set  = {int(p["PID"]) for p in processes if p.get("PID", "").isdigit()}
    # Build a name-by-pid lookup for context checks
    name_by_pid: Dict[int, str] = {}
    for p in processes:
        if p.get("PID", "").isdigit():
            name_by_pid[int(p["PID"])] = p.get("ImageFileName", "").lower()

    for proc in processes:
        try:
            pid  = int(proc.get("PID",  "0") or "0")
            ppid = int(proc.get("PPID", "0") or "0")
        except ValueError:
            continue

        name      = proc.get("ImageFileName", "N/A")
        name_low  = name.lower()

        # Skip absolute root PIDs
        if pid in _WINDOWS_ROOT_PIDS or ppid in _WINDOWS_ROOT_PIDS:
            continue

        # Skip always-allowed names
        if name_low in _ALWAYS_ALLOWED_ORPHAN_NAMES:
            continue

        if ppid not in pid_set:
            # --- Whitelist: known Windows boot lineage orphans ---------------
            # Check if this process is expected to have a gone-away parent
            # (e.g. csrss whose parent smss already exited)
            allowed_parents = _WINDOWS_BOOT_LINEAGE.get(name_low)
            if allowed_parents:
                # The parent is gone but name alone tells us it's a boot process
                # → suppress the alert entirely (this is normal Vista+ behaviour)
                continue

            alerts.append(Alert(
                id="ORF-001",
                severity=Severity.HIGH,
                category=AlertCategory.PROCESS,
                title="Orphan Process Detected",
                description=(
                    f"Process '{name}' (PID {pid}) references PPID {ppid} "
                    f"which does not exist in the active process list."
                ),
                dfir_explanation=(
                    "An orphan process occurs when a process's recorded parent PID "
                    "cannot be matched to any active or recently-exited process. "
                    "This is a common indicator of:\n"
                    "  • Process injection (e.g., via CreateRemoteThread) where the "
                    "injector process has since terminated\n"
                    "  • PPID spoofing — a technique used by malware to forge its parent "
                    "so it appears to be spawned by a trusted process (e.g., svchost)\n"
                    "  • Code-hollowing or process doppelgänging attacks\n\n"
                    "Investigator actions:\n"
                    "  1. Dump the process memory: vol windows.memmap --pid <PID> --dump\n"
                    "  2. Check the command line:  vol windows.cmdline --pid <PID>\n"
                    "  3. List loaded DLLs:        vol windows.dlllist --pid <PID>\n"
                    "  4. Correlate with malfind output for RWX memory regions."
                ),
                evidence=[
                    f"PID={pid}, PPID={ppid}, Name={name}",
                    f"PPID {ppid} not found in active process list ({len(pid_set)} entries)",
                ],
                affected_artifacts=[f"PID:{pid}", f"PPID:{ppid}", name],
                mitre_techniques=[_T["T1055"], _T["T1134.004"]],
            ))

    return alerts


def detect_hidden_processes(
    pslist_output:  Optional[str],
    psscan_output:  Optional[str],
) -> List[Alert]:
    """
    RULE: Hidden Processes
    ----------------------
    Compares psscan (physical memory walk) against pslist (EPROCESS linked list).
    A PID that appears in psscan but NOT in pslist has been unlinked from the
    doubly-linked list — the classic DKOM (Direct Kernel Object Manipulation)
    rootkit technique.
    """
    if not pslist_output or not psscan_output:
        return []

    def extract_pids(raw: str) -> Dict[int, str]:
        """Return {pid: process_name} from a pslist/psscan table."""
        pid_map: Dict[int, str] = {}
        for line in raw.splitlines():
            line = line.strip()
            if not line or line.startswith("Volatility") or "PID" in line:
                continue
            parts = re.split(r"\t+|\s{2,}", line)
            if len(parts) >= 3:
                try:
                    pid  = int(parts[0])
                    name = parts[2] if len(parts) > 2 else "?"
                    pid_map[pid] = name
                except ValueError:
                    pass
        return pid_map

    pslist_pids  = extract_pids(pslist_output)
    psscan_pids  = extract_pids(psscan_output)

    alerts: List[Alert] = []
    for pid, name in psscan_pids.items():
        if pid not in pslist_pids and pid not in _WINDOWS_ROOT_PIDS:
            alerts.append(Alert(
                id="HID-001",
                severity=Severity.CRITICAL,
                category=AlertCategory.PROCESS,
                title="Hidden Process (DKOM Rootkit Indicator)",
                description=(
                    f"Process '{name}' (PID {pid}) found in physical memory scan "
                    f"(psscan) but absent from the OS process list (pslist)."
                ),
                dfir_explanation=(
                    "A process visible via psscan (physical memory walk over EPROCESS "
                    "pool tags) but missing from pslist (EPROCESS linked-list traversal) "
                    "indicates Direct Kernel Object Manipulation (DKOM). The malware has "
                    "unlinked its EPROCESS structure from the ActiveProcessLinks list so "
                    "the OS — and Task Manager — cannot see it.\n\n"
                    "This is characteristic of kernel-mode rootkits such as:\n"
                    "  • TDL/Alureon, ZeroAccess, Necurs bootkit family\n"
                    "  • Custom ring-0 implants used in APT campaigns\n\n"
                    "Investigator actions:\n"
                    "  1. Dump the hidden process: vol windows.memmap --pid <PID> --dump\n"
                    "  2. Examine its VAD tree:    vol windows.vadinfo --pid <PID>\n"
                    "  3. Check for unsigned/anomalous kernel modules: vol windows.modules\n"
                    "  4. Cross-reference with volatility windows.driverscan for hidden drivers."
                ),
                evidence=[
                    f"PID {pid} ('{name}') present in psscan",
                    f"PID {pid} absent from pslist ({len(pslist_pids)} processes)",
                ],
                affected_artifacts=[f"PID:{pid}", name],
                mitre_techniques=[_T["T1014"], _T["T1564.001"]],
            ))

    return alerts


def detect_injected_memory(
    malfind_output: Optional[str],
) -> List[Alert]:
    """
    RULE: Injected Memory Regions
    ------------------------------
    Parses malfind output for VAD regions that are:
      - Marked PAGE_EXECUTE_READWRITE (RWX) — writable AND executable
      - Contain a PE header (MZ / 4D5A magic bytes)

    Both together are a strong indicator of code/shellcode injection or
    process hollowing.
    """
    if not malfind_output:
        return []

    alerts: List[Alert] = []

    # malfind output groups entries separated by blank lines; each has a header
    # like: "Process:  <name>  Pid: <pid>  Address: <addr>  Vad Tag: ..."
    # followed by protection flags and hex dump lines
    block_re   = re.compile(
        r"Process:\s+(\S+)\s+Pid:\s+(\d+)\s+Address:\s+(0x[0-9a-fA-F]+)",
        re.IGNORECASE,
    )
    rwx_re     = re.compile(r"PAGE_EXECUTE_READWRITE", re.IGNORECASE)
    pe_magic_re = re.compile(r"4d\s*5a|MZ", re.IGNORECASE)  # MZ header

    current_block = []
    entries: List[Dict[str, str]] = []

    for line in malfind_output.splitlines():
        if not line.strip():
            if current_block:
                block_text = "\n".join(current_block)
                m = block_re.search(block_text)
                if m:
                    entries.append({
                        "name":    m.group(1),
                        "pid":     m.group(2),
                        "address": m.group(3),
                        "text":    block_text,
                    })
                current_block = []
        else:
            current_block.append(line)

    # Flush last block
    if current_block:
        block_text = "\n".join(current_block)
        m = block_re.search(block_text)
        if m:
            entries.append({
                "name":    m.group(1),
                "pid":     m.group(2),
                "address": m.group(3),
                "text":    block_text,
            })

    for entry in entries:
        text     = entry["text"]
        has_rwx  = bool(rwx_re.search(text))
        has_pe   = bool(pe_magic_re.search(text))

        if has_rwx and has_pe:
            severity   = Severity.CRITICAL
            reason     = "RWX region with embedded PE header"
            techniques = [_T["T1055"], _T["T1055.012"]]
        elif has_rwx:
            severity   = Severity.HIGH
            reason     = "RWX executable-writable region"
            techniques = [_T["T1055"]]
        else:
            continue  # benign or low-signal

        alerts.append(Alert(
            id="INJ-001",
            severity=severity,
            category=AlertCategory.MEMORY,
            title="Injected Memory Region Detected",
            description=(
                f"Process '{entry['name']}' (PID {entry['pid']}) has a {reason} "
                f"at address {entry['address']}."
            ),
            dfir_explanation=(
                "A VAD (Virtual Address Descriptor) region that is both writable and "
                "executable (PAGE_EXECUTE_READWRITE) and contains a PE header (MZ/4D5A) "
                "is a textbook indicator of:\n"
                "  • Process injection via VirtualAllocEx + WriteProcessMemory + "
                "CreateRemoteThread\n"
                "  • Process hollowing (RunPE) — legitimate process image replaced "
                "    with malicious payload\n"
                "  • Reflective DLL injection — DLL loads itself into memory without "
                "    touching disk\n"
                "  • Shellcode injection staging a PE payload in memory\n\n"
                "Investigator actions:\n"
                "  1. Dump injected region: vol windows.memmap --pid <PID> --dump\n"
                "     then: strings, binwalk, or submit to VirusTotal / CAPE sandbox\n"
                "  2. Check parent-child process chain for suspicious spawns\n"
                "  3. Cross reference with network connections from the same PID\n"
                "  4. Look for missing or mismatched PE headers on disk vs memory "
                "     (vol windows.dlllist --pid <PID>)."
            ),
            evidence=[
                f"VAD @ {entry['address']} in PID {entry['pid']} ({entry['name']})",
                f"Flags: {'RWX' if has_rwx else ''}{'+ PE-header' if has_pe else ''}",
            ],
            affected_artifacts=[f"PID:{entry['pid']}", entry['name'], entry['address']],
            mitre_techniques=techniques,
        ))

    return alerts


def detect_external_connections(
    connections: Optional[List[Dict[str, str]]],
) -> List[Alert]:
    """
    RULE: External Network Connections
    ------------------------------------
    Flags ESTABLISHED TCP connections to public (non-RFC1918) IP addresses.
    These may indicate C2 beaconing, data exfiltration, or lateral movement
    to an external staging server.
    """
    if not connections:
        return []

    def is_private(addr: str) -> bool:
        ip = addr.split(":")[0] if ":" in addr else addr
        return any(ip.startswith(p) for p in _PRIVATE_PREFIXES) or not ip

    alerts: List[Alert] = []
    seen_ips: set = set()

    for conn in connections:
        state   = conn.get("State", "").upper()
        foreign = conn.get("ForeignAddr", "")
        proto   = conn.get("Proto", "")
        owner   = conn.get("Owner", "N/A")
        pid     = conn.get("PID", "N/A")
        local   = conn.get("LocalAddr", "N/A")

        if state != "ESTABLISHED":
            continue
        if is_private(foreign):
            continue

        ip = foreign.split(":")[0]
        if ip in seen_ips:
            continue
        seen_ips.add(ip)

        severity = Severity.HIGH

        # Escalate to CRITICAL if the owning process is a known system binary
        # (that should not be making external connections)
        suspicious_owners = ["lsass.exe", "csrss.exe", "smss.exe", "wininit.exe",
                             "services.exe", "winlogon.exe", "svchost.exe"]
        if any(s.lower() == owner.lower() for s in suspicious_owners):
            severity = Severity.CRITICAL

        alerts.append(Alert(
            id="NET-001",
            severity=severity,
            category=AlertCategory.NETWORK,
            title="External Network Connection Detected",
            description=(
                f"Process '{owner}' (PID {pid}) has an ESTABLISHED connection "
                f"to external IP {foreign} via {proto}."
            ),
            dfir_explanation=(
                "An ESTABLISHED connection to a public IP address from a memory dump "
                "indicates that the system was actively communicating with an external "
                "host at the time of acquisition. Forensic significance:\n"
                "  • C2 beaconing — malware periodically checks in with a remote "
                "    command-and-control server\n"
                "  • Data exfiltration — sensitive files being uploaded outbound\n"
                "  • Reverse shell — attacker interactive session already established\n"
                "  • If owner is a core Windows process (lsass, svchost), this is "
                "    especially suspicious and may indicate process hollowing or DLL injection\n\n"
                "Investigator actions:\n"
                f"  1. WHOIS / threat intel lookup on {ip}\n"
                "     Tools: VirusTotal, Shodan, AbuseIPDB, MISP\n"
                "  2. Check for additional connections from the same PID\n"
                "  3. Carve pcap data if a full capture is available\n"
                "  4. Correlate the local port with sockets in /proc (Linux) or "
                "     handle table (Windows) for additional context."
            ),
            evidence=[
                f"State=ESTABLISHED  Proto={proto}",
                f"Local={local}  Foreign={foreign}",
                f"Owner={owner}  PID={pid}",
            ],
            affected_artifacts=[f"PID:{pid}", owner, foreign, ip],
            mitre_techniques=[_T["T1071.001"], _T["T1041"], _T["T1048"]],
        ))

    return alerts


def detect_suspicious_dlls(
    dlllist_output: Optional[str],
) -> List[Alert]:
    """
    RULE: Suspicious DLL Loading
    -----------------------------
    Flags DLLs loaded from user-writable or unusual filesystem paths
    (Temp, AppData, Downloads, Desktop, etc.) that legitimate Windows
    components should never load from.
    """
    if not dlllist_output:
        return []

    alerts: List[Alert] = []

    # Parse dlllist: lines following a "Process:" header contain Base, Size, Name, Path
    # Format: "0x.... 0x.... True/False <name>  <path>"
    current_proc = {"name": "unknown", "pid": "0"}
    proc_header_re = re.compile(
        r"Process:\s+(\S+)\s+Pid:\s+(\d+)", re.IGNORECASE
    )
    # Match lines that look like DLL table rows (offset  size  wow  <name>  <path>)
    dll_line_re = re.compile(
        r"0x[0-9a-fA-F]+\s+0x[0-9a-fA-F]+\s+(?:True|False)\s+(\S+)\s+(.*)",
        re.IGNORECASE,
    )

    seen_paths: set = set()

    for line in dlllist_output.splitlines():
        line = line.strip()

        # Track current process context
        pm = proc_header_re.search(line)
        if pm:
            current_proc = {"name": pm.group(1), "pid": pm.group(2)}
            continue

        dm = dll_line_re.match(line)
        if not dm:
            continue

        dll_name = dm.group(1)
        dll_path = dm.group(2).strip().lower()

        if not dll_path or dll_path in seen_paths:
            continue
        seen_paths.add(dll_path)

        # Skip known-good paths
        if any(dll_path.startswith(p) for p in _KNOWN_GOOD_DLL_PREFIXES):
            continue

        # Check for suspicious patterns
        matched_pattern = None
        for pattern_re in _SUSPICIOUS_DLL_RE:
            if pattern_re.search(dll_path):
                matched_pattern = pattern_re.pattern
                break

        if matched_pattern:
            alerts.append(Alert(
                id="DLL-001",
                severity=Severity.HIGH,
                category=AlertCategory.MODULE,
                title="Suspicious DLL Load Path",
                description=(
                    f"Process '{current_proc['name']}' (PID {current_proc['pid']}) "
                    f"loaded '{dll_name}' from an unusual path: {dll_path}"
                ),
                dfir_explanation=(
                    "DLLs loaded from user-writable directories (Temp, AppData, "
                    "Downloads, Desktop) are a strong indicator of malicious activity. "
                    "Legitimate Windows system components load exclusively from "
                    "System32, SysWOW64, or WinSxS.\n\n"
                    "Attack techniques that produce this artifact:\n"
                    "  • DLL Search Order Hijacking — malicious DLL placed ahead of "
                    "    the legitimate one on the search path\n"
                    "  • DLL Side-loading — a signed vulnerable binary loaded alongside "
                    "    a malicious same-named DLL\n"
                    "  • In-memory dropper — payload drops a DLL to %TEMP% and loads it,\n"
                    "    then deletes the file (file may no longer exist on disk)\n\n"
                    "Investigator actions:\n"
                    f"  1. Hash the DLL: vol windows.dlllist --pid <PID>, then check "
                    "     hash against VirusTotal / MalwareBazaar\n"
                    "  2. Check if the file still exists on disk (it may be wiped)\n"
                    "  3. Examine export table for unusual exports\n"
                    "  4. Correlate with process creation events in the event log."
                ),
                evidence=[
                    f"DLL: {dll_name}",
                    f"Path: {dll_path}",
                    f"Matched rule pattern: {matched_pattern}",
                    f"Loaded by: {current_proc['name']} (PID {current_proc['pid']})",
                ],
                affected_artifacts=[
                    f"PID:{current_proc['pid']}",
                    current_proc["name"],
                    dll_path,
                ],
                mitre_techniques=[_T["T1574.001"], _T["T1574.002"]],
            ))

    return alerts


# ---------------------------------------------------------------------------
# New rule baselines
# ---------------------------------------------------------------------------

_SYSTEM_PROCESS_PATHS: Dict[str, tuple] = {
    "svchost.exe":   ("c:\\windows\\system32\\svchost.exe",),
    "lsass.exe":     ("c:\\windows\\system32\\lsass.exe",),
    "services.exe":  ("c:\\windows\\system32\\services.exe",),
    "csrss.exe":     ("c:\\windows\\system32\\csrss.exe",),
    "wininit.exe":   ("c:\\windows\\system32\\wininit.exe",),
    "winlogon.exe":  ("c:\\windows\\system32\\winlogon.exe",),
    "smss.exe":      ("c:\\windows\\system32\\smss.exe",),
    "spoolsv.exe":   ("c:\\windows\\system32\\spoolsv.exe",),
    "explorer.exe":  ("c:\\windows\\explorer.exe",),
}
_SYSTEM_BINARY_NAMES = set(_SYSTEM_PROCESS_PATHS.keys())

_DOCUMENT_PARENT_NAMES = {
    "winword.exe", "excel.exe", "powerpnt.exe", "outlook.exe",
    "acrord32.exe", "acrobat.exe", "wordpad.exe", "thunderbird.exe",
    "wps.exe", "wpp.exe", "et.exe",
}
_BROWSER_NAMES = {
    "iexplore.exe", "firefox.exe", "chrome.exe", "msedge.exe",
    "opera.exe", "brave.exe",
}
_SHELL_TARGET_NAMES = {
    "cmd.exe", "powershell.exe", "pwsh.exe", "wscript.exe",
    "cscript.exe", "mshta.exe", "regsvr32.exe", "rundll32.exe",
    "certutil.exe", "bitsadmin.exe",
}

_CRED_TOOL_NAMES = {
    "mimikatz.exe", "wce.exe", "gsecdump.exe", "pwdump.exe",
    "lazagne.exe", "fgdump.exe", "ntlmrelayx.exe", "responder.exe",
}
_CRED_CMDLINE_RE = [re.compile(p, re.IGNORECASE) for p in [
    r"sekurlsa", r"lsadump", r"privilege::debug", r"logonpasswords",
    r"procdump.*lsass", r"lsass.*-ma", r"comsvcs.*minidump",
    r"out-minidump", r"minidump.*lsass",
]]

_SUSPICIOUS_PS_RE = [(re.compile(p, re.IGNORECASE), d) for p, d in [
    (r"-[eE][nN][cC](?:odedCommand)?\s+[A-Za-z0-9+/=]{20,}", "Encoded command (-enc)"),
    (r"(?:iex|invoke-expression)\s*[\(\s]",                    "Invoke-Expression (IEX)"),
    (r"new-object\s+net\.webclient",                           "WebClient download cradle"),
    (r"downloadstring|downloadfile|downloaddata",               "HTTP download method"),
    (r"bitstransfer|start-bitstransfer",                       "BITS transfer (LOLBin)"),
    (r"-nop(?:rofile)?\s+.*-w(?:indowstyle)?\s+hid",           "Hidden no-profile PS"),
    (r"frombase64string|\[convert\]::frombase64",               "Base64 decode"),
    (r"bypass.*executionpolicy|executionpolicy.*bypass",        "ExecutionPolicy bypass"),
    (r"reflection\.assembly.*load",                             "In-memory assembly load"),
]]

_SUSPICIOUS_SVC_PATH_RE = [re.compile(p, re.IGNORECASE) for p in [
    r"\\temp\\", r"\\tmp\\", r"\\appdata\\",
    r"\\users\\.*\\downloads\\", r"\\users\\.*\\desktop\\",
    r"\\recycle",
]]


# ---------------------------------------------------------------------------
# New detection rules
# ---------------------------------------------------------------------------

def detect_process_masquerading(
    processes: Optional[List[Dict[str, str]]],
) -> List[Alert]:
    """
    RULE PROC-001: Process Masquerading
    ------------------------------------
    Detects processes impersonating system binaries via digit-for-letter
    substitution (e.g. svch0st.exe → svchost.exe, lsasse.exe → lsass.exe).
    """
    if not processes:
        return []

    _digit_map = str.maketrans("0123456789", "oizeasgtbp")

    def _norm(name: str) -> str:
        return name.lower().translate(_digit_map)

    _sys_norm = {_norm(n): n for n in _SYSTEM_BINARY_NAMES}
    alerts: List[Alert] = []

    for proc in processes:
        name     = proc.get("ImageFileName", "")
        name_low = name.lower()
        if name_low in _SYSTEM_BINARY_NAMES or not name_low.endswith(".exe"):
            continue
        normed = _norm(name_low)
        if normed in _sys_norm:
            original = _sys_norm[normed]
            pid  = proc.get("PID",  "?")
            ppid = proc.get("PPID", "?")
            alerts.append(Alert(
                id="PROC-001",
                severity=Severity.HIGH,
                category=AlertCategory.PROCESS,
                title="Process Name Masquerading (Typosquatting)",
                description=(
                    f"'{name}' (PID {pid}) impersonates '{original}' "
                    f"via digit/letter substitution."
                ),
                dfir_explanation=(
                    "Malware replaces letters with similar digits "
                    "(0→o, 1→i/l) to mimic system process names.\n\n"
                    "Investigator actions:\n"
                    "  1. Check path: vol windows.cmdline --pid <PID>\n"
                    "  2. Dump: vol windows.memmap --pid <PID> --dump\n"
                    "  3. Submit hash to VirusTotal / sandbox."
                ),
                evidence=[
                    f"Suspicious name: '{name}' (PID {pid}, PPID {ppid})",
                    f"Resembles: '{original}' via digit substitution",
                ],
                affected_artifacts=[f"PID:{pid}", name],
                mitre_techniques=[_T["T1036"], _T["T1036.005"]],
            ))

    return alerts


def detect_suspicious_cmdline(
    cmdline_output: Optional[str],
) -> List[Alert]:
    """
    RULE CMD-001: Suspicious PowerShell Command-Line Arguments
    ----------------------------------------------------------
    Scans windows.cmdline for encoded/obfuscated PowerShell patterns,
    download cradles, and living-off-the-land (LOTL) techniques.
    """
    if not cmdline_output:
        return []

    alerts: List[Alert] = []
    seen: set = set()
    ps_names = {"powershell", "powershell.exe", "pwsh", "pwsh.exe"}

    for line in cmdline_output.splitlines():
        line = line.strip()
        if not line or line.startswith("Volatility"):
            continue
        if not any(ps in line.lower() for ps in ps_names):
            continue
        for pattern_re, desc in _SUSPICIOUS_PS_RE:
            if pattern_re.search(line):
                snippet = line[:150]
                if snippet in seen:
                    continue
                seen.add(snippet)
                alerts.append(Alert(
                    id="CMD-001",
                    severity=Severity.HIGH,
                    category=AlertCategory.PROCESS,
                    title="Suspicious PowerShell Command-Line Detected",
                    description=(
                        f"Pattern '{desc}' in cmdline: "
                        f"{line[:100]}{'...' if len(line) > 100 else ''}"
                    ),
                    dfir_explanation=(
                        "Encoded/obfuscated PowerShell is a primary fileless malware "
                        "delivery mechanism, bypassing AV signatures.\n\n"
                        "Common chains: phishing macro → PS -enc → C2 beacon, "
                        "or AMSI bypass → in-memory .NET assembly load.\n\n"
                        "Investigator actions:\n"
                        "  1. Decode the base64 payload and analyse statically\n"
                        "  2. Check what spawned PowerShell (process tree)\n"
                        "  3. Correlate network connections from the same PID."
                    ),
                    evidence=[f"Match: {desc}", f"Cmdline: {line[:200]}"],
                    affected_artifacts=[line[:200]],
                    mitre_techniques=[_T["T1059.001"], _T["T1027"], _T["T1140"]],
                ))
                break  # one alert per line

    return alerts


def detect_suspicious_services(
    svcscan_output: Optional[str],
) -> List[Alert]:
    """
    RULE SVC-001: Suspicious Service Binary Paths
    ----------------------------------------------
    Flags Windows services whose ImagePath resides in user-writable or
    temporary directories. Legitimate services virtually always run from
    System32, SysWOW64, or Program Files.
    """
    if not svcscan_output:
        return []

    alerts: List[Alert] = []
    seen_paths: set = set()
    header_seen = False

    for line in svcscan_output.splitlines():
        line = line.strip()
        if not line or line.startswith("Volatility"):
            continue
        if "ServiceName" in line and ("BinaryPath" in line or "Binary" in line):
            header_seen = True
            continue
        if not header_seen:
            continue

        parts = re.split(r"\t+|\s{2,}", line)
        if len(parts) < 4:
            continue

        binary_path = parts[-1].strip().lower()
        svc_name    = parts[-3].strip() if len(parts) >= 3 else "?"

        if not binary_path or binary_path in seen_paths:
            continue
        seen_paths.add(binary_path)

        if binary_path.startswith(("c:\\windows\\", "c:\\program files")):
            continue

        for pat in _SUSPICIOUS_SVC_PATH_RE:
            if pat.search(binary_path):
                alerts.append(Alert(
                    id="SVC-001",
                    severity=Severity.HIGH,
                    category=AlertCategory.PERSISTENCE,
                    title="Suspicious Service Binary Path",
                    description=(
                        f"Service '{svc_name}' binary at unusual path: {binary_path}"
                    ),
                    dfir_explanation=(
                        "Malware installs persistence via services with binaries "
                        "in user-writable directories (Temp, AppData).\n\n"
                        "Investigator actions:\n"
                        "  1. Check service details: vol windows.svcscan\n"
                        "  2. Hash the binary and submit to VirusTotal\n"
                        "  3. Examine service start type and dependencies."
                    ),
                    evidence=[f"Service: {svc_name}", f"Binary path: {binary_path}"],
                    affected_artifacts=[svc_name, binary_path],
                    mitre_techniques=[_T["T1543.003"], _T["T1574.001"]],
                ))
                break

    return alerts


def detect_suspicious_parent_child(
    processes: Optional[List[Dict[str, str]]],
) -> List[Alert]:
    """
    RULE PPID-001: Suspicious Parent-Child Process Relationships
    -------------------------------------------------------------
    Flags unusual spawning patterns: Office/PDF apps or browsers spawning
    command interpreters, script engines, or dual-use LOLBins.
    Classic indicator of malicious macro or drive-by download execution.
    """
    if not processes:
        return []

    pid_to_proc: Dict[int, Dict] = {}
    for proc in processes:
        pid_str = proc.get("PID", "")
        if pid_str.isdigit():
            pid_to_proc[int(pid_str)] = proc

    alerts: List[Alert] = []

    for proc in processes:
        name     = proc.get("ImageFileName", "").lower()
        pid_str  = proc.get("PID",  "?")
        ppid_str = proc.get("PPID", "")

        if name not in _SHELL_TARGET_NAMES:
            continue

        try:
            ppid = int(ppid_str)
        except ValueError:
            continue

        parent = pid_to_proc.get(ppid)
        if not parent:
            continue

        parent_name = parent.get("ImageFileName", "").lower()
        parent_pid  = parent.get("PID", "?")

        if parent_name in _DOCUMENT_PARENT_NAMES:
            sev     = Severity.HIGH
            context = "document/office application"
        elif parent_name in _BROWSER_NAMES:
            sev     = Severity.MEDIUM
            context = "browser"
        else:
            continue

        alerts.append(Alert(
            id="PPID-001",
            severity=sev,
            category=AlertCategory.PROCESS,
            title="Suspicious Parent-Child Process Relationship",
            description=(
                f"'{name}' (PID {pid_str}) spawned by {context} "
                f"'{parent_name}' (PID {parent_pid})."
            ),
            dfir_explanation=(
                "Office apps and browsers spawning command interpreters is a "
                "classic indicator of malicious macro execution or drive-by download.\n\n"
                "Typical chains:\n"
                "  • Phishing .docx with VBA macro → cmd.exe → powershell\n"
                "  • Malicious PDF → acrobat → wscript → JS dropper\n"
                "  • Browser exploit → chrome → cmd → payload\n\n"
                "Investigator actions:\n"
                "  1. Dump process: vol windows.memmap --pid <PID> --dump\n"
                "  2. Check cmdline: vol windows.cmdline --pid <PID>\n"
                "  3. Look for dropped files via windows.filescan."
            ),
            evidence=[
                f"Child:  '{name}' (PID {pid_str})",
                f"Parent: '{parent_name}' (PID {parent_pid})",
            ],
            affected_artifacts=[f"PID:{pid_str}", name, f"PID:{parent_pid}", parent_name],
            mitre_techniques=[_T["T1566.001"], _T["T1204.002"], _T["T1059"]],
        ))

    return alerts


def detect_credential_dumping(
    processes: Optional[List[Dict[str, str]]],
    cmdline_output: Optional[str] = None,
) -> List[Alert]:
    """
    RULE CRED-001: Credential Dumping Indicators
    ---------------------------------------------
    Detects known credential harvesting tools by process name and
    suspicious cmdline patterns targeting LSASS memory.
    """
    alerts: List[Alert] = []

    # --- (a) Known credential tool names in process list ---
    if processes:
        for proc in processes:
            name = proc.get("ImageFileName", "")
            pid  = proc.get("PID", "?")
            if name.lower() in _CRED_TOOL_NAMES:
                alerts.append(Alert(
                    id="CRED-001",
                    severity=Severity.CRITICAL,
                    category=AlertCategory.CREDENTIAL,
                    title="Known Credential Dumping Tool Detected",
                    description=(
                        f"Process '{name}' (PID {pid}) is a known "
                        f"credential harvesting tool."
                    ),
                    dfir_explanation=(
                        "Credential dumping tools extract hashes and plaintext "
                        "credentials from LSASS memory, SAM, or Active Directory.\n\n"
                        "Investigator actions:\n"
                        "  1. Dump process: vol windows.memmap --pid <PID> --dump\n"
                        "  2. Check cmdline targets: vol windows.cmdline\n"
                        "  3. Review LSASS handles: vol windows.handles\n"
                        "  4. Assume credentials compromised — rotate immediately."
                    ),
                    evidence=[f"Process '{name}' (PID {pid}) in known tool list"],
                    affected_artifacts=[f"PID:{pid}", name],
                    mitre_techniques=[_T["T1003"], _T["T1003.001"]],
                ))

    # --- (b) Cmdline patterns targeting LSASS ---
    if cmdline_output:
        seen: set = set()
        for line in cmdline_output.splitlines():
            line = line.strip()
            if not line or line.startswith("Volatility"):
                continue
            for cre in _CRED_CMDLINE_RE:
                if cre.search(line):
                    snippet = line[:150]
                    if snippet in seen:
                        continue
                    seen.add(snippet)
                    alerts.append(Alert(
                        id="CRED-001",
                        severity=Severity.CRITICAL,
                        category=AlertCategory.CREDENTIAL,
                        title="Credential Dumping Command-Line Pattern",
                        description=(
                            f"LSASS-targeting pattern in cmdline: "
                            f"{line[:100]}{'...' if len(line) > 100 else ''}"
                        ),
                        dfir_explanation=(
                            "Commands targeting LSASS (e.g., procdump -ma lsass, "
                            "comsvcs MiniDump, mimikatz sekurlsa) dump credential "
                            "material from process memory.\n\n"
                            "Investigator actions:\n"
                            "  1. Identify the parent process\n"
                            "  2. Check for output files via windows.filescan\n"
                            "  3. Treat all domain credentials as compromised."
                        ),
                        evidence=[f"Cmdline: {line[:200]}"],
                        affected_artifacts=[line[:200]],
                        mitre_techniques=[_T["T1003"], _T["T1003.001"]],
                    ))
                    break

    return alerts


# ---------------------------------------------------------------------------
# Rule Registry  (foundation for future user-selectable rules)
# ---------------------------------------------------------------------------

RULE_REGISTRY: Dict[str, Dict[str, Any]] = {
    "ORF-001": {
        "name":        "Orphan Processes",
        "description": "Process whose PPID has no matching entry in the active process list.",
        "category":    AlertCategory.PROCESS,
        "enabled":     True,
        "mitre_ids":   ["T1055", "T1134.004"],
    },
    "HID-001": {
        "name":        "Hidden Processes (DKOM)",
        "description": "PID visible in psscan but absent from pslist — classic DKOM rootkit.",
        "category":    AlertCategory.PROCESS,
        "enabled":     True,
        "mitre_ids":   ["T1014", "T1564.001"],
    },
    "INJ-001": {
        "name":        "Injected Memory Regions",
        "description": "RWX VAD regions with PE header; process injection / hollowing.",
        "category":    AlertCategory.MEMORY,
        "enabled":     True,
        "mitre_ids":   ["T1055", "T1055.012"],
    },
    "NET-001": {
        "name":        "External Network Connections",
        "description": "ESTABLISHED connections to public IPs; possible C2 or exfiltration.",
        "category":    AlertCategory.NETWORK,
        "enabled":     True,
        "mitre_ids":   ["T1071.001", "T1041", "T1048"],
    },
    "DLL-001": {
        "name":        "Suspicious DLL Load Paths",
        "description": "DLLs loaded from user-writable / temp directories.",
        "category":    AlertCategory.MODULE,
        "enabled":     True,
        "mitre_ids":   ["T1574.001", "T1574.002"],
    },
    "PROC-001": {
        "name":        "Process Masquerading",
        "description": "System binary names with digit/letter substitution (typosquatting).",
        "category":    AlertCategory.PROCESS,
        "enabled":     True,
        "mitre_ids":   ["T1036", "T1036.005"],
    },
    "CMD-001": {
        "name":        "Suspicious PowerShell Command Lines",
        "description": "Encoded/obfuscated PowerShell, download cradles, AMSI bypass.",
        "category":    AlertCategory.PROCESS,
        "enabled":     True,
        "mitre_ids":   ["T1059.001", "T1027", "T1140"],
    },
    "SVC-001": {
        "name":        "Suspicious Service Binary Paths",
        "description": "Service binaries in Temp/AppData or other user-writable paths.",
        "category":    AlertCategory.PERSISTENCE,
        "enabled":     True,
        "mitre_ids":   ["T1543.003", "T1574.001"],
    },
    "PPID-001": {
        "name":        "Suspicious Parent-Child Processes",
        "description": "Office/browser apps spawning shells — macro or drive-by indicator.",
        "category":    AlertCategory.PROCESS,
        "enabled":     True,
        "mitre_ids":   ["T1566.001", "T1204.002", "T1059"],
    },
    "CRED-001": {
        "name":        "Credential Dumping Indicators",
        "description": "Known cred tools or LSASS-targeting cmdline patterns.",
        "category":    AlertCategory.CREDENTIAL,
        "enabled":     True,
        "mitre_ids":   ["T1003", "T1003.001"],
    },
}


# ---------------------------------------------------------------------------
# RuleEngine
# ---------------------------------------------------------------------------

class RuleEngine:
    """
    Orchestrates all detection rules against the full_analysis() result dict.

    Usage:
        engine = RuleEngine()
        alerts = engine.run_all_rules(analysis_result)
        summary = engine.summarize(alerts)

    Rule selection (preview of upcoming per-user selection feature):
        engine = RuleEngine(enabled_rules={"ORF-001", "NET-001", "CRED-001"})
    """

    def __init__(self, enabled_rules: Optional[set] = None) -> None:
        """
        Args:
            enabled_rules: Optional set of rule IDs to run.
                           Defaults to all rules marked enabled=True in RULE_REGISTRY.
        """
        if enabled_rules is not None:
            self._enabled = enabled_rules
        else:
            self._enabled = {
                rid for rid, meta in RULE_REGISTRY.items() if meta.get("enabled", True)
            }

    def _rule_enabled(self, rule_id: str) -> bool:
        return rule_id in self._enabled

    def run_all_rules(self, result: Dict[str, Any]) -> List[Alert]:
        """
        Run every enabled detection rule using data from the full_analysis() output.

        Args:
            result: The dict returned by full_analysis()

        Returns:
            Sorted list of Alert objects (CRITICAL first)
        """
        alerts: List[Alert] = []

        raw            = result.get("raw_volatility_data", {})
        plugin_results = result.get("_plugin_results_raw", {})
        processes      = raw.get("process_list") or []
        network_conns  = raw.get("network_connections") or []

        pslist_raw  = plugin_results.get("windows.pslist")
        psscan_raw  = plugin_results.get("windows.psscan")
        malfind_raw = plugin_results.get("windows.malfind")
        dlllist_raw = plugin_results.get("windows.dlllist")
        cmdline_raw = plugin_results.get("windows.cmdline")
        svcscan_raw = plugin_results.get("windows.svcscan")

        # --- Existing rules ---
        if self._rule_enabled("ORF-001"):
            alerts.extend(detect_orphan_processes(processes))
        if self._rule_enabled("HID-001"):
            alerts.extend(detect_hidden_processes(pslist_raw, psscan_raw))
        if self._rule_enabled("INJ-001"):
            alerts.extend(detect_injected_memory(malfind_raw))
        if self._rule_enabled("NET-001"):
            alerts.extend(detect_external_connections(network_conns))
        if self._rule_enabled("DLL-001"):
            alerts.extend(detect_suspicious_dlls(dlllist_raw))

        # --- New rules ---
        if self._rule_enabled("PROC-001"):
            alerts.extend(detect_process_masquerading(processes))
        if self._rule_enabled("CMD-001"):
            alerts.extend(detect_suspicious_cmdline(cmdline_raw))
        if self._rule_enabled("SVC-001"):
            alerts.extend(detect_suspicious_services(svcscan_raw))
        if self._rule_enabled("PPID-001"):
            alerts.extend(detect_suspicious_parent_child(processes))
        if self._rule_enabled("CRED-001"):
            alerts.extend(detect_credential_dumping(processes, cmdline_raw))

        # Sort: CRITICAL → HIGH → MEDIUM → LOW → INFO
        severity_order = {
            Severity.CRITICAL: 0,
            Severity.HIGH:     1,
            Severity.MEDIUM:   2,
            Severity.LOW:      3,
            Severity.INFO:     4,
        }
        alerts.sort(key=lambda a: severity_order.get(a.severity, 99))
        return alerts

    def summarize(self, alerts: List[Alert]) -> Dict[str, Any]:
        """
        Produce a count-by-severity summary and total.

        Args:
            alerts: List of Alert objects

        Returns:
            Dict with per-severity counts and total
        """
        counts: Dict[str, int] = {s.value: 0 for s in Severity}
        for alert in alerts:
            counts[alert.severity.value] += 1

        return {
            "total":    len(alerts),
            "critical": counts[Severity.CRITICAL.value],
            "high":     counts[Severity.HIGH.value],
            "medium":   counts[Severity.MEDIUM.value],
            "low":      counts[Severity.LOW.value],
            "info":     counts[Severity.INFO.value],
        }
