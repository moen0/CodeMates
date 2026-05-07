import 'dart:async';

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'public_profile_screen.dart';

class ProjectChatScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ProjectChatScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageService = MessageService();
  final _authService = AuthService();

  StreamSubscription<Message>? _messagesSubscription;
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorText;

  // Cache of sender info: senderId -> { name, avatar_url }
  Map<String, Map<String, String?>> _senderInfo = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _messagesSubscription = _messageService
        .subscribeToMessages(widget.projectId)
        .listen(_handleIncomingMessage, onError: (_) {
      if (mounted) {
        setState(() => _errorText = 'Noe gikk galt');
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageService.getMessages(widget.projectId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
        _errorText = null;
      });
      _updateSenderInfo(messages);
      _scrollToBottom(jump: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Noe gikk galt';
      });
    }
  }

  void _updateSenderInfo(Iterable<Message> messages) {
    final updated = Map<String, Map<String, String?>>.from(_senderInfo);
    for (final message in messages) {
      final sender = message.sender;
      if (sender == null) continue;
      updated[message.senderId] = {
        'name': sender.displayLabel,
        'avatar_url': sender.avatarUrl,
      };
    }
    if (mounted) setState(() => _senderInfo = updated);
  }

  void _handleIncomingMessage(Message message) {
    if (!mounted) return;
    final exists = _messages.any((m) => m.id == message.id);
    if (exists) return;

    setState(() {
      _messages.insert(0, message);
    });
    _updateSenderInfo([message]);
    _scrollToBottom();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.minScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      final message = await _messageService.sendMessage(
        projectId: widget.projectId,
        content: content,
      );
      _handleIncomingMessage(message);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke sende melding')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageService.unsubscribe(widget.projectId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUserId!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (_errorText != null) {
                  return Center(child: Text(_errorText!));
                }
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_messages.isEmpty) {
                  return const Center(
                    child: Text('Ingen meldinger ennå. Si hei!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final senderId = msg.senderId;
                    final isMe = senderId == currentUserId;

                    // Group consecutive messages from the same sender.
                    // In a reversed list, the "next" message visually below
                    // is at index+1 in the data array.
                    final prevMsg =
                        index + 1 < _messages.length ? _messages[index + 1] : null;
                    final isFirstInGroup =
                        prevMsg == null || prevMsg.senderId != senderId;

                    final info = _senderInfo[senderId];
                    final senderName =
                        msg.sender?.displayLabel ?? info?['name'] ?? 'Ukjent';
                    final avatarUrl =
                        msg.sender?.avatarUrl ?? info?['avatar_url'];

                    return _MessageBubble(
                      content: msg.content,
                      isMe: isMe,
                      senderId: senderId,
                      senderName: senderName,
                      avatarUrl: avatarUrl,
                      timestamp: msg.createdAt.toLocal(),
                      showHeader: isFirstInGroup,
                      onAvatarTap: isMe
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PublicProfileScreen(userId: senderId),
                                ),
                              ),
                    );
                  },
                );
              },
            ),
          ),

          // Inputfelt
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Skriv en melding...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
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

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String senderId;
  final String senderName;
  final String? avatarUrl;
  final DateTime timestamp;
  final bool showHeader;
  final VoidCallback? onAvatarTap;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.senderId,
    required this.senderName,
    required this.avatarUrl,
    required this.timestamp,
    required this.showHeader,
    this.onAvatarTap,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final mutedColor = textColor.withValues(alpha: 0.7);

    final avatar = SizedBox(
      width: 32,
      child: showHeader
          ? GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Text(
                        _initials(senderName),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
            )
          : null,
    );

    final bubble = Flexible(
      child: Container(
        margin: EdgeInsets.only(top: showHeader ? 8 : 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 16 : (showHeader ? 4 : 16)),
            topRight: Radius.circular(isMe ? (showHeader ? 4 : 16) : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe && showHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            Text(
              content,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTime(timestamp),
                style: TextStyle(fontSize: 10, color: mutedColor),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: bubble,
                ),
              ]
            : [
                avatar,
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: bubble,
                ),
              ],
      ),
    );
  }
}
