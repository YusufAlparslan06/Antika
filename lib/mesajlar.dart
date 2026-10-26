import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'navigasyon.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRefreshing = false;
  String? _error;
  int _lastMessageId = 0;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      var query = _supabase
          .from('uygulama_mesajlari')
          .select(
            'id, gonderen_id, gonderen_adi, gonderen_rol, mesaj, created_at',
          );
      query = query.gt('id', _lastMessageId);
      final rows = await query.order('id').limit(250);
      final loaded = (rows as List)
          .map(
            (row) =>
                _ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
      if (!mounted) return;
      if (loaded.isNotEmpty) {
        setState(() {
          _messages.addAll(loaded);
          _lastMessageId = loaded.last.id;
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        });
      } else if (!silent) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
      if (_isLoading) setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Mesaj göndermek için yeniden giriş yapın.');
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final metadataName = user.userMetadata?['full_name']?.toString().trim();
      final senderName = metadataName?.isNotEmpty == true
          ? metadataName!
          : (user.email ?? 'Kullanıcı');
      await _supabase.from('uygulama_mesajlari').insert({
        'gonderen_id': user.id,
        'gonderen_adi': senderName.length > 160
            ? senderName.substring(0, 160)
            : senderName,
        'mesaj': text,
      });
      _messageController.clear();
      await _loadMessages(silent: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Mesaj gönderilemedi: $error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            tooltip: 'Mesajları yenile',
            onPressed: _isLoading ? null : _loadMessages,
            icon: const Icon(Icons.refresh),
          ),
          const NotificationMenuButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText('Mesajlar yüklenemedi: $_error'),
                    ),
                  )
                : _messages.isEmpty
                ? const Center(
                    child: Text('Henüz mesaj yok. İlk mesajı sen gönder!'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.senderId == currentUserId;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Card(
                            color: isMine
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${isMine ? 'Sen' : message.senderName} · '
                                    '${message.senderRole == 'yonetici' ? 'Yönetici' : 'Personel'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: isMine
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(message.text),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isMine
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_error != null && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mesajlar güncellenemedi: $_error',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Mesajını yaz...',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Gönder',
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime createdAt;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
    id: (json['id'] as num?)?.toInt() ?? 0,
    senderId: (json['gonderen_id'] ?? '').toString(),
    senderName: (json['gonderen_adi'] ?? 'Kullanıcı').toString(),
    senderRole: (json['gonderen_rol'] ?? 'personel').toString(),
    text: (json['mesaj'] ?? '').toString(),
    createdAt:
        DateTime.tryParse((json['created_at'] ?? '').toString()) ??
        DateTime.now(),
  );
}
