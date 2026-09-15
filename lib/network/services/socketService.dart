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

  String? _activeRoomId;

  String? get activeRoomId => _activeRoomId;

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
        // Re-join active room on reconnection if previously joined
        if (_activeRoomId != null) {
          debugPrint('[SocketService] Rejoining active room: $_activeRoomId');
          _socket!.emit('joinRoom', _activeRoomId);
        }
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

  void joinRoom(String roomId) {
    _activeRoomId = roomId;
    if (_socket != null && _socket!.connected) {
      debugPrint('[SocketService] Joining room: $roomId');
      _socket!.emit('joinRoom', roomId);
    } else {
      debugPrint('[SocketService] Socket not connected yet; room $roomId queued.');
    }
  }

  void leaveRoom(String roomId) {
    if (_activeRoomId == roomId) {
      _activeRoomId = null;
    }
    if (_socket != null && _socket!.connected) {
      debugPrint('[SocketService] Leaving room: $roomId');
      _socket!.emit('leaveRoom', roomId);
    }
  }

  void sendMessageToRoom({
    required String roomId,
    required String message,
    String messageType = 'text',
  }) {
    if (_socket != null && _socket!.connected) {
      debugPrint('[SocketService] Emitting sendMessageToRoom -> $roomId: $message');
      _socket!.emit('sendMessageToRoom', {
        'room': roomId,
        'message': message,
        'messageType': messageType,
      });
    } else {
      debugPrint('[SocketService] Socket not connected, could not emit message.');
    }
  }

  void onMessage(void Function(dynamic data) handler) {
    _socket?.on('message', handler);
  }

  void offMessage([void Function(dynamic data)? handler]) {
    if (handler != null) {
      _socket?.off('message', handler);
    } else {
      _socket?.off('message');
    }
  }

  void onMessagesRead(void Function(dynamic data) handler) {
    _socket?.on('messagesRead', handler);
  }

  void offMessagesRead([void Function(dynamic data)? handler]) {
    if (handler != null) {
      _socket?.off('messagesRead', handler);
    } else {
      _socket?.off('messagesRead');
    }
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('[SocketService] Disconnecting socket...');
      _activeRoomId = null;
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
