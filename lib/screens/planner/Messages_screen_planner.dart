import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/chat_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MessagesScreenPlanner extends StatefulWidget {
  const MessagesScreenPlanner({super.key});

  @override
  State<MessagesScreenPlanner> createState() => _MessagesScreenPlannerState();
}

class _MessagesScreenPlannerState extends State<MessagesScreenPlanner> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.getPlannerMessagesEvents();

      debugPrint('Messages response: $response');

      if (response['success'] == true) {
        final raw = response['data'] as List<dynamic>? ?? [];
        setState(() {
          _chats = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppColors.darkpink,
                      size: 22,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Messages',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Chat with your clients',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.green.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chat list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkpink,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadChats,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _chats.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppColors.green.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.green.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Client messages will appear here once they reach out',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.green.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _chats.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.grey.shade200, height: 1, indent: 72),
      itemBuilder: (_, index) {
        final chat = _chats[index];
        final clientName = chat['client']?['name'] ?? 'Client';
        final eventName = chat['name'] ?? 'Event';
        final lastMessage =
            chat['last_message']?['message'] ?? 'Start conversation...';
        final lastTime = chat['last_message']?['created_at'] ?? '';
        final unreadCount = int.tryParse('${chat['unread_count'] ?? 0}') ?? 0;
        final eventId = chat['id']?.toString() ?? '';

        return InkWell(
          onTap: () {
            final parsedEventId = int.tryParse(eventId);
            if (parsedEventId == null) return;

            setState(() {
              _chats[index]['unread_count'] = 0;
            });

            ApiService.markPlannerEventMessagesAsRead(parsedEventId).catchError(
              (e) {
                debugPrint('Mark messages as read error: $e');
              },
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  eventId: parsedEventId,
                  eventName: eventName,
                  plannerName: clientName,
                  isPlanner: true,
                  onRead: () {
                    if (!mounted || index >= _chats.length) return;

                    setState(() {
                      _chats[index]['unread_count'] = 0;
                    });
                  },
                ),
              ),
            ).then((_) {
              if (mounted) {
                _loadChats();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.darkpink.withOpacity(0.12),
                  child: Text(
                    eventName.isNotEmpty ? eventName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      color: AppColors.darkpink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: AppColors.coral),
                          const SizedBox(width: 4),
                          Text(
                            clientName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkpink.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.green.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.green.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastTime.isNotEmpty)
                      Text(
                        lastTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.green.withOpacity(0.7),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkpink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
