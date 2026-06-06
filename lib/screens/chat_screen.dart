import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  final String plannerName;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.plannerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final result = await ApiService.getMessages(widget.eventId);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final result = await ApiService.sendMessage(
        eventId: widget.eventId,
        message: text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _messageController.clear();
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
                      style: const TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        SizedBox(
                          width: 15, // same as icon size
                          child: Icon(
                            Icons.person,
                            color: AppColors.coral,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.plannerName,
                          style: const TextStyle(
                            color: AppColors.darkpink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () async {
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
                  if (confirm == true) {
                    await ApiService.deleteAllMessages(widget.eventId);
                    _loadMessages();
                  }
                },
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
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.darkpink),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
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
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMine = msg['is_mine'] == true;
                      return _buildMessageBubble(msg, isMine);
                    },
                  ),
          ),

          // Message input
          Container(
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
                        hintStyle: TextStyle(color: AppColors.coral),

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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.darkpink,
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
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
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

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMine) {
    final senderName = msg['sender_name'] ?? '';
    final message = msg['message'] ?? '';
    final time = msg['created_at'] ?? '';

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
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkpink,
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : AppColors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
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
