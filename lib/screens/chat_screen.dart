import 'dart:async';

import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/chat_message.dart';
import 'package:event_planner/repositories/chat_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  final String plannerName;
  final bool isPlanner;
  final VoidCallback? onRead;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.plannerName,
    required this.isPlanner,
    this.onRead,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ValueNotifier<List<ChatMessage>> _messagesNotifier;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _attachToChat();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.eventId != widget.eventId ||
        oldWidget.isPlanner != widget.isPlanner) {
      _messagesNotifier.removeListener(_onMessagesChanged);
      _attachToChat();
    }
  }

  @override
  void dispose() {
    _messagesNotifier.removeListener(_onMessagesChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _attachToChat() {
    _messagesNotifier = ChatRepository.messagesFor(
      eventId: widget.eventId,
      isPlanner: widget.isPlanner,
    );
    _messagesNotifier.addListener(_onMessagesChanged);

    _messages = ChatRepository.cachedMessages(
      eventId: widget.eventId,
      isPlanner: widget.isPlanner,
    );

    if (ChatRepository.hasCache(
      eventId: widget.eventId,
      isPlanner: widget.isPlanner,
    )) {
      widget.onRead?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(jump: true);
      });
      unawaited(
        ChatRepository.refreshInBackground(
          eventId: widget.eventId,
          isPlanner: widget.isPlanner,
        ),
      );
    } else {
      unawaited(_loadMessages());
    }
  }

  void _onMessagesChanged() {
    if (!mounted) return;

    setState(() {
      _messages = _messagesNotifier.value;
      _errorMessage = null;
    });

    _scrollToBottom();
    widget.onRead?.call();
  }

  Future<void> _loadMessages({bool showLoader = true}) async {
    if (!mounted) return;

    final hasCache = ChatRepository.hasCache(
      eventId: widget.eventId,
      isPlanner: widget.isPlanner,
    );

    if (showLoader && !hasCache) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      await ChatRepository.loadMessages(
        eventId: widget.eventId,
        isPlanner: widget.isPlanner,
        forceRefresh: true,
      );

      if (!mounted) return;

      setState(() {
        _messages = ChatRepository.cachedMessages(
          eventId: widget.eventId,
          isPlanner: widget.isPlanner,
        );
        _isLoading = false;
        _errorMessage = null;
      });

      _scrollToBottom();
      widget.onRead?.call();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (!hasCache && _messages.isEmpty) {
          _errorMessage = 'Connection error';
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await ChatRepository.sendMessage(
        eventId: widget.eventId,
        isPlanner: widget.isPlanner,
        text: text,
      );

      if (!mounted) return;

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFromError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Clear Chat',
          style: TextStyle(
            color: AppColors.burgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Delete all messages?',
          style: TextStyle(color: AppColors.burgundy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.burgundy),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.darkpink,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ChatRepository.clearMessages(
        eventId: widget.eventId,
        isPlanner: widget.isPlanner,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFromError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Connection error' : message;
  }

  void _scrollToBottom({bool jump = false}) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      final bottom = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(bottom);
        return;
      }

      _scrollController.animateTo(
        bottom,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.coral.withOpacity(0.4),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.eventName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(
                          width: 15,
                          child: Icon(
                            Icons.person,
                            color: AppColors.coral,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.plannerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkpink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _clearChat,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkpink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: AppColors.darkpink,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          color: AppColors.darkpink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.darkpink),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.green.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.green.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _loadMessages(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => _loadMessages(showLoader: false),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: AppColors.green.withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.green.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start the conversation!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.green.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return RefreshIndicator(
      onRefresh: () => _loadMessages(showLoader: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                cursorColor: AppColors.burgundy,
                style: const TextStyle(color: AppColors.burgundy),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: AppColors.coral),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.darkpink.withOpacity(0.6)
                    : AppColors.darkpink,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.darkpink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkpink,
                  ),
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : AppColors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.createdAt,
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
