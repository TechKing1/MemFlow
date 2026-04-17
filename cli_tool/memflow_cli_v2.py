#!/usr/bin/env python3
"""
Memflow CLI v2.0 - Advanced Memory Dump Analysis Tool
Analyzes memory dumps with support for multiple formats and operating systems.
Designed for both CLI usage and background integration.
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
import struct
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any, Callable
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, asdict
from enum import Enum

# Constants
BUFFER_SIZE = 65536
HEURISTIC_SAMPLE_SIZE = 4_000_000  # Increased to 4MB for better detection
DEFAULT_TIMEOUT = 300  # 5 minutes for volatility commands
MIN_FILE_SIZE = 1024  # 1KB minimum for memory dumps
MAX_WORKERS = 4  # Parallel plugin execution
DEFAULT_TERMINAL_WIDTH = 100  # Fallback if terminal width can't be detected

# ANSI Color Codes
class ColorCode:
    """ANSI color codes for terminal output"""
    RESET = '\033[0m'
    BOLD = '\033[1m'
    
    # Foreground colors
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    GRAY = '\033[90m'
    
    # Background colors
    BG_RED = '\033[101m'
    BG_GREEN = '\033[102m'
    BG_YELLOW = '\033[103m'

# Format Magic Bytes (first 16 bytes typically)
FORMAT_SIGNATURES = {
    'WINDOWS_CRASH_DUMP': [
        b'PAGEDUMP',  # Windows crash dump
        b'PAGE',      # Windows minidump
        b'MDMP',      # Windows minidump
    ],
    'WINDOWS_HIBERNATION': [
        b'hibr',      # Windows hibernation file
        b'\x81\x00\x00\x00',  # Hibernation signature
    ],
    'ELF_CORE': [
        b'\x7fELF',   # ELF format (Linux core dumps)
    ],
    'LIME': [
        b'EMiL',      # LiME format (Linux Memory Extractor)
    ],
    'VMWARE': [
        b'.vmem',     # VMware memory file
    ],
    'VIRTUALBOX': [
        b'VirtualBox',  # VirtualBox saved state
    ],
}

# OS Detection signatures (expanded)
WINDOWS_SIGNATURES = [
    b"SystemRoot",
    b"KDBG",
    b"ntoskrnl",
    b"\\Windows\\",
    b"\\WINDOWS\\",
    b"MZ\x90\x00",  # PE header
    b"_EPROCESS",
    b"_KTHREAD",
]

LINUX_SIGNATURES = [
    b"Linux version",
    b"/lib/modules/",
    b"/usr/bin/",
    b"/etc/",
    b"task_struct",
    b"init_task",
]

MAC_SIGNATURES = [
    b"Darwin Kernel",
    b"com.apple.",
    b"/System/Library/",
    b"__PAGEZERO",
    b"Mach-O",
]

# Comprehensive plugin lists
WINDOWS_PLUGINS = {
    'essential': [
        'windows.info',
        'windows.pslist',
        'windows.pstree',
        'windows.cmdline',
    ],
    'network': [
        'windows.netscan',
        'windows.netstat',
    ],
    'registry': [
        'windows.registry.hivelist',
        'windows.registry.printkey',
    ],
    'malware': [
        'windows.malfind',
        'windows.dlllist',
        'windows.handles',
    ],
    'advanced': [
        'windows.filescan',
        'windows.driverscan',
        'windows.svcscan',
        'windows.envars',
        'windows.sessions',
    ]
}

LINUX_PLUGINS = {
    'essential': [
        'linux.bash',
        'linux.pslist',
        'linux.pstree',
    ],
    'network': [
        'linux.sockstat',
    ],
    'advanced': [
        'linux.lsmod',
        'linux.lsof',
        'linux.mountinfo',
        'linux.proc',
    ]
}

MACOS_PLUGINS = {
    'essential': [
        'mac.pslist',
        'mac.pstree',
    ],
    'network': [
        'mac.netstat',
    ],
    'advanced': [
        'mac.lsmod',
        'mac.lsof',
    ]
}


class DumpFormat(Enum):
    """Supported memory dump formats"""
    RAW = "raw"
    WINDOWS_CRASH = "windows_crash_dump"
    WINDOWS_HIBERNATION = "windows_hibernation"
    ELF_CORE = "elf_core"
    LIME = "lime"
    VMWARE = "vmware"
    VIRTUALBOX = "virtualbox"
    UNKNOWN = "unknown"


class OSType(Enum):
    """Supported operating systems"""
    WINDOWS = "Windows"
    LINUX = "Linux"
    MACOS = "macOS"
    UNKNOWN = "Unknown"


@dataclass
class AnalysisProgress:
    """Progress tracking for background integration"""
    stage: str
    current: int
    total: int
    message: str
    percentage: float


@dataclass
class FormatInfo:
    """Memory dump format information"""
    format_type: DumpFormat
    confidence: int
    evidence: List[str]
    size_bytes: int
    is_compressed: bool


class MemflowError(Exception):
    """Base exception for Memflow CLI errors"""
    pass


class VolatilityNotFoundError(MemflowError):
    """Raised when Volatility3 cannot be located"""
    pass


class UnsupportedFormatError(MemflowError):
    """Raised when dump format is not supported"""
    pass


# ---------------------------------------------------------
# Progress Callback System (for background integration)
# ---------------------------------------------------------

class ProgressTracker:
    """Thread-safe progress tracking with callback support"""
    
    def __init__(self, callback: Optional[Callable[[AnalysisProgress], None]] = None):
        self.callback = callback
        self._lock = threading.Lock()
        self._current_stage = "Initializing"
        self._stages = []
        
    def set_stages(self, stages: List[str]):
        """Set the list of analysis stages"""
        with self._lock:
            self._stages = stages
    
    def update(self, stage: str, current: int, total: int, message: str = ""):
        """Update progress and trigger callback"""
        with self._lock:
            self._current_stage = stage
            
            # Calculate overall percentage
            if self._stages and stage in self._stages:
                stage_idx = self._stages.index(stage)
                stage_weight = 100.0 / len(self._stages)
                base_percentage = stage_idx * stage_weight
                stage_percentage = (current / total * stage_weight) if total > 0 else 0
                overall_percentage = base_percentage + stage_percentage
            else:
                overall_percentage = (current / total * 100) if total > 0 else 0
            
            progress = AnalysisProgress(
                stage=stage,
                current=current,
                total=total,
                message=message,
                percentage=min(100.0, overall_percentage)
            )
            
            if self.callback:
                try:
                    self.callback(progress)
                except Exception as e:
                    print(f"[!] Progress callback error: {e}", file=sys.stderr)


# ---------------------------------------------------------
# Format Detection
# ---------------------------------------------------------

def detect_dump_format(path: str, progress: Optional[ProgressTracker] = None) -> FormatInfo:
    """
    Detect memory dump format using magic bytes and structure analysis.
    
    Args:
        path: Path to memory dump file
        progress: Optional progress tracker
        
    Returns:
        FormatInfo object with detection results
    """
    if progress:
        progress.update("Format Detection", 0, 3, "Reading file header")
    
    size_bytes = os.path.getsize(path)
    
    try:
        with open(path, "rb") as f:
            # Read first 512 bytes for magic byte detection
            header = f.read(512)
            
            if progress:
                progress.update("Format Detection", 1, 3, "Analyzing signatures")
            
            # Check for specific format signatures
            for format_name, signatures in FORMAT_SIGNATURES.items():
                for sig in signatures:
                    if sig in header[:64]:
                        format_type = _map_format_name(format_name)
                        return FormatInfo(
                            format_type=format_type,
                            confidence=90,
                            evidence=[f"Found {format_name} signature: {sig[:8]}"],
                            size_bytes=size_bytes,
                            is_compressed=False
                        )
            
            if progress:
                progress.update("Format Detection", 2, 3, "Checking compression")
            
            # Check for compression
            is_compressed = _check_compression(header)
            
            # Default to RAW format
            if progress:
                progress.update("Format Detection", 3, 3, "Complete")
            
            return FormatInfo(
                format_type=DumpFormat.RAW,
                confidence=50,
                evidence=["No specific format signatures found, assuming raw dump"],
                size_bytes=size_bytes,
                is_compressed=is_compressed
            )
            
    except Exception as e:
        raise MemflowError(f"Format detection failed: {e}")


def _map_format_name(format_name: str) -> DumpFormat:
    """Map format signature name to DumpFormat enum"""
    mapping = {
        'WINDOWS_CRASH_DUMP': DumpFormat.WINDOWS_CRASH,
        'WINDOWS_HIBERNATION': DumpFormat.WINDOWS_HIBERNATION,
        'ELF_CORE': DumpFormat.ELF_CORE,
        'LIME': DumpFormat.LIME,
        'VMWARE': DumpFormat.VMWARE,
        'VIRTUALBOX': DumpFormat.VIRTUALBOX,
    }
    return mapping.get(format_name, DumpFormat.UNKNOWN)


def _check_compression(header: bytes) -> bool:
    """Check if file appears to be compressed"""
    compression_signatures = [
        b'\x1f\x8b',  # gzip
        b'BZ',        # bzip2
        b'\x50\x4b',  # zip
        b'\xfd\x37',  # xz
    ]
    return any(header.startswith(sig) for sig in compression_signatures)


# ---------------------------------------------------------
# Enhanced OS Detection
# ---------------------------------------------------------

def enhanced_os_detection(path: str, progress: Optional[ProgressTracker] = None) -> Tuple[OSType, List[str], int]:
    """
    Multi-stage OS detection with improved accuracy.
    
    Args:
        path: Path to memory dump
        progress: Optional progress tracker
        
    Returns:
        Tuple of (OS type, evidence list, confidence score 0-100)
    """
    if progress:
        progress.update("OS Detection", 0, 2, "Scanning for OS signatures")
    
    try:
        with open(path, "rb") as f:
            # Read larger sample for better detection
            sample = f.read(HEURISTIC_SAMPLE_SIZE)
        
        # Count signature occurrences with position weighting
        windows_score = _calculate_signature_score(sample, WINDOWS_SIGNATURES)
        linux_score = _calculate_signature_score(sample, LINUX_SIGNATURES)
        mac_score = _calculate_signature_score(sample, MAC_SIGNATURES)
        
        if progress:
            progress.update("OS Detection", 1, 2, "Analyzing kernel structures")
        
        # Determine OS with confidence
        scores = {
            OSType.WINDOWS: windows_score,
            OSType.LINUX: linux_score,
            OSType.MACOS: mac_score,
        }
        
        detected_os = max(scores, key=scores.get)
        max_score = scores[detected_os]
        
        if max_score > 0:
            confidence = min(100, 50 + max_score)
            evidence = _generate_evidence(detected_os, sample)
            
            if progress:
                progress.update("OS Detection", 2, 2, f"Detected {detected_os.value}")
            
            return (detected_os, evidence, confidence)
        
        if progress:
            progress.update("OS Detection", 2, 2, "No OS detected")
        
        return (OSType.UNKNOWN, ["No OS-specific signatures found"], 0)
        
    except Exception as e:
        return (OSType.UNKNOWN, [f"Error during OS detection: {e}"], 0)


def _calculate_signature_score(sample: bytes, signatures: List[bytes]) -> int:
    """Calculate weighted score based on signature occurrences and positions"""
    score = 0
    sample_len = len(sample)
    
    for sig in signatures:
        count = sample.count(sig)
        if count > 0:
            # Find first occurrence position
            pos = sample.find(sig)
            # Earlier occurrences get higher weight
            position_weight = 1.0 if pos < sample_len // 4 else 0.5
            score += count * 10 * position_weight
    
    return int(score)


def _generate_evidence(os_type: OSType, sample: bytes) -> List[str]:
    """Generate evidence list for detected OS"""
    evidence = []
    
    if os_type == OSType.WINDOWS:
        sigs = WINDOWS_SIGNATURES
        os_name = "Windows"
    elif os_type == OSType.LINUX:
        sigs = LINUX_SIGNATURES
        os_name = "Linux"
    elif os_type == OSType.MACOS:
        sigs = MAC_SIGNATURES
        os_name = "macOS"
    else:
        return ["Unknown OS"]
    
    found_sigs = [sig for sig in sigs if sig in sample]
    if found_sigs:
        evidence.append(f"Found {len(found_sigs)} {os_name} kernel signature(s)")
        # Add specific signatures found (without nested indentation)
        for sig in found_sigs[:3]:  # Limit to first 3
            try:
                sig_str = sig.decode('utf-8', errors='ignore')[:20]
                evidence.append(f"Signature: {sig_str}")
            except:
                evidence.append(f"Binary signature found")
    
    return evidence


# ---------------------------------------------------------
# Utility Functions
# ---------------------------------------------------------

def supports_color() -> bool:
    """
    Check if the terminal supports color output.
    
    Returns:
        True if colors are supported, False otherwise
    """
    # Check if running in a TTY
    if not hasattr(sys.stdout, 'isatty') or not sys.stdout.isatty():
        return False
    
    # Check for NO_COLOR environment variable
    if os.environ.get('NO_COLOR'):
        return False
    
    # Windows 10+ supports ANSI colors
    if platform.system() == 'Windows':
        try:
            # Enable ANSI escape sequences on Windows
            import ctypes
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
            return True
        except Exception:
            return False
    
    # Unix-like systems generally support colors
    return True


def colorize(text: str, color: str, use_color: bool = True) -> str:
    """
    Colorize text with ANSI color codes.
    
    Args:
        text: Text to colorize
        color: Color code from ColorCode class
        use_color: Whether to actually apply colors
        
    Returns:
        Colorized text or plain text if colors disabled
    """
    if not use_color:
        return text
    return f"{color}{text}{ColorCode.RESET}"


def format_elapsed_time(seconds: float) -> str:
    """
    Format elapsed time in a human-readable format.
    
    Args:
        seconds: Time in seconds
        
    Returns:
        Formatted time string (e.g., "2.3s", "1m 30s", "1h 5m")
    """
    if seconds < 1:
        return f"{seconds*1000:.0f}ms"
    elif seconds < 60:
        return f"{seconds:.1f}s"
    elif seconds < 3600:
        minutes = int(seconds // 60)
        secs = int(seconds % 60)
        return f"{minutes}m {secs}s"
    else:
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        return f"{hours}h {minutes}m"

def get_terminal_width() -> int:
    """
    Get the current terminal width.
    
    Returns:
        Terminal width in characters, or DEFAULT_TERMINAL_WIDTH if detection fails
    """
    try:
        # Check if stdout is a TTY (terminal)
        if not sys.stdout.isatty():
            return DEFAULT_TERMINAL_WIDTH
        
        # Try to get terminal size
        size = shutil.get_terminal_size(fallback=(DEFAULT_TERMINAL_WIDTH, 24))
        return min(size.columns, 200)  # Cap at 200 to prevent excessive padding
    except Exception:
        return DEFAULT_TERMINAL_WIDTH


# ---------------------------------------------------------
# Volatility3 Detection (Enhanced)
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
    for name in ["vol.exe", "vol.cmd", "vol.bat", "vol3.exe"]:
        path = shutil.which(name)
        if path:
            return path

    # Check common installation directories
    possible_paths = [
        Path(os.getenv("LOCALAPPDATA", "")) / "Programs" / "Python",
        Path("C:/Program Files/Volatility3"),
        Path("C:/Program Files (x86)/Volatility3"),
        Path.home() / "AppData" / "Local" / "Programs" / "Python",
        Path.home() / "volatility3",
    ]

    for base_path in possible_paths:
        if base_path.exists():
            for pattern in ["**/vol.exe", "**/vol.cmd", "**/vol3.exe"]:
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

    # Check common installation paths
    possible_paths = [
        Path.home() / "volatility3" / "vol.py",
        Path("/opt/volatility3/vol.py"),
        Path("/usr/local/bin/vol"),
    ]
    
    for path in possible_paths:
        if path.exists():
            return str(path)

    return _try_python_module()


def _try_python_module() -> Optional[str]:
    """Try to use Volatility3 as a Python module"""
    try:
        __import__("volatility3")
        return f'"{sys.executable}" -m volatility3'
    except ImportError:
        return None


# ---------------------------------------------------------
# Volatility Command Execution (Enhanced)
# ---------------------------------------------------------

def run_vol(command: str, dump_path: str, timeout: int = DEFAULT_TIMEOUT, 
            silent: bool = False) -> Optional[str]:
    """
    Execute a Volatility3 command on the memory dump.
    
    Args:
        command: Volatility plugin command (e.g., "windows.info")
        dump_path: Path to the memory dump file
        timeout: Command timeout in seconds
        silent: Suppress error messages
        
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
        
        # Log error if available and not silent
        if proc.stderr and not silent:
            # Only show first line of error to avoid spam
            error_line = proc.stderr.split('\n')[0][:200]
            print(f"[!] Plugin '{command}' failed: {error_line}", file=sys.stderr)
        
        return None
        
    except subprocess.TimeoutExpired:
        if not silent:
            print(f"[!] Command timeout after {timeout}s: {command}", file=sys.stderr)
        return None
    except Exception as e:
        if not silent:
            print(f"[!] Error running volatility: {e}", file=sys.stderr)
        return None


def run_vol_parallel(plugins: List[str], dump_path: str, 
                     progress: Optional[ProgressTracker] = None,
                     max_workers: int = MAX_WORKERS) -> Dict[str, Optional[str]]:
    """
    Execute multiple Volatility plugins in parallel.
    
    Args:
        plugins: List of plugin commands
        dump_path: Path to memory dump
        progress: Optional progress tracker
        max_workers: Maximum parallel workers
        
    Returns:
        Dictionary mapping plugin names to their outputs and failure reasons
    """
    results = {}
    failures = {}  # Track failure reasons
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all plugin tasks
        future_to_plugin = {
            executor.submit(run_vol, plugin, dump_path, DEFAULT_TIMEOUT, True): plugin
            for plugin in plugins
        }
        
        completed = 0
        total = len(plugins)
        
        # Collect results as they complete
        for future in as_completed(future_to_plugin):
            plugin = future_to_plugin[future]
            completed += 1
            
            try:
                output = future.result()
                results[plugin] = output
                
                if progress:
                    status = "✓" if output else "✗"
                    # Truncate plugin name if needed to fit terminal
                    plugin_display = plugin if len(plugin) <= 30 else plugin[:27] + "..."
                    progress.update("Plugin Execution", completed, total, 
                                  f"{status} {plugin_display} ({completed}/{total})")
                
                if not output:
                    failures[plugin] = "No output returned"
                    
            except Exception as e:
                results[plugin] = None
                failures[plugin] = str(e)
                if progress:
                    plugin_display = plugin if len(plugin) <= 30 else plugin[:27] + "..."
                    progress.update("Plugin Execution", completed, total, 
                                  f"✗ {plugin_display} ({completed}/{total})")
    
    # Store failures in results for later reporting
    results['_failures'] = failures
    
    return results


# ---------------------------------------------------------
# Output Parsers (Enhanced)
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
        
        if len(parts) >= 8:
            process = {
                "PID": parts[0].strip(),
                "PPID": parts[1].strip(),
                "ImageFileName": parts[2].strip(),
                "Offset": parts[3].strip(),
                "Threads": parts[4].strip(),
                "Handles": parts[5].strip(),
                "SessionId": parts[6].strip(),
                "Wow64": parts[7].strip(),
                "CreateTime": parts[8].strip() if len(parts) > 8 else "N/A",
                "ExitTime": parts[9].strip() if len(parts) > 9 else "N/A"
            }
            processes.append(process)
    
    return processes if processes else None


def parse_windows_netscan(raw_output: Optional[str]) -> Optional[List[Dict[str, str]]]:
    """Parse windows.netscan output for network connections"""
    if not raw_output:
        return None
    
    connections = []
    lines = raw_output.strip().split('\n')
    
    # Find header
    header_idx = -1
    for i, line in enumerate(lines):
        if 'Offset' in line and 'Proto' in line and 'LocalAddr' in line:
            header_idx = i
            break
    
    if header_idx == -1:
        return None
    
    for line in lines[header_idx + 1:]:
        line = line.strip()
        if not line or line.startswith('==='):
            continue
        
        parts = re.split(r'\t+|\s{2,}', line)
        if len(parts) >= 5:
            connections.append({
                "Offset": parts[0].strip(),
                "Proto": parts[1].strip(),
                "LocalAddr": parts[2].strip(),
                "ForeignAddr": parts[3].strip(),
                "State": parts[4].strip() if len(parts) > 4 else "N/A",
                "PID": parts[5].strip() if len(parts) > 5 else "N/A",
                "Owner": parts[6].strip() if len(parts) > 6 else "N/A",
            })
    
    return connections if connections else None


def parse_generic_table(raw_output: Optional[str]) -> Optional[List[Dict[str, str]]]:
    """Generic parser for table-formatted Volatility output"""
    if not raw_output:
        return None
    
    lines = raw_output.strip().split('\n')
    
    # Find header line (contains multiple capitalized words)
    header_idx = -1
    headers = []
    
    for i, line in enumerate(lines):
        if re.search(r'[A-Z][a-z]+.*[A-Z][a-z]+', line):
            # Potential header line
            parts = re.split(r'\t+|\s{2,}', line.strip())
            if len(parts) >= 2:
                header_idx = i
                headers = [h.strip() for h in parts]
                break
    
    if header_idx == -1 or not headers:
        return None
    
    results = []
    for line in lines[header_idx + 1:]:
        line = line.strip()
        if not line or line.startswith('==='):
            continue
        
        parts = re.split(r'\t+|\s{2,}', line)
        if len(parts) >= len(headers):
            row = {headers[i]: parts[i].strip() for i in range(len(headers))}
            results.append(row)
    
    return results if results else None


# ---------------------------------------------------------
# File Hashing
# ---------------------------------------------------------

def file_hashes(path: str, progress: Optional[ProgressTracker] = None) -> Dict[str, str]:
    """
    Calculate MD5, SHA1, and SHA256 hashes of a file.
    
    Args:
        path: Path to the file
        progress: Optional progress tracker
        
    Returns:
        Dictionary containing hash values
    """
    md5 = hashlib.md5()
    sha1 = hashlib.sha1()
    sha256 = hashlib.sha256()

    try:
        file_size = os.path.getsize(path)
        bytes_read = 0
        
        with open(path, "rb") as f:
            while chunk := f.read(BUFFER_SIZE):
                md5.update(chunk)
                sha1.update(chunk)
                sha256.update(chunk)
                
                bytes_read += len(chunk)
                
                if progress and file_size > 0:
                    progress.update("Hashing", bytes_read, file_size, 
                                  f"Calculating hashes ({bytes_read / file_size * 100:.1f}%)")

        return {
            "md5": md5.hexdigest(),
            "sha1": sha1.hexdigest(),
            "sha256": sha256.hexdigest()
        }
    except Exception as e:
        raise MemflowError(f"Failed to calculate hashes: {e}")


# ---------------------------------------------------------
# Analysis Helpers (Enhanced)
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
    elif major == "11" and minor == "0":
        version_name = "Windows 11"
    
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
        "kernel_base": windows_info.get("KernelBase", windows_info.get("Kernel Base", "Unknown"))
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
    
    browser_names = ["iexplore.exe", "firefox.exe", "chrome.exe", "msedge.exe", "opera.exe", "brave.exe"]
    system_names = ["System", "smss.exe", "csrss.exe", "wininit.exe", "services.exe", "lsass.exe", "svchost.exe"]
    suspicious_indicators = ["FTK Imager.exe", "winpmem", "dumpit", "procdump", "mimikatz", "psexec"]
    
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
        elif any(susp.lower() in name.lower() for susp in suspicious_indicators):
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


def analyze_network(connections: Optional[List[Dict[str, str]]], 
                   plugin_failed: bool = False,
                   plugin_level: str = "essential") -> Dict[str, Any]:
    """Analyze network connections with enhanced error reporting"""
    if plugin_failed:
        return {
            "detected": False, 
            "count": 0,
            "failure_reason": "Network plugin execution failed",
            "failure_type": "plugin_error"
        }
    
    if not connections:
        # Check if network plugins would be available at this level
        if plugin_level == "essential":
            return {
                "detected": False, 
                "count": 0,
                "failure_reason": f"Network analysis not available at '{plugin_level}' level",
                "suggestion": "Use --level standard or higher to include network analysis",
                "failure_type": "not_included"
            }
        else:
            return {
                "detected": False, 
                "count": 0,
                "failure_reason": "No network data available (plugin may not be compatible with this dump)",
                "failure_type": "no_data"
            }
    
    # Categorize connections
    established = [c for c in connections if c.get("State") == "ESTABLISHED"]
    listening = [c for c in connections if c.get("State") == "LISTENING"]
    
    # Extract unique remote IPs
    remote_ips = set()
    for conn in connections:
        foreign = conn.get("ForeignAddr", "")
        if ":" in foreign:
            ip = foreign.split(":")[0]
            if ip and ip != "0.0.0.0" and ip != "*" and not ip.startswith("127."):
                remote_ips.add(ip)
    
    return {
        "detected": True,
        "total_connections": len(connections),
        "established": len(established),
        "listening": len(listening),
        "unique_remote_ips": len(remote_ips),
        "remote_ips": list(remote_ips)[:20],  # Limit to 20
        "sample_connections": connections[:10]  # First 10 connections
    }


def determine_os_confidence(os_detection: Tuple[OSType, List[str], int], 
                           windows_info: Optional[Dict], 
                           linux_success: bool, 
                           mac_success: bool) -> Dict[str, Any]:
    """
    Determine final OS detection with confidence level.
    
    Args:
        os_detection: Results from enhanced OS detection
        windows_info: Parsed Windows info (if any)
        linux_success: Whether Linux plugins succeeded
        mac_success: Whether Mac plugins succeeded
        
    Returns:
        OS detection summary with confidence
    """
    os_type, evidence, heuristic_confidence = os_detection
    
    # Volatility confirmation
    volatility_confirms = {
        OSType.WINDOWS: windows_info is not None,
        OSType.LINUX: linux_success,
        OSType.MACOS: mac_success,
    }
    
    # Calculate final confidence
    if volatility_confirms.get(os_type, False):
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
        "operating_system": os_type.value,
        "confidence_score": final_confidence,
        "confidence_level": confidence_level,
        "detection_method": detection_method,
        "evidence": evidence,
        "volatility_support": {
            "windows_compatible": volatility_confirms[OSType.WINDOWS],
            "linux_compatible": volatility_confirms[OSType.LINUX],
            "macos_compatible": volatility_confirms[OSType.MACOS]
        }
    }


# ---------------------------------------------------------
# Full Analysis Workflow (Enhanced)
# ---------------------------------------------------------

def full_analysis(path: str, 
                 progress_callback: Optional[Callable[[AnalysisProgress], None]] = None,
                 plugin_level: str = "essential",
                 use_color: bool = None) -> Dict[str, Any]:
    """
    Perform comprehensive analysis of a memory dump file.
    
    Args:
        path: Path to the memory dump file
        progress_callback: Optional callback for progress updates (for background integration)
        plugin_level: Plugin execution level - "essential", "standard", "advanced", "full"
        use_color: Whether to use colored output (auto-detected if None)
        
    Returns:
        Dictionary containing complete analysis results
    """
    # Auto-detect color support if not specified
    if use_color is None:
        use_color = supports_color()
    
    # Track timing for each stage
    stage_timings = {}
    analysis_start_time = time.time()
    
    # Initialize progress tracker
    progress = ProgressTracker(progress_callback)
    progress.set_stages([
        "Validation",
        "Format Detection",
        "Hashing",
        "OS Detection",
        "Plugin Execution",
        "Analysis",
        "Finalization"
    ])
    
    # Validate input
    progress.update("Validation", 0, 2, "Checking file existence")
    
    if not os.path.exists(path):
        raise MemflowError(f"File not found: {path}")
    
    if not os.path.isfile(path):
        raise MemflowError(f"Not a file: {path}")
    
    progress.update("Validation", 1, 2, "Checking file size")
    size_bytes = os.path.getsize(path)
    
    if size_bytes < MIN_FILE_SIZE:
        raise MemflowError(f"File too small ({size_bytes} bytes), likely not a valid memory dump")
    
    progress.update("Validation", 2, 2, "Validation complete")
    
    # Basic file information
    human_size = _format_size(size_bytes)
    
    # Format detection
    stage_start = time.time()
    print(colorize("\n[*] Detecting dump format...", ColorCode.BLUE, use_color))
    format_info = detect_dump_format(path, progress)
    stage_timings['format_detection'] = time.time() - stage_start
    print(colorize(f"\n[+] Format: {format_info.format_type.value} (confidence: {format_info.confidence}%)", ColorCode.GREEN, use_color) + 
          colorize(f" [{format_elapsed_time(stage_timings['format_detection'])}]", ColorCode.GRAY, use_color))
    
    # Calculate hashes
    stage_start = time.time()
    print(colorize("\n[*] Calculating file hashes...", ColorCode.BLUE, use_color))
    hashes = file_hashes(path, progress)
    stage_timings['hashing'] = time.time() - stage_start
    print(colorize(f"[+] Hashes calculated", ColorCode.GREEN, use_color) + 
          colorize(f" [{format_elapsed_time(stage_timings['hashing'])}]", ColorCode.GRAY, use_color))

    # Enhanced OS detection
    stage_start = time.time()
    print(colorize("\n[*] Running enhanced OS detection...", ColorCode.BLUE, use_color))
    os_detection = enhanced_os_detection(path, progress)
    os_type, evidence, confidence = os_detection
    stage_timings['os_detection'] = time.time() - stage_start
    
    print(colorize(f"\n[+] OS Detection: {os_type.value} (confidence: {confidence}%)", ColorCode.GREEN, use_color) + 
          colorize(f" [{format_elapsed_time(stage_timings['os_detection'])}]", ColorCode.GRAY, use_color))
    
    # Determine which plugins to run
    plugins_to_run = _select_plugins(os_type, plugin_level)
    
    stage_start = time.time()
    print(colorize(f"\n[*] Running {len(plugins_to_run)} Volatility3 plugins...", ColorCode.BLUE, use_color))
    
    # Run plugins in parallel
    plugin_results = run_vol_parallel(plugins_to_run, path, progress)
    stage_timings['plugin_execution'] = time.time() - stage_start
    
    # Extract failures and remove from results
    failures = plugin_results.pop('_failures', {})
    
    # Count successful plugins
    successful = sum(1 for v in plugin_results.values() if v is not None)
    success_msg = f"\n[+] Completed: {successful}/{len(plugins_to_run)} plugins successful"
    print(colorize(success_msg, ColorCode.GREEN if successful == len(plugins_to_run) else ColorCode.YELLOW, use_color) + 
          colorize(f" [{format_elapsed_time(stage_timings['plugin_execution'])}]", ColorCode.GRAY, use_color))
    
    # Report failures if any
    if failures:
        print(colorize(f"[!] {len(failures)} plugin(s) failed:", ColorCode.YELLOW, use_color))
        for plugin, reason in list(failures.items())[:3]:  # Show first 3
            print(colorize(f"    - {plugin}: {reason[:60]}", ColorCode.RED, use_color))
    
    # Parse outputs
    progress.update("Analysis", 0, 5, "Parsing plugin outputs")
    
    windows_info = parse_windows_info(plugin_results.get("windows.info"))
    processes = parse_windows_pslist(plugin_results.get("windows.pslist"))
    network_connections = parse_windows_netscan(plugin_results.get("windows.netscan"))
    
    # Additional parsers for other plugins
    cmdline_data = parse_generic_table(plugin_results.get("windows.cmdline"))
    dll_data = parse_generic_table(plugin_results.get("windows.dlllist"))
    
    progress.update("Analysis", 1, 5, "Analyzing system information")
    
    # Build comprehensive analysis
    os_final = determine_os_confidence(
        os_detection,
        windows_info,
        plugin_results.get("linux.pslist") is not None,
        plugin_results.get("mac.pslist") is not None
    )
    
    progress.update("Analysis", 2, 5, "Analyzing processes")
    system_info = extract_os_info(windows_info)
    process_analysis = analyze_processes(processes)
    
    progress.update("Analysis", 3, 5, "Analyzing network")
    # Check if network plugins failed
    network_plugin_failed = all(
        plugin_results.get(p) is None 
        for p in ['windows.netscan', 'windows.netstat', 'linux.sockstat', 'mac.netstat']
        if p in plugins_to_run
    )
    network_analysis = analyze_network(network_connections, network_plugin_failed, plugin_level)
    
    progress.update("Analysis", 4, 5, "Compiling results")
    
    # Build final report
    result = {
        "analysis_metadata": {
            "analyzer": "Memflow CLI v2.0",
            "analysis_date": datetime.now().isoformat(),
            "dump_filename": os.path.basename(path),
            "dump_path": str(Path(path).resolve()),
            "plugin_level": plugin_level,
            "plugins_executed": len(plugins_to_run),
            "plugins_successful": successful
        },
        "file_information": {
            "size_bytes": size_bytes,
            "size_human": human_size,
            "format": {
                "type": format_info.format_type.value,
                "confidence": format_info.confidence,
                "evidence": format_info.evidence,
                "compressed": format_info.is_compressed
            },
            "hashes": hashes
        },
        "os_detection": os_final,
        "system_information": system_info,
        "process_analysis": process_analysis,
        "network_analysis": network_analysis,
        "advanced_artifacts": {
            "command_lines": cmdline_data[:20] if cmdline_data else None,  # Limit output
            "loaded_dlls_sample": dll_data[:10] if dll_data else None,
        },
        "raw_volatility_data": {
            "windows_info": windows_info if windows_info else None,
            "process_list": processes if processes else None,
            "network_connections": network_connections if network_connections else None,
            "plugins_attempted": {plugin: (result is not None) for plugin, result in plugin_results.items()}
        },
        "plugin_failures": failures if failures else None,
        "performance": {
            "total_time": time.time() - analysis_start_time,
            "stage_timings": stage_timings
        },
        "analysis_level": plugin_level  # Store for reference
    }
    
    progress.update("Finalization", 1, 1, "Analysis complete")
    
    # Clear the progress line before returning
    print()  # Add newline to clear progress display
    
    return result


def _select_plugins(os_type: OSType, level: str) -> List[str]:
    """Select plugins to run based on OS and level"""
    plugins = []
    
    if os_type == OSType.WINDOWS:
        plugins.extend(WINDOWS_PLUGINS['essential'])
        if level in ['standard', 'advanced', 'full']:
            plugins.extend(WINDOWS_PLUGINS['network'])
        if level in ['advanced', 'full']:
            plugins.extend(WINDOWS_PLUGINS['malware'])
        if level == 'full':
            plugins.extend(WINDOWS_PLUGINS['advanced'])
    
    elif os_type == OSType.LINUX:
        plugins.extend(LINUX_PLUGINS['essential'])
        if level in ['standard', 'advanced', 'full']:
            plugins.extend(LINUX_PLUGINS['network'])
        if level in ['advanced', 'full']:
            plugins.extend(LINUX_PLUGINS['advanced'])
    
    elif os_type == OSType.MACOS:
        plugins.extend(MACOS_PLUGINS['essential'])
        if level in ['standard', 'advanced', 'full']:
            plugins.extend(MACOS_PLUGINS['network'])
        if level in ['advanced', 'full']:
            plugins.extend(MACOS_PLUGINS['advanced'])
    
    else:
        # Unknown OS - try essential plugins from all
        plugins.extend(WINDOWS_PLUGINS['essential'])
        plugins.extend(LINUX_PLUGINS['essential'][:2])  # Just a couple
    
    return plugins


def _format_size(bytes_size: int) -> str:
    """Format byte size to human-readable string."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_size < 1024.0:
            return f"{bytes_size:.2f} {unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.2f} PB"


# ---------------------------------------------------------
# Background Integration API
# ---------------------------------------------------------

class MemflowAnalyzer:
    """
    Class-based interface for background integration.
    Provides async-friendly methods and progress tracking.
    """
    
    def __init__(self, progress_callback: Optional[Callable[[AnalysisProgress], None]] = None):
        """
        Initialize analyzer with optional progress callback.
        
        Args:
            progress_callback: Function to call with progress updates
        """
        self.progress_callback = progress_callback
        self._current_analysis = None
    
    def analyze(self, dump_path: str, plugin_level: str = "essential", use_color: bool = None) -> Dict[str, Any]:
        """
        Analyze a memory dump file.
        
        Args:
            dump_path: Path to memory dump
            plugin_level: Analysis depth - "essential", "standard", "advanced", "full"
            use_color: Whether to use colored output (auto-detected if None)
            
        Returns:
            Analysis results dictionary
        """
        return full_analysis(dump_path, self.progress_callback, plugin_level, use_color)
    
    def quick_scan(self, dump_path: str) -> Dict[str, Any]:
        """
        Quick scan - format detection and OS detection only.
        
        Args:
            dump_path: Path to memory dump
            
        Returns:
            Quick scan results
        """
        progress = ProgressTracker(self.progress_callback)
        
        # Validate
        if not os.path.exists(dump_path):
            raise MemflowError(f"File not found: {dump_path}")
        
        size_bytes = os.path.getsize(dump_path)
        
        # Format detection
        format_info = detect_dump_format(dump_path, progress)
        
        # OS detection
        os_detection = enhanced_os_detection(dump_path, progress)
        os_type, evidence, confidence = os_detection
        
        return {
            "file": {
                "path": dump_path,
                "size_bytes": size_bytes,
                "size_human": _format_size(size_bytes)
            },
            "format": {
                "type": format_info.format_type.value,
                "confidence": format_info.confidence
            },
            "os": {
                "type": os_type.value,
                "confidence": confidence,
                "evidence": evidence
            }
        }
    
    def get_supported_formats(self) -> List[str]:
        """Get list of supported dump formats"""
        return [fmt.value for fmt in DumpFormat]
    
    def get_supported_os(self) -> List[str]:
        """Get list of supported operating systems"""
        return [os.value for os in OSType]


# ---------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------

def main() -> None:
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Memflow CLI v2.0 - Advanced Memory Dump Analysis Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s full memory.dmp
  %(prog)s full memory.dmp --json report.json --level advanced
  %(prog)s quick memory.dmp
  %(prog)s detect memory.dmp
        """
    )
    
    parser.add_argument(
        "mode",
        choices=["full", "quick", "detect"],
        help="Analysis mode: full (complete analysis), quick (format+OS only), detect (format detection)"
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
        "--level",
        choices=["essential", "standard", "advanced", "full"],
        default="essential",
        help="Analysis depth (default: essential)"
    )
    
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Show detailed output including raw volatility data"
    )

    args = parser.parse_args()

    try:
        # Get terminal width for proper line clearing
        term_width = get_terminal_width()
        
        # Simple progress printer for CLI with proper line clearing
        def print_progress(progress: AnalysisProgress):
            # Clear the line by padding with spaces based on terminal width
            msg = f"[{progress.percentage:5.1f}%] {progress.stage}: {progress.message}"
            # Truncate message if it exceeds terminal width
            if len(msg) > term_width - 1:
                msg = msg[:term_width - 4] + "..."
            print(f"\r{msg:<{term_width}}", end='', flush=True)
        
        analyzer = MemflowAnalyzer(progress_callback=print_progress)
        
        # Detect color support
        use_color = supports_color()
        
        if args.mode == "detect":
            print(f"[*] Detecting format of: {args.dump}\n")
            format_info = detect_dump_format(args.dump)
            print(f"\n[+] Format: {format_info.format_type.value}")
            print(f"[+] Confidence: {format_info.confidence}%")
            print(f"[+] Evidence:")
            for ev in format_info.evidence:
                print(f"    - {ev}")
            
        elif args.mode == "quick":
            print(f"[*] Quick scan of: {args.dump}\n")
            result = analyzer.quick_scan(args.dump)
            print("\n" + "="*70)
            print("QUICK SCAN RESULTS")
            print("="*70)
            print(f"\nFile: {result['file']['size_human']}")
            print(f"Format: {result['format']['type']} ({result['format']['confidence']}% confidence)")
            print(f"OS: {result['os']['type']} ({result['os']['confidence']}% confidence)")
            
            if args.json_out:
                with open(args.json_out, "w", encoding="utf-8") as f:
                    json.dump(result, f, indent=2, ensure_ascii=False)
                print(f"\n[+] Results saved -> {args.json_out}")
        
        elif args.mode == "full":
            print(f"[*] Starting full analysis of: {args.dump}")
            print(f"[*] Analysis level: {args.level}\n")
            
            result = analyzer.analyze(args.dump, args.level, use_color)
            
            print("\n\n" + "="*70)
            print("ANALYSIS COMPLETE")
            print("="*70 + "\n")
            
            # Print summary
            _print_summary(result, args.verbose, use_color)

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


def _print_summary(result: Dict[str, Any], verbose: bool = False, use_color: bool = True) -> None:
    """Print formatted summary of analysis results with color support."""
    
    try:
        # File Information
        print("[FILE INFORMATION]")
        print("-" * 70)
        file_info = result["file_information"]
        print(f"  File: {result['analysis_metadata']['dump_filename']}")
        print(f"  Size: {file_info['size_human']} ({file_info['size_bytes']:,} bytes)")
        print(f"  Format: {file_info['format']['type']} ({file_info['format']['confidence']}% confidence)")
        if file_info['format']['compressed']:
            print(f"  Compression: Detected")
        print(f"  MD5:    {file_info['hashes']['md5']}")
        print(f"  SHA1:   {file_info['hashes']['sha1']}")
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
        for evidence in os_detect["evidence"][:5]:  # Limit to 5
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
        
        # Network Analysis
        net_info = result["network_analysis"]
        if net_info.get("detected"):
            print("\n[NETWORK ANALYSIS]")
            print("-" * 70)
            print(f"  Total Connections: {net_info['total_connections']}")
            print(f"  Established: {net_info['established']} | Listening: {net_info['listening']}")
            print(f"  Unique Remote IPs: {net_info['unique_remote_ips']}")
            if net_info.get("remote_ips"):
                print(f"  Remote IPs (sample):")
                for ip in net_info["remote_ips"][:5]:
                    print(f"    - {ip}")
        elif net_info.get("failure_reason"):
            print("\n[NETWORK ANALYSIS]")
            print("-" * 70)
            print(colorize(f"  {net_info['failure_reason']}", ColorCode.YELLOW, use_color))
        
        # Plugin Statistics and Performance
        print("\n[ANALYSIS STATISTICS]")
        print("-" * 70)
        meta = result["analysis_metadata"]
        print(f"  Plugins Executed: {meta['plugins_executed']}")
        print(f"  Plugins Successful: {meta['plugins_successful']}")
        print(f"  Analysis Level: {meta['plugin_level']}")
        
        # Performance metrics
        if result.get("performance"):
            perf = result["performance"]
            total_time = perf.get("total_time", 0)
            print(f"\n  {colorize('Performance:', ColorCode.CYAN, use_color)}")
            print(f"    Total Time: {colorize(format_elapsed_time(total_time), ColorCode.GREEN, use_color)}")
            
            if perf.get("stage_timings"):
                timings = perf["stage_timings"]
                if timings:
                    print(f"    Stage Breakdown:")
                    for stage, duration in timings.items():
                        stage_name = stage.replace('_', ' ').title()
                        print(f"      - {stage_name}: {format_elapsed_time(duration)}")
        
        print(f"\n  Analysis Date: {meta['analysis_date']}")
        
        # Show plugin failures if any
        if result.get("plugin_failures"):
            print(colorize("\n[PLUGIN FAILURES]", ColorCode.YELLOW, use_color))
            print("-" * 70)
            for plugin, reason in list(result["plugin_failures"].items())[:5]:
                print(colorize(f"  {plugin}:", ColorCode.RED, use_color))
                print(f"    {reason[:100]}")
        
        # Verbose output
        if verbose:
            print(colorize("\n[RAW VOLATILITY DATA]", ColorCode.CYAN, use_color))
            print("-" * 70)
            print(json.dumps(result["raw_volatility_data"], indent=2))
    
    except Exception as e:
        print(f"\n[!] Error printing summary: {e}", file=sys.stderr)
        print("\nFull result:")
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()