import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _supabase = Supabase.instance.client;

  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  // Cache of sender info: senderId -> { name, avatar_url }
  Map<String, Map<String, String?>> _senderInfo = {};

  @override
  void initState() {
    super.initState();
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('project_id', widget.projectId)
        .order('created_at', ascending: false);

    _loadSenderInfo();
  }

  Future<void> _loadSenderInfo() async {
    try {
      final messages = await _supabase
          .from('messages')
          .select('sender_id')
          .eq('project_id', widget.projectId);

      final senderIds = messages
          .map((m) => m['sender_id'] as String)
          .toSet()
          .toList();

      // Always include the current user so own bubbles can show avatar fallback
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null && !senderIds.contains(currentUserId)) {
        senderIds.add(currentUserId);
      }

      if (senderIds.isEmpty) return;

      final profiles = await _supabase
          .from('profiles')
          .select('id, display_name, email, avatar_url')
          .inFilter('id', senderIds);

      final map = <String, Map<String, String?>>{};
      for (final p in profiles) {
        map[p['id'] as String] = {
          'name': (p['display_name'] as String?) ??
              (p['email'] as String?) ??
              'Ukjent',
          'avatar_url': p['avatar_url'] as String?,
        };
      }

      if (mounted) setState(() => _senderInfo = map);
    } catch (_) {
      // silent fail; bubbles will fall back to "Ukjent"
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'project_id': widget.projectId,
        'sender_id': _supabase.auth.currentUser!.id,
        'content': content,
      });
      _loadSenderInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke sende melding')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Noe gikk galt'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Ingen meldinger ennå. Si hei!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderId = msg['sender_id'] as String;
                    final isMe = senderId == currentUserId;

                    // Group consecutive messages from the same sender.
                    // In a reversed list, the "next" message visually below
                    // is at index+1 in the data array.
                    final prevMsg =
                    index + 1 < messages.length ? messages[index + 1] : null;
                    final isFirstInGroup =
                        prevMsg == null || prevMsg['sender_id'] != senderId;

                    final info = _senderInfo[senderId];
                    final senderName = info?['name'] ?? 'Ukjent';
                    final avatarUrl = info?['avatar_url'];

                    return _MessageBubble(
                      content: msg['content'] as String,
                      isMe: isMe,
                      senderName: senderName,
                      avatarUrl: avatarUrl,
                      timestamp:
                      DateTime.parse(msg['created_at'] as String).toLocal(),
                      showHeader: isFirstInGroup,
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
  final String senderName;
  final String? avatarUrl;
  final DateTime timestamp;
  final bool showHeader;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.senderName,
    required this.avatarUrl,
    required this.timestamp,
    required this.showHeader,
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
    isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final mutedColor = textColor.withOpacity(0.7);

    final avatar = SizedBox(
      width: 32,
      child: showHeader
          ? CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage:
        (avatarUrl != null && avatarUrl!.isNotEmpty)
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