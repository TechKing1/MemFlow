#!/usr/bin/env python3
"""
Memflow CLI - Memory dump analysis tool using Volatility3
Analyzes memory dumps and provides comprehensive forensic information
"""
import argparse
import hashlib
import json
import os
import platform
import subprocess
import shutil
import sys
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime

# Constants
BUFFER_SIZE = 65536
HEURISTIC_SAMPLE_SIZE = 2_000_000
DEFAULT_TIMEOUT = 300  # 5 minutes for volatility commands
MIN_FILE_SIZE = 1024  # 1KB minimum for memory dumps

# OS Detection signatures
WINDOWS_SIGNATURES = [b"SystemRoot", b"KDBG", b"ntoskrnl"]
LINUX_SIGNATURES = [b"Linux version"]
MAC_SIGNATURES = [b"Darwin Kernel"]


class MemflowError(Exception):
    """Base exception for Memflow CLI errors"""
    pass


class VolatilityNotFoundError(MemflowError):
    """Raised when Volatility3 cannot be located"""
    pass


# ---------------------------------------------------------
# Volatility3 Detection
# ---------------------------------------------------------

def find_volatility() -> Optional[str]:
    """
    Locate Volatility3 installation across different operating systems.
    
    Returns:
        Path to Volatility3 executable or command, None if not found
    """
    system = platform.system().lower()

    if system == "windows":
        return _find_volatility_windows()
    else:
        return _find_volatility_unix()


def _find_volatility_windows() -> Optional[str]:
    """Find Volatility on Windows systems"""
    # Check PATH first
    for name in ["vol.exe", "vol.cmd", "vol.bat"]:
        path = shutil.which(name)
        if path:
            return path

    # Check common installation directories
    possible_paths = [
        Path(os.getenv("LOCALAPPDATA", "")) / "Programs" / "Python",
        Path("C:/Program Files/Volatility3"),
        Path("C:/Program Files (x86)/Volatility3"),
        Path.home() / "AppData" / "Local" / "Programs" / "Python"
    ]

    for base_path in possible_paths:
        if base_path.exists():
            for pattern in ["**/vol.exe", "**/vol.cmd"]:
                for candidate in base_path.glob(pattern):
                    if candidate.exists():
                        return str(candidate)

    return _try_python_module()


def _find_volatility_unix() -> Optional[str]:
    """Find Volatility on Linux/macOS systems"""
    for name in ["vol", "vol.py", "volatility3", "vol3"]:
        path = shutil.which(name)
        if path:
            return path

    return _try_python_module()


def _try_python_module() -> Optional[str]:
    """Try to use Volatility3 as a Python module"""
    try:
        __import__("volatility3")
        return f'"{sys.executable}" -m volatility3'
    except ImportError:
        return None


# ---------------------------------------------------------
# Volatility Command Execution
# ---------------------------------------------------------

def run_vol(command: str, dump_path: str, timeout: int = DEFAULT_TIMEOUT) -> Optional[str]:
    """
    Execute a Volatility3 command on the memory dump.
    
    Args:
        command: Volatility plugin command (e.g., "windows.info")
        dump_path: Path to the memory dump file
        timeout: Command timeout in seconds
        
    Returns:
        Command output as string, or None if failed
    """
    vol = find_volatility()
    if not vol:
        raise VolatilityNotFoundError("Volatility3 not found. Please install it first.")

    full_cmd = f'{vol} -f "{dump_path}" {command}'
    
    try:
        proc = subprocess.run(
            full_cmd,
            capture_output=True,
            text=True,
            shell=True,
            timeout=timeout,
            encoding='utf-8',
            errors='replace'
        )
        
        if proc.returncode == 0 and proc.stdout:
            return proc.stdout
        
        # Log error if available
        if proc.stderr:
            print(f"[!] Volatility error: {proc.stderr[:200]}", file=sys.stderr)
        
        return None
        
    except subprocess.TimeoutExpired:
        print(f"[!] Command timeout after {timeout}s: {command}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"[!] Error running volatility: {e}", file=sys.stderr)
        return None


# ---------------------------------------------------------
# Output Parsers
# ---------------------------------------------------------

def parse_windows_info(raw_output: Optional[str]) -> Optional[Dict[str, str]]:
    """
    Parse windows.info plugin output into structured data.
    
    Args:
        raw_output: Raw output from windows.info plugin
        
    Returns:
        Dictionary of system information, or None if parsing failed
    """
    if not raw_output:
        return None
    
    parsed = {}
    lines = raw_output.strip().split('\n')
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines and headers
        if not line or 'Volatility 3' in line or line.startswith('Variable') or line.startswith('==='):
            continue
        
        # Split by tab or multiple spaces
        parts = re.split(r'\t+|\s{2,}', line, maxsplit=1)
        
        if len(parts) == 2:
            key = parts[0].strip()
            value = parts[1].strip()
            if key and value:
                parsed[key] = value
    
    return parsed if parsed else None


def parse_windows_pslist(raw_output: Optional[str]) -> Optional[List[Dict[str, str]]]:
    """
    Parse windows.pslist plugin output into structured process list.
    
    Args:
        raw_output: Raw output from windows.pslist plugin
        
    Returns:
        List of process dictionaries, or None if parsing failed
    """
    if not raw_output:
        return None
    
    processes = []
    lines = raw_output.strip().split('\n')
    
    # Find the header line
    header_idx = -1
    for i, line in enumerate(lines):
        if 'PID' in line and 'PPID' in line and 'ImageFileName' in line:
            header_idx = i
            break
    
    if header_idx == -1:
        return None
    
    # Process each line after the header
    for line in lines[header_idx + 1:]:
        line = line.strip()
        if not line or line.startswith('==='):
            continue
        
        # Split by tab or multiple spaces
        parts = re.split(r'\t+|\s{2,}', line)
        
        if len(parts) >= 10:
            process = {
                "PID": parts[0].strip(),
                "PPID": parts[1].strip(),
                "ImageFileName": parts[2].strip(),
                "Offset": parts[3].strip(),
                "Threads": parts[4].strip(),
                "Handles": parts[5].strip(),
                "SessionId": parts[6].strip(),
                "Wow64": parts[7].strip(),
                "CreateTime": parts[8].strip(),
                "ExitTime": parts[9].strip() if len(parts) > 9 else "N/A "
            }
            processes.append(process)
    
    return processes if processes else None


# ---------------------------------------------------------
# File Hashing
# ---------------------------------------------------------

def file_hashes(path: str) -> Dict[str, str]:
    """
    Calculate MD5, SHA1, and SHA256 hashes of a file.
    
    Args:
        path: Path to the file
        
    Returns:
        Dictionary containing hash values
    """
    md5 = hashlib.md5()
    sha1 = hashlib.sha1()
    sha256 = hashlib.sha256()

    try:
        with open(path, "rb") as f:
            while chunk := f.read(BUFFER_SIZE):
                md5.update(chunk)
                sha1.update(chunk)
                sha256.update(chunk)

        return {
            "md5": md5.hexdigest(),
            "sha1": sha1.hexdigest(),
            "sha256": sha256.hexdigest()
        }
    except Exception as e:
        raise MemflowError(f"Failed to calculate hashes: {e}")


# ---------------------------------------------------------
# OS Detection Heuristics
# ---------------------------------------------------------

def heuristic_guess(path: str) -> Tuple[str, List[str], int]:
    """
    Attempt to detect OS from memory dump using signature heuristics.
    
    Args:
        path: Path to memory dump
        
    Returns:
        Tuple of (OS name, list of evidence strings, confidence score 0-100)
    """
    try:
        with open(path, "rb") as f:
            sample = f.read(HEURISTIC_SAMPLE_SIZE)
        
        # Count signature occurrences for better confidence
        windows_count = sum(sample.count(sig) for sig in WINDOWS_SIGNATURES)
        linux_count = sum(sample.count(sig) for sig in LINUX_SIGNATURES)
        mac_count = sum(sample.count(sig) for sig in MAC_SIGNATURES)
        
        # Determine OS with confidence
        if windows_count > 0:
            confidence = min(100, 60 + (windows_count * 10))
            evidence = [f"Found {windows_count} Windows kernel signature(s) (KDBG/ntoskrnl/SystemRoot)"]
            return ("Windows", evidence, confidence)
        
        if linux_count > 0:
            confidence = min(100, 60 + (linux_count * 10))
            evidence = [f"Found {linux_count} Linux kernel signature(s)"]
            return ("Linux", evidence, confidence)
        
        if mac_count > 0:
            confidence = min(100, 60 + (mac_count * 10))
            evidence = [f"Found {mac_count} macOS kernel signature(s)"]
            return ("macOS", evidence, confidence)
        
        return ("Unknown", ["No OS-specific signatures found in first 2MB sample"], 0)
        
    except Exception as e:
        return ("Unknown", [f"Error during heuristic analysis: {e}"], 0)


# ---------------------------------------------------------
# Analysis Helpers
# ---------------------------------------------------------

def extract_os_info(windows_info: Optional[Dict[str, str]]) -> Dict[str, Any]:
    """
    Extract and format OS information from windows.info output.
    
    Args:
        windows_info: Parsed windows.info data
        
    Returns:
        Formatted OS information dictionary
    """
    if not windows_info:
        return {"detected": False}
    
    # Extract version info
    major = windows_info.get("NtMajorVersion", "")
    minor = windows_info.get("NtMinorVersion", "")
    product = windows_info.get("NtProductType", "")
    build = windows_info.get("NTBuildLab", "")
    
    # Determine Windows version
    version_name = "Unknown Windows"
    if major == "6" and minor == "0":
        version_name = "Windows Vista / Server 2008"
    elif major == "6" and minor == "1":
        version_name = "Windows 7 / Server 2008 R2"
    elif major == "6" and minor == "2":
        version_name = "Windows 8 / Server 2012"
    elif major == "6" and minor == "3":
        version_name = "Windows 8.1 / Server 2012 R2"
    elif major == "10" and minor == "0":
        version_name = "Windows 10 / Server 2016+"
    
    return {
        "detected": True,
        "os_type": "Windows",
        "version": version_name,
        "version_numbers": f"{major}.{minor}",
        "product_type": product,
        "build_lab": build,
        "architecture": "x86 (32-bit PAE)" if windows_info.get("IsPAE") == "True" else "x64 (64-bit)" if windows_info.get("Is64Bit") == "True" else "x86 (32-bit)",
        "system_time": windows_info.get("SystemTime", "Unknown"),
        "system_root": windows_info.get("NtSystemRoot", "Unknown"),
        "kernel_base": windows_info.get("Kernel Base", "Unknown")
    }


def analyze_processes(processes: Optional[List[Dict[str, str]]]) -> Dict[str, Any]:
    """
    Analyze process list and extract insights.
    
    Args:
        processes: List of parsed processes
        
    Returns:
        Process analysis summary
    """
    if not processes:
        return {"detected": False, "count": 0}
    
    # Extract interesting processes
    interesting = {
        "browsers": [],
        "system": [],
        "suspicious": [],
        "user_apps": []
    }
    
    browser_names = ["iexplore.exe", "firefox.exe", "chrome.exe", "msedge.exe", "opera.exe"]
    system_names = ["System", "smss.exe", "csrss.exe", "wininit.exe", "services.exe", "lsass.exe", "svchost.exe"]
    suspicious_indicators = ["FTK Imager.exe", "winpmem", "dumpit", "procdump"]
    
    for proc in processes:
        name = proc.get("ImageFileName", "")
        
        if any(browser in name.lower() for browser in browser_names):
            interesting["browsers"].append({
                "name": name,
                "pid": proc.get("PID"),
                "created": proc.get("CreateTime")
            })
        elif any(sys_name.lower() == name.lower() for sys_name in system_names):
            interesting["system"].append(name)
        elif any(susp in name for susp in suspicious_indicators):
            interesting["suspicious"].append({
                "name": name,
                "pid": proc.get("PID"),
                "created": proc.get("CreateTime")
            })
        elif proc.get("SessionId") == "1" and name not in system_names:
            interesting["user_apps"].append(name)
    
    return {
        "detected": True,
        "total_count": len(processes),
        "running_processes": len([p for p in processes if p.get("ExitTime") == "N/A"]),
        "exited_processes": len([p for p in processes if p.get("ExitTime") != "N/A"]),
        "interesting_findings": {
            "browsers": interesting["browsers"],
            "suspicious_processes": interesting["suspicious"],
            "user_applications": list(set(interesting["user_apps"]))[:10]  # Top 10 unique
        }
    }


def determine_os_confidence(heuristic_result: Tuple[str, List[str], int], 
                           windows_info: Optional[Dict], 
                           linux_success: bool, 
                           mac_success: bool) -> Dict[str, Any]:
    """
    Determine final OS detection with confidence level.
    
    Args:
        heuristic_result: Results from heuristic detection
        windows_info: Parsed Windows info (if any)
        linux_success: Whether Linux plugins succeeded
        mac_success: Whether Mac plugins succeeded
        
    Returns:
        OS detection summary with confidence
    """
    os_guess, evidence, heuristic_confidence = heuristic_result
    
    # Volatility confirmation
    volatility_confirms = {
        "Windows": windows_info is not None,
        "Linux": linux_success,
        "macOS": mac_success
    }
    
    # Calculate final confidence
    if volatility_confirms.get(os_guess, False):
        final_confidence = min(100, heuristic_confidence + 30)
        confidence_level = "HIGH"
        detection_method = "Heuristic + Volatility Confirmation"
    elif heuristic_confidence >= 70:
        final_confidence = heuristic_confidence
        confidence_level = "MEDIUM"
        detection_method = "Heuristic Only"
    elif heuristic_confidence > 0:
        final_confidence = heuristic_confidence
        confidence_level = "LOW"
        detection_method = "Heuristic Only (Weak)"
    else:
        final_confidence = 0
        confidence_level = "NONE"
        detection_method = "No OS signatures detected"
    
    return {
        "operating_system": os_guess,
        "confidence_score": final_confidence,
        "confidence_level": confidence_level,
        "detection_method": detection_method,
        "evidence": evidence,
        "volatility_support": {
            "windows_compatible": volatility_confirms["Windows"],
            "linux_compatible": volatility_confirms["Linux"],
            "macos_compatible": volatility_confirms["macOS"]
        }
    }


# ---------------------------------------------------------
# Full Analysis Workflow
# ---------------------------------------------------------

def full_analysis(path: str) -> Dict[str, Any]:
    """
    Perform comprehensive analysis of a memory dump file.
    
    Args:
        path: Path to the memory dump file
        
    Returns:
        Dictionary containing complete analysis results
    """
    # Validate input
    if not os.path.exists(path):
        raise MemflowError(f"File not found: {path}")
    
    if not os.path.isfile(path):
        raise MemflowError(f"Not a file: {path}")
    
    size_bytes = os.path.getsize(path)
    
    if size_bytes < MIN_FILE_SIZE:
        raise MemflowError(f"File too small ({size_bytes} bytes), likely not a valid memory dump")
    
    # Basic file information
    human_size = _format_size(size_bytes)
    
    print("[*] Calculating file hashes...")
    hashes = file_hashes(path)

    print("[*] Running OS detection heuristics...")
    heuristic_result = heuristic_guess(path)
    os_guess = heuristic_result[0]

    print(f"[*] Heuristic detection: {os_guess} (confidence: {heuristic_result[2]}%)")
    print(f"[*] Running Volatility3 plugins for {os_guess}...")
    
    # Run appropriate plugins based on heuristic
    win_info_raw = None
    win_pslist_raw = None
    linux_banners_raw = None
    linux_pslist_raw = None
    mac_banners_raw = None
    
    if os_guess == "Windows":
        print("    - windows.info")
        win_info_raw = run_vol("windows.info", path)
        print("    - windows.pslist")
        win_pslist_raw = run_vol("windows.pslist", path)
    elif os_guess == "Linux":
        print("    - linux.banners")
        linux_banners_raw = run_vol("linux.banners", path)
        print("    - linux.pslist")
        linux_pslist_raw = run_vol("linux.pslist", path)
    elif os_guess == "macOS":
        print("    - mac.banners")
        mac_banners_raw = run_vol("mac.banners", path)
    else:
        # Unknown - try all
        print("    - Trying all OS plugins...")
        print("      - windows.info")
        win_info_raw = run_vol("windows.info", path)
        if not win_info_raw:
            print("      - linux.banners")
            linux_banners_raw = run_vol("linux.banners", path)
        if not win_info_raw and not linux_banners_raw:
            print("      - mac.banners")
            mac_banners_raw = run_vol("mac.banners", path)
        
        if win_info_raw:
            print("      - windows.pslist")
            win_pslist_raw = run_vol("windows.pslist", path)

    # Parse outputs
    windows_info = parse_windows_info(win_info_raw)
    processes = parse_windows_pslist(win_pslist_raw)
    
    # Build comprehensive analysis
    os_detection = determine_os_confidence(
        heuristic_result,
        windows_info,
        linux_banners_raw is not None or linux_pslist_raw is not None,
        mac_banners_raw is not None
    )
    
    system_info = extract_os_info(windows_info)
    process_analysis = analyze_processes(processes)
    
    # Build final report
    return {
        "analysis_metadata": {
            "analyzer": "Memflow CLI",
            "analysis_date": datetime.now().isoformat(),
            "dump_filename": os.path.basename(path),
            "dump_path": str(Path(path).resolve())
        },
        "file_information": {
            "size_bytes": size_bytes,
            "size_human": human_size,
            "hashes": hashes
        },
        "os_detection": os_detection,
        "system_information": system_info,
        "process_analysis": process_analysis,
        "raw_volatility_data": {
            "windows_info": windows_info if windows_info else None,
            "process_list": processes if processes else None,
            "plugins_attempted": {
                "windows.info": win_info_raw is not None,
                "windows.pslist": win_pslist_raw is not None,
                "linux.banners": linux_banners_raw is not None,
                "linux.pslist": linux_pslist_raw is not None,
                "mac.banners": mac_banners_raw is not None
            }
        }
    }


def _format_size(bytes_size: int) -> str:
    """Format byte size to human-readable string."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_size < 1024.0:
            return f"{bytes_size:.2f} {unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.2f} PB"


# ---------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------

def main() -> None:
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Memflow CLI - Memory Dump Analysis Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s full memory.dmp
  %(prog)s full memory.dmp --json report.json
        """
    )
    
    parser.add_argument(
        "mode",
        choices=["full"],
        help="Analysis mode (currently only 'full' is supported)"
    )
    
    parser.add_argument(
        "dump",
        help="Path to memory dump file"
    )
    
    parser.add_argument(
        "--json",
        dest="json_out",
        metavar="FILE",
        help="Save JSON report to specified file"
    )
    
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Show detailed output including raw volatility data"
    )

    args = parser.parse_args()

    try:
        if args.mode == "full":
            print(f"[*] Starting analysis of: {args.dump}\n")
            result = full_analysis(args.dump)

            print("\n" + "="*70)
            print("ANALYSIS COMPLETE")
            print("="*70 + "\n")
            
            # Print summary
            _print_summary(result, args.verbose)

            if args.json_out:
                try:
                    with open(args.json_out, "w", encoding="utf-8") as f:
                        json.dump(result, f, indent=2, ensure_ascii=False)
                    print(f"\n[+] Full report saved -> {args.json_out}")
                except Exception as e:
                    print(f"\n[!] Failed to save JSON report: {e}", file=sys.stderr)
                
    except MemflowError as e:
        print(f"\n[!] Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[!] Analysis interrupted by user", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"\n[!] Unexpected error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


def _print_summary(result: Dict[str, Any], verbose: bool = False) -> None:
    """Print formatted summary of analysis results."""
    
    try:
        # File Information
        print("[FILE INFORMATION]")
        print("-" * 70)
        file_info = result["file_information"]
        print(f"  File: {result['analysis_metadata']['dump_filename']}")
        print(f"  Size: {file_info['size_human']} ({file_info['size_bytes']:,} bytes)")
        print(f"  MD5:  {file_info['hashes']['md5']}")
        print(f"  SHA256: {file_info['hashes']['sha256']}")
        
        # OS Detection
        print("\n[OS DETECTION]")
        print("-" * 70)
        os_detect = result["os_detection"]
        confidence_indicator = "[HIGH]" if os_detect["confidence_score"] >= 80 else "[MEDIUM]" if os_detect["confidence_score"] >= 50 else "[LOW]"
        print(f"  Operating System: {os_detect['operating_system']}")
        print(f"  Confidence: {confidence_indicator} {os_detect['confidence_score']}% ({os_detect['confidence_level']})")
        print(f"  Method: {os_detect['detection_method']}")
        print(f"  Evidence:")
        for evidence in os_detect["evidence"]:
            print(f"    - {evidence}")
        
        # System Information
        sys_info = result["system_information"]
        if sys_info.get("detected"):
            print("\n[SYSTEM INFORMATION]")
            print("-" * 70)
            print(f"  OS Version: {sys_info['version']}")
            print(f"  Architecture: {sys_info['architecture']}")
            print(f"  Product Type: {sys_info['product_type']}")
            print(f"  System Time: {sys_info['system_time']}")
            print(f"  System Root: {sys_info['system_root']}")
        
        # Process Analysis
        proc_info = result["process_analysis"]
        if proc_info.get("detected"):
            print("\n[PROCESS ANALYSIS]")
            print("-" * 70)
            print(f"  Total Processes: {proc_info['total_count']}")
            print(f"  Running: {proc_info['running_processes']} | Exited: {proc_info['exited_processes']}")
            
            findings = proc_info["interesting_findings"]
            
            if findings.get("suspicious_processes"):
                print(f"\n  [!] Suspicious Processes:")
                for proc in findings["suspicious_processes"]:
                    print(f"    - {proc['name']} (PID: {proc['pid']}) - {proc['created']}")
            
            if findings.get("browsers"):
                print(f"\n  [+] Browsers:")
                for browser in findings["browsers"]:
                    print(f"    - {browser['name']} (PID: {browser['pid']})")
            
            if findings.get("user_applications"):
                print(f"\n  [+] User Applications (sample):")
                for app in findings["user_applications"][:5]:
                    print(f"    - {app}")
        
        # Verbose output
        if verbose:
            print("\n[RAW VOLATILITY DATA]")
            print("-" * 70)
            print(json.dumps(result["raw_volatility_data"], indent=2))
    
    except Exception as e:
        print(f"\n[!] Error printing summary: {e}", file=sys.stderr)
        print("\nFull result:")
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()