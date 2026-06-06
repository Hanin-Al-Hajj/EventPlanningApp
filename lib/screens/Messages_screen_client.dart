import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/screens/profile_screen.dart';
import 'package:event_planner/screens/system_screen.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/chat_screen.dart';

class MessagesScreenClient extends StatefulWidget {
  const MessagesScreenClient({super.key});

  @override
  State<MessagesScreenClient> createState() => _MessagesScreenClientState();
}

class _MessagesScreenClientState extends State<MessagesScreenClient> {
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
      final result = await ApiService.getMessagesEvents();

      if (!mounted) return;

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          _chats = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.burgundy),
        ),
        content: const Text(
          'Are you sure you want to logout?',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
                  // Profile menu
                  PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: AppColors.darkpink,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Profile',
                              style: TextStyle(color: AppColors.darkpink),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: AppColors.darkpink,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Settings',
                              style: TextStyle(color: AppColors.darkpink),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: AppColors.darkpink),
                            SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(color: AppColors.darkpink),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      } else if (value == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SystemScreen(),
                          ),
                        );
                      } else if (value == 'logout') {
                        _handleLogout(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.darkpink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  // Title
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

                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Chat with your event planners',
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

  // Empty state when no planners
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
              'Create an event and choose a planner to start chatting',
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

  // WhatsApp-style chat list
  Widget _buildChatList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _chats.length,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey.shade200, height: 1, indent: 72),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final plannerName = chat['planner']?['name'] ?? 'Planner';
        final eventName = chat['name'] ?? 'Event';
        final lastMessage =
            chat['last_message']?['message'] ?? 'Start conversation...';
        final lastTime = chat['last_message']?['created_at'] ?? '';
        final unreadCount = chat['unread_count'] ?? 0;
        final eventId = chat['id']?.toString() ?? '';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  eventId: int.parse(eventId),
                  eventName: eventName,
                  plannerName: plannerName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Avatar with event initial
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

                // Event name, planner name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event name (main title)
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Planner name with person icon + last message
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: AppColors.coral),
                          const SizedBox(width: 4),
                          Text(
                            plannerName,
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

                // Time + unread badge
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
