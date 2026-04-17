"""
Flask-SocketIO extension for real-time WebSocket communication.
Emits events to connected Flutter clients when case status changes.
"""
from flask_socketio import SocketIO

# Initialize SocketIO with Redis message queue for cross-process communication.
# The worker runs as a separate process — events go through Redis pubsub → Flask → Flutter.
socketio = SocketIO(
    cors_allowed_origins="*",
    async_mode='threading',
    message_queue='redis://localhost:6382/0'
)


@socketio.on('connect')
def on_connect():
    print("✅ Flutter client connected via WebSocket")


@socketio.on('disconnect')
def on_disconnect():
    print("🔌 Flutter client disconnected")
