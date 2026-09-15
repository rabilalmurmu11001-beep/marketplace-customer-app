import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/messageServices.dart';
import '../network/services/socketService.dart';
import '../network/services/userService.dart';
import '../security/secureStorage.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String messageContent;
  final String messageType;
  final String messageStatus; // 'sending', 'sent', 'delivered', 'read', 'failed'
  final DateTime createdAt;
  final String? senderName;
  final String? senderPhoto;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageContent,
    this.messageType = 'text',
    this.messageStatus = 'sent',
    required this.createdAt,
    this.senderName,
    this.senderPhoto,
  });

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? messageContent,
    String? messageType,
    String? messageStatus,
    DateTime? createdAt,
    String? senderName,
    String? senderPhoto,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      messageContent: messageContent ?? this.messageContent,
      messageType: messageType ?? this.messageType,
      messageStatus: messageStatus ?? this.messageStatus,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['createdAt'] != null) {
      parsedDate =
          DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final senderRaw = json['sender'];
    final Map<String, dynamic>? sender = senderRaw is Map
        ? Map<String, dynamic>.from(senderRaw)
        : null;

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      messageContent: json['messageContent']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      messageStatus: json['messageStatus']?.toString() ?? 'sent',
      createdAt: parsedDate,
      senderName:
          sender?['username']?.toString() ?? sender?['name']?.toString(),
      senderPhoto:
          sender?['photo']?.toString() ?? sender?['avatar']?.toString(),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? recipientName;
  final String? recipientPhoto;
  final String? recipientId;

  const ChatScreen({
    super.key,
    required this.roomId,
    this.recipientName,
    this.recipientPhoto,
    this.recipientId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  void Function(dynamic data)? _onMessageReceived;
  void Function(dynamic data)? _onMessagesRead;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _resolveCurrentUserId();
    await _loadMessages();
    _setupSocket();
  }

  Future<void> _resolveCurrentUserId() async {
    // 1. Try from customerProfileProvider
    final profile = ref.read(customerProfileProvider);
    if (profile != null && profile['id'] != null) {
      _currentUserId = profile['id'].toString();
      return;
    }

    // 2. Try decoding stored JWT token
    final token = await TokenRepository().readToken();
    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final normalized = base64Url.normalize(parts[1]);
          final payloadStr = utf8.decode(base64Url.decode(normalized));
          final payload = json.decode(payloadStr) as Map<String, dynamic>?;
          if (payload != null && payload['id'] != null) {
            _currentUserId = payload['id'].toString();
            return;
          }
        }
      } catch (_) {}
    }

    // 3. Try fetching from user profile endpoint
    try {
      final res = await ref.read(userServiceProvider).getUserProfile();
      if (res.data is Map && res.data['user'] != null) {
        final user = Map<String, dynamic>.from(res.data['user'] as Map);
        _currentUserId = user['id']?.toString();
        ref.read(customerProfileProvider.notifier).setProfile(user);
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    if (widget.roomId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await ref.read(messageServiceProvider).getRoomMessages(
        widget.roomId,
        limit: 100,
      );

      if (res.data is Map && res.data['messages'] is List) {
        final rawList = res.data['messages'] as List;
        final parsed = rawList
            .map((item) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();

        if (mounted) {
          setState(() {
            _messages = parsed;
            _isLoading = false;
          });
          _scrollToBottom();
        }

        // Mark existing messages as read
        await ref.read(messageServiceProvider).markRoomAsRead(widget.roomId);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupSocket() {
    final socketService = ref.read(socketServiceProvider);

    // Clean up previous listeners to prevent duplicate events
    if (_onMessageReceived != null) {
      socketService.offMessage(_onMessageReceived);
      _onMessageReceived = null;
    }
    if (_onMessagesRead != null) {
      socketService.offMessagesRead(_onMessagesRead);
      _onMessagesRead = null;
    }

    if (!socketService.isConnected) {
      socketService.connect().then((_) {
        if (mounted && widget.roomId.isNotEmpty) {
          socketService.joinRoom(widget.roomId);
        }
      });
    } else if (widget.roomId.isNotEmpty) {
      socketService.joinRoom(widget.roomId);
    }

    // Real-time message listener
    _onMessageReceived = (data) {
      if (!mounted) return;

      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final incoming = ChatMessage.fromJson(mapData);

        // Ignore messages from other rooms
        if (incoming.roomId.isNotEmpty && incoming.roomId != widget.roomId) {
          return;
        }

        setState(() {
          // Check if replacing an optimistic message
          final existingIdx = _messages.indexWhere(
            (m) =>
                m.id == incoming.id ||
                (m.messageStatus == 'sending' &&
                    m.messageContent == incoming.messageContent &&
                    (m.senderId == incoming.senderId ||
                        m.senderId.isEmpty ||
                        incoming.senderId == _currentUserId)),
          );

          if (existingIdx >= 0) {
            _messages[existingIdx] = incoming;
          } else {
            _messages.add(incoming);
          }
        });

        _scrollToBottom();

        // Mark as read if received from service provider
        if (incoming.senderId != _currentUserId && widget.roomId.isNotEmpty) {
          ref.read(messageServiceProvider).markRoomAsRead(widget.roomId);
        }
      } else if (data is String) {
        debugPrint('[ChatScreen] System notice: $data');
      }
    };

    socketService.onMessage(_onMessageReceived!);

    // Real-time read receipt listener
    _onMessagesRead = (data) {
      if (!mounted) return;
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        if (mapData['roomId'] == widget.roomId) {
          setState(() {
            for (int i = 0; i < _messages.length; i++) {
              if (_messages[i].senderId == _currentUserId) {
                _messages[i] = _messages[i].copyWith(messageStatus: 'read');
              }
            }
          });
        }
      }
    };

    socketService.onMessagesRead(_onMessagesRead!);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    if (widget.roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat room not ready. Please go back and retry.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (customText == null) {
      _messageController.clear();
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      roomId: widget.roomId,
      senderId: _currentUserId ?? '',
      messageContent: text,
      messageType: 'text',
      messageStatus: 'sending',
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    final socketService = ref.read(socketServiceProvider);

    if (socketService.isConnected) {
      socketService.sendMessageToRoom(
        roomId: widget.roomId,
        message: text,
        messageType: 'text',
        ack: (ack) {
          if (!mounted) return;
          if (ack is Map) {
            final ackMap = Map<String, dynamic>.from(ack);
            if (ackMap['message'] is Map) {
              final serverMsg = ChatMessage.fromJson(
                Map<String, dynamic>.from(ackMap['message'] as Map),
              );
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == tempId);
                if (idx >= 0) {
                  _messages[idx] = serverMsg;
                }
              });
            }
          }
        },
      );

      // Safety fallback: after 10s if still 'sending', mark failed
      Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx >= 0 && _messages[idx].messageStatus == 'sending') {
          setState(() {
            _messages[idx] = _messages[idx].copyWith(messageStatus: 'failed');
          });
        }
      });
    } else {
      // Fallback to REST endpoint
      try {
        final res = await ref.read(messageServiceProvider).sendMessage(
          roomId: widget.roomId,
          messageContent: text,
        );
        if (res.data is Map && res.data['message'] != null) {
          final serverMsg = ChatMessage.fromJson(
            Map<String, dynamic>.from(res.data['message'] as Map),
          );
          if (mounted) {
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == tempId);
              if (idx >= 0) {
                _messages[idx] = serverMsg;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('[ChatScreen] Error sending via REST fallback: $e');
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == tempId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(messageStatus: 'failed');
            }
          });
        }
      }
    }
  }

  Future<void> _retryMessage(ChatMessage msg) async {
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        _messages[idx] = _messages[idx].copyWith(messageStatus: 'sending');
      }
    });

    final socketService = ref.read(socketServiceProvider);

    if (socketService.isConnected) {
      socketService.sendMessageToRoom(
        roomId: widget.roomId,
        message: msg.messageContent,
        messageType: msg.messageType,
        ack: (ack) {
          if (!mounted) return;
          if (ack is Map) {
            final ackMap = Map<String, dynamic>.from(ack);
            if (ackMap['message'] is Map) {
              final serverMsg = ChatMessage.fromJson(
                Map<String, dynamic>.from(ackMap['message'] as Map),
              );
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == msg.id);
                if (idx >= 0) {
                  _messages[idx] = serverMsg;
                }
              });
            }
          }
        },
      );

      Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx >= 0 && _messages[idx].messageStatus == 'sending') {
          setState(() {
            _messages[idx] = _messages[idx].copyWith(messageStatus: 'failed');
          });
        }
      });
    } else {
      try {
        final res = await ref.read(messageServiceProvider).sendMessage(
          roomId: widget.roomId,
          messageContent: msg.messageContent,
          messageType: msg.messageType,
        );
        if (res.data is Map && res.data['message'] != null) {
          final serverMsg = ChatMessage.fromJson(
            Map<String, dynamic>.from(res.data['message'] as Map),
          );
          if (mounted) {
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == msg.id);
              if (idx >= 0) {
                _messages[idx] = serverMsg;
              }
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(messageStatus: 'failed');
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    if (_onMessageReceived != null) {
      socketService.offMessage(_onMessageReceived);
    }
    if (_onMessagesRead != null) {
      socketService.offMessagesRead(_onMessagesRead);
    }
    if (widget.roomId.isNotEmpty) {
      socketService.leaveRoom(widget.roomId);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'SP';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return const Icon(
          Icons.access_time_rounded,
          size: 11,
          color: Colors.white60,
        );
      case 'sent':
        return const Icon(
          Icons.check_rounded,
          size: 13,
          color: Colors.white70,
        );
      case 'delivered':
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.white70,
        );
      case 'read':
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.lightBlueAccent,
        );
      case 'failed':
        return const Icon(
          Icons.error_outline_rounded,
          size: 12,
          color: Colors.redAccent,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final providerName = widget.recipientName ?? 'Service Provider';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE6F4F2),
              backgroundImage: widget.recipientPhoto != null &&
                      widget.recipientPhoto!.isNotEmpty
                  ? NetworkImage(widget.recipientPhoto!)
                  : null,
              child: widget.recipientPhoto == null ||
                      widget.recipientPhoto!.isEmpty
                  ? Text(
                      _getInitials(providerName),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: BrandColors.accent,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        ref.read(socketServiceProvider).connectionNotifier,
                    builder: (context, isConnected, _) {
                      return Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? Colors.green
                                  : Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isConnected ? 'Connected' : 'Connecting...',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isConnected
                                  ? Colors.green
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.accent,
                      strokeWidth: 2.5,
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: BrandColors.accent
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: BrandColors.accent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinate service details directly with your technician.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCustomer = _currentUserId != null &&
                              message.senderId == _currentUserId;

                          final isFailed = message.messageStatus == 'failed';

                          return Align(
                            alignment: isCustomer
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: isCustomer && isFailed
                                  ? () => _retryMessage(message)
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isCustomer
                                      ? (isFailed
                                          ? Colors.red.shade900.withValues(alpha: 0.8)
                                          : BrandColors.accent)
                                      : (isDark
                                          ? const Color(0xFF1E293B)
                                          : theme.cardColor),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                      isCustomer ? 16 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isCustomer ? 4 : 16,
                                    ),
                                  ),
                                  border: isCustomer
                                      ? (isFailed
                                          ? Border.all(color: Colors.redAccent)
                                          : null)
                                      : Border.all(color: theme.dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isCustomer
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.messageContent,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isCustomer
                                            ? Colors.white
                                            : theme.textTheme.bodyLarge?.color,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTime(message.createdAt),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isCustomer
                                                ? Colors.white70
                                                : theme
                                                    .textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        if (isCustomer) ...[
                                          const SizedBox(width: 4),
                                          _buildStatusIcon(message.messageStatus),
                                          if (isFailed) ...[
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Message Input Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: BrandColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: BrandColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _sendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
