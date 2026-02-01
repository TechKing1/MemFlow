"""
Redis client and RQ queue initialization.
This module sets up the Redis connection and creates the job queue.
"""
import redis
from rq import Queue
from config import Config

# Initialize Redis connection
try:
    redis_conn = redis.from_url(
        Config.REDIS_URL,
        decode_responses=True,
        socket_connect_timeout=5
    )
    # Test connection
    redis_conn.ping()
    print("✓ Redis connected successfully")
except redis.ConnectionError as e:
    print(f"✗ Redis connection failed: {e}")
    print("  Make sure Redis server is running on localhost:6381")
    redis_conn = None

# Create RQ Queue for forensics analysis tasks
task_queue = Queue(
    name=Config.RQ_QUEUE_NAME,
    connection=redis_conn
) if redis_conn else None
