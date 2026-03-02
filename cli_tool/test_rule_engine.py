#!/usr/bin/env python3
"""
Unit tests for the MemFlow Rule Engine.
Run with:  python -m pytest cli_tool/test_rule_engine.py -v
Or:        python cli_tool/test_rule_engine.py
"""

import sys
import os
import unittest

# Add the cli_tool directory to import path when run directly
sys.path.insert(0, os.path.dirname(__file__))

from rule_engine import (
    RuleEngine,
    Alert,
    Severity,
    AlertCategory,
    detect_orphan_processes,
    detect_hidden_processes,
    detect_injected_memory,
    detect_external_connections,
    detect_suspicious_dlls,
)


# ---------------------------------------------------------------------------
# Helper builders
# ---------------------------------------------------------------------------

def make_process(pid: str, ppid: str, name: str) -> dict:
    return {
        "PID": pid,
        "PPID": ppid,
        "ImageFileName": name,
        "Offset": "0x0",
        "Threads": "1",
        "Handles": "100",
        "SessionId": "1",
        "Wow64": "False",
        "CreateTime": "2024-01-01 00:00:00",
        "ExitTime": "N/A",
    }


def make_connection(state: str, foreign: str, owner: str, pid: str = "1234",
                    proto: str = "TCPv4", local: str = "10.0.0.5:50000") -> dict:
    return {
        "Offset": "0x0",
        "Proto": proto,
        "LocalAddr": local,
        "ForeignAddr": foreign,
        "State": state,
        "PID": pid,
        "Owner": owner,
    }


# ---------------------------------------------------------------------------
# Tests: detect_orphan_processes
# ---------------------------------------------------------------------------

class TestOrphanProcesses(unittest.TestCase):

    def test_no_orphans_in_normal_tree(self):
        """System / svchost lineage should not trigger orphan alerts."""
        procs = [
            make_process("4",    "0",   "System"),
            make_process("600",  "4",   "smss.exe"),
            make_process("800",  "600", "csrss.exe"),
            make_process("1000", "600", "wininit.exe"),
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 0)

    def test_orphan_detected(self):
        """Process with missing PPID should generate a HIGH alert."""
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1234", "9999", "malware.exe"),   # PPID 9999 doesn't exist
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "ORF-001")
        self.assertEqual(alerts[0].severity, Severity.HIGH)
        self.assertIn("9999", alerts[0].description)

    def test_multiple_orphans(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1234", "9990", "evil1.exe"),
            make_process("1235", "9991", "evil2.exe"),
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 2)

    def test_empty_process_list(self):
        self.assertEqual(detect_orphan_processes([]), [])
        self.assertEqual(detect_orphan_processes(None), [])

    def test_windows_boot_processes_not_flagged(self):
        """Vista+ boot processes with gone-away smss parents must NOT fire."""
        procs = [
            make_process("4",    "0",   "System"),
            make_process("344",  "4",   "smss.exe"),
            make_process("472",  "460", "csrss.exe"),    # parent smss gone
            make_process("524",  "460", "wininit.exe"),  # parent smss gone
            make_process("516",  "508", "csrss.exe"),    # parent smss gone
            make_process("552",  "508", "winlogon.exe"), # parent smss gone
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 0, [a.description for a in alerts])

    def test_non_boot_orphan_still_fires(self):
        """An unusual orphan (Oobe.exe with gone-away parent) must still fire."""
        procs = [
            make_process("4",    "0",    "System"),
            make_process("344",  "4",    "smss.exe"),
            make_process("2720", "2444", "Oobe.exe"),
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 1)
        self.assertIn("Oobe.exe", alerts[0].description)


# ---------------------------------------------------------------------------
# Tests: detect_hidden_processes
# ---------------------------------------------------------------------------

class TestHiddenProcesses(unittest.TestCase):

    PSLIST = (
        "PID   PPID  ImageFileName\n"
        "4     0     System\n"
        "800   4     csrss.exe\n"
    )

    PSSCAN_CLEAN = (
        "PID   PPID  ImageFileName\n"
        "4     0     System\n"
        "800   4     csrss.exe\n"
    )

    PSSCAN_WITH_HIDDEN = (
        "PID   PPID  ImageFileName\n"
        "4     0     System\n"
        "800   4     csrss.exe\n"
        "1337  4     rootkit.exe\n"   # NOT in pslist
    )

    def test_no_hidden(self):
        alerts = detect_hidden_processes(self.PSLIST, self.PSSCAN_CLEAN)
        self.assertEqual(len(alerts), 0)

    def test_hidden_process_detected(self):
        alerts = detect_hidden_processes(self.PSLIST, self.PSSCAN_WITH_HIDDEN)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "HID-001")
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)
        self.assertIn("1337", alerts[0].description)

    def test_missing_one_output_returns_empty(self):
        self.assertEqual(detect_hidden_processes(None, self.PSSCAN_WITH_HIDDEN), [])
        self.assertEqual(detect_hidden_processes(self.PSLIST, None), [])


# ---------------------------------------------------------------------------
# Tests: detect_injected_memory
# ---------------------------------------------------------------------------

class TestInjectedMemory(unittest.TestCase):

    RWX_WITH_PE = (
        "Process:  explorer.exe  Pid: 2468  Address: 0x1a2b3c4d  Vad Tag: VadS\n"
        "Protection: PAGE_EXECUTE_READWRITE\n"
        "0x1a2b3c4d  4d 5a 90 00 03 00 00 00  MZ......\n"
        "\n"
    )

    RWX_NO_PE = (
        "Process:  explorer.exe  Pid: 2468  Address: 0xdeadbeef  Vad Tag: VadS\n"
        "Protection: PAGE_EXECUTE_READWRITE\n"
        "0xdeadbeef  90 90 90 cc cc cc cc cc  ........\n"
        "\n"
    )

    BENIGN = (
        "Process:  notepad.exe  Pid: 1111  Address: 0x00001000  Vad Tag: VadS\n"
        "Protection: PAGE_EXECUTE_READ\n"
        "0x00001000  48 89 5c 24 08 48 89 6c  H.\\$.H.l\n"
        "\n"
    )

    def test_rwx_with_pe_is_critical(self):
        alerts = detect_injected_memory(self.RWX_WITH_PE)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)
        self.assertIn("0x1a2b3c4d", alerts[0].description)

    def test_rwx_no_pe_is_high(self):
        alerts = detect_injected_memory(self.RWX_NO_PE)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.HIGH)

    def test_benign_region_no_alert(self):
        alerts = detect_injected_memory(self.BENIGN)
        self.assertEqual(len(alerts), 0)

    def test_none_returns_empty(self):
        self.assertEqual(detect_injected_memory(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_external_connections
# ---------------------------------------------------------------------------

class TestExternalConnections(unittest.TestCase):

    def test_external_established_flagged(self):
        conns = [make_connection("ESTABLISHED", "185.220.101.42:443", "chrome.exe")]
        alerts = detect_external_connections(conns)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "NET-001")

    def test_private_ip_not_flagged(self):
        conns = [make_connection("ESTABLISHED", "192.168.1.1:80", "svchost.exe")]
        alerts = detect_external_connections(conns)
        self.assertEqual(len(alerts), 0)

    def test_listening_not_flagged(self):
        conns = [make_connection("LISTENING", "185.220.101.42:443", "nc.exe")]
        alerts = detect_external_connections(conns)
        self.assertEqual(len(alerts), 0)

    def test_system_process_external_is_critical(self):
        """lsass.exe making external connections → CRITICAL."""
        conns = [make_connection("ESTABLISHED", "1.2.3.4:443", "lsass.exe")]
        alerts = detect_external_connections(conns)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)

    def test_dedup_same_ip(self):
        """Same external IP on multiple ports should produce one alert."""
        conns = [
            make_connection("ESTABLISHED", "1.1.1.1:80",  "chrome.exe"),
            make_connection("ESTABLISHED", "1.1.1.1:443", "chrome.exe"),
        ]
        alerts = detect_external_connections(conns)
        self.assertEqual(len(alerts), 1)

    def test_empty_returns_empty(self):
        self.assertEqual(detect_external_connections([]), [])
        self.assertEqual(detect_external_connections(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_suspicious_dlls
# ---------------------------------------------------------------------------

class TestSuspiciousDlls(unittest.TestCase):

    CLEAN_DLLLIST = (
        "Process:  explorer.exe  Pid: 1234\n"
        "0x7ff800000000  0x100000  False  kernel32.dll  "
        "C:\\Windows\\System32\\kernel32.dll\n"
    )

    SUSPICIOUS_DLLLIST = (
        "Process:  explorer.exe  Pid: 1234\n"
        "0x7ff800000000  0x100000  False  kernel32.dll  "
        "C:\\Windows\\System32\\kernel32.dll\n"
        "0x000000010000  0x050000  False  evil.dll  "
        "C:\\Users\\victim\\AppData\\Local\\Temp\\evil.dll\n"
    )

    def test_clean_dll_no_alert(self):
        alerts = detect_suspicious_dlls(self.CLEAN_DLLLIST)
        self.assertEqual(len(alerts), 0)

    def test_temp_dll_flagged(self):
        alerts = detect_suspicious_dlls(self.SUSPICIOUS_DLLLIST)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "DLL-001")
        self.assertEqual(alerts[0].severity, Severity.HIGH)
        self.assertIn("evil.dll", alerts[0].description)

    def test_none_returns_empty(self):
        self.assertEqual(detect_suspicious_dlls(None), [])


# ---------------------------------------------------------------------------
# Tests: RuleEngine.summarize
# ---------------------------------------------------------------------------

class TestRuleEngineSummarize(unittest.TestCase):

    def _make_alert(self, sev: Severity) -> Alert:
        return Alert(
            id="TEST-001", severity=sev,
            category=AlertCategory.PROCESS,
            title="Test", description="Test",
            dfir_explanation="Test",
            evidence=[], affected_artifacts=[],
        )

    def test_summary_counts(self):
        engine = RuleEngine()
        alerts = [
            self._make_alert(Severity.CRITICAL),
            self._make_alert(Severity.CRITICAL),
            self._make_alert(Severity.HIGH),
            self._make_alert(Severity.LOW),
        ]
        summary = engine.summarize(alerts)
        self.assertEqual(summary["total"],    4)
        self.assertEqual(summary["critical"], 2)
        self.assertEqual(summary["high"],     1)
        self.assertEqual(summary["medium"],   0)
        self.assertEqual(summary["low"],      1)

    def test_empty_summary(self):
        engine = RuleEngine()
        summary = engine.summarize([])
        self.assertEqual(summary["total"], 0)


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 60)
    print("MemFlow Rule Engine – Unit Tests")
    print("=" * 60)
    unittest.main(verbosity=2)
