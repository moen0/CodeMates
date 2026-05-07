import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message.dart';
import '../models/profile.dart';
import 'profile_service.dart';

class MessageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Message>> _controllers = {};
  final Map<String, Profile> _senderCache = {};

  Future<List<Message>> getMessages(String projectId) async {
    final response = await _supabase
        .from('messages')
        .select('*, sender:sender_id(id, display_name, email, avatar_url)')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    final messages = response
        .map((row) => Message.fromMap(Map<String, dynamic>.from(row)))
        .toList();

    for (final message in messages) {
      _cacheSender(message.sender);
    }

    return Future.wait(messages.map(_withSender));
  }

  Stream<Message> subscribeToMessages(String projectId) {
    final existingController = _controllers[projectId];
    if (existingController != null) {
      return existingController.stream;
    }

    final controller = StreamController<Message>.broadcast();

    final channel = _supabase
        .channel('project_$projectId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'project_id',
            value: projectId,
          ),
          callback: (payload) {
            final raw = Map<String, dynamic>.from(payload.newRecord);
            final message = Message.fromMap(raw);
            unawaited(_emitEnrichedMessage(controller, message));
          },
        );

    _channels[projectId] = channel;
    _controllers[projectId] = controller;
    channel.subscribe();

    return controller.stream;
  }

  Future<Message> sendMessage({
    required String projectId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No current user');
    }

    final response = await _supabase.from('messages').insert({
      'project_id': projectId,
      'sender_id': userId,
      'content': content,
    }).select('*, sender:sender_id(id, display_name, email, avatar_url)').single();

    final message = Message.fromMap(Map<String, dynamic>.from(response));
    _cacheSender(message.sender);

    return _withSender(message);
  }

  Future<void> unsubscribe(String projectId) async {
    final controller = _controllers.remove(projectId);
    await controller?.close();

    final channel = _channels.remove(projectId);
    if (channel != null) {
      await _supabase.removeChannel(channel);
    }
  }

  void _cacheSender(Profile? sender) {
    if (sender == null) {
      return;
    }

    _senderCache[sender.id] = sender;
  }

  Future<Message> _withSender(Message message) async {
    if (message.sender != null) {
      _cacheSender(message.sender);
      return message;
    }

    final cached = _senderCache[message.senderId];
    if (cached != null) {
      return message.copyWith(sender: cached);
    }

    final profile = await _profileService.getProfile(message.senderId);
    if (profile == null) {
      return message;
    }

    _senderCache[profile.id] = profile;
    return message.copyWith(sender: profile);
  }

  Future<void> _emitEnrichedMessage(
    StreamController<Message> controller,
    Message message,
  ) async {
    final enriched = await _withSender(message);
    if (!controller.isClosed) {
      controller.add(enriched);
    }
  }
}
