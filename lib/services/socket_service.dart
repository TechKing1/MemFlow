import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

/// Singleton WebSocket service for real-time case status updates.
/// Connects to Flask-SocketIO backend and broadcasts case_update events.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final List<Function(Map<String, dynamic>)> _listeners = [];

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      print('🟢 WebSocket connected to Flask-SocketIO');
    });

    _socket!.onDisconnect((_) {
      print('🔴 WebSocket disconnected — will reconnect...');
    });

    _socket!.on('case_update', (data) {
      print('📡 case_update received: $data');
      final event = Map<String, dynamic>.from(data as Map);
      for (final listener in _listeners) {
        listener(event);
      }
    });

    _socket!.connect();
  }

  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
