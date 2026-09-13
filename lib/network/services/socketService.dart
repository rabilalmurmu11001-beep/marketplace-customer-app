import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:customer_app/network/api.dart';
import 'package:customer_app/security/secureStorage.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

class SocketService {
  static final SocketService instance = SocketService._internal();
  factory SocketService() => instance;
  SocketService._internal();

  socket_io.Socket? _socket;

  socket_io.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect([String? token]) async {
    final authToken = token ?? await TokenRepository().readToken();

    if (authToken == null || authToken.isEmpty) {
      debugPrint('[SocketService] Cannot connect: No token available.');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('[SocketService] Socket already connected (id: ${_socket!.id}).');
      return;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    try {
      debugPrint('[SocketService] Connecting to socket at $host ...');

      _socket = socket_io.io(
        host,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setAuth({'token': authToken})
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('[SocketService] Connected successfully. Socket ID: ${_socket?.id}');
      });

      _socket!.onConnectError((err) {
        debugPrint('[SocketService] Connection error: $err');
      });

      _socket!.onError((err) {
        debugPrint('[SocketService] Socket error: $err');
      });

      _socket!.onDisconnect((reason) {
        debugPrint('[SocketService] Disconnected: $reason');
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('[SocketService] Exception while connecting: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('[SocketService] Disconnecting socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
