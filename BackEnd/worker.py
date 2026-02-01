"""
RQ Worker for processing forensics analysis jobs.

This script starts a worker that listens to the Redis queue
and processes jobs asynchronously.

WINDOWS COMPATIBILITY:
This worker uses burst mode with timeout to properly handle Ctrl+C on Windows.
The worker checks for shutdown signals between job bursts.

Usage:
    python worker.py
"""
import sys
import signal
import time
import logging
from rq import Worker, Queue
from rq.worker import StopRequested
from app.extensions.redis_client import redis_conn
from config import Config

# Configure logging to suppress verbose RQ output
logging.basicConfig(
    level=logging.WARNING,  # Only show warnings and errors
    format='%(message)s'
)

# Global flag for graceful shutdown
shutdown_requested = False

def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully"""
    global shutdown_requested
    if shutdown_requested:
        # Second Ctrl+C - force quit
        print("\n⚠ Force quitting...")
        sys.exit(0)
    
    shutdown_requested = True
    print("\n⚠ Shutdown requested... Finishing current job (Ctrl+C again to force quit)")

def main():
    """Start the RQ worker with Windows-compatible shutdown handling"""
    if not redis_conn:
        print("✗ Cannot start worker: Redis connection failed")
        print("  Make sure Redis server is running on localhost:6381")
        sys.exit(1)
    
    # Register signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    
    print("=" * 70)
    print("RQ Worker - Memory Forensics Analysis")
    print("=" * 70)
    print(f"Queue: {Config.RQ_QUEUE_NAME}")
    print(f"Redis: {Config.REDIS_URL}")
    print("=" * 70)
    
    # Create queue and worker
    queue = Queue(Config.RQ_QUEUE_NAME, connection=redis_conn)
    worker = Worker([queue], connection=redis_conn)
    
    print(f"\n✓ Worker started - Listening on queue: {Config.RQ_QUEUE_NAME}")
    print("  Press Ctrl+C to stop\n")
    
    # Work loop with periodic shutdown checks (Windows-compatible)
    try:
        while not shutdown_requested:
            try:
                # Process jobs in burst mode with timeout
                # This allows the worker to check for shutdown signals periodically
                worker.work(burst=True, max_jobs=1, with_scheduler=False, logging_level='WARNING')
                
                # Small sleep to prevent CPU spinning when queue is empty
                if not shutdown_requested:
                    time.sleep(1)  # Check for new jobs every second
                    
            except StopRequested:
                # RQ's internal shutdown signal - this is expected
                break
                
    except KeyboardInterrupt:
        pass  # Handled by signal handler
    finally:
        print("✓ Worker stopped gracefully\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("✓ Worker stopped\n")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Worker error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
