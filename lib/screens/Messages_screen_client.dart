import 'dart:async';

import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/message_chat.dart';
import 'package:event_planner/repositories/message_repository.dart';
import 'package:event_planner/screens/profile_screen.dart';
import 'package:event_planner/screens/client/client_setting.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/chat_screen.dart';

class MessagesScreenClient extends StatefulWidget {
  const MessagesScreenClient({super.key});

  @override
  State<MessagesScreenClient> createState() => _MessagesScreenClientState();
}

class _MessagesScreenClientState extends State<MessagesScreenClient> {
  List<MessageChat> _chats = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    MessageRepository.chats.addListener(_onChatsChanged);
    _chats = MessageRepository.cachedChats;

    if (MessageRepository.hasCache) {
      unawaited(MessageRepository.refreshInBackground());
    } else {
      unawaited(_loadChats());
    }
  }

  @override
  void dispose() {
    MessageRepository.chats.removeListener(_onChatsChanged);
    super.dispose();
  }

  void _onChatsChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _chats = MessageRepository.cachedChats;
        _errorMessage = null;
      });
    });
  }

  Future<void> _loadChats({bool showLoader = true}) async {
    if (!mounted) return;

    final hasCache = MessageRepository.hasCache;

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
      await MessageRepository.loadChats(forceRefresh: true);
      if (!mounted) return;

      setState(() {
        _chats = MessageRepository.cachedChats;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (!MessageRepository.hasCache && _chats.isEmpty) {
          _errorMessage = 'Connection error';
        }
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

    if (confirm == true && mounted) {
      await ApiService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                children: [
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
                            builder: (_) => const ClientSetting(),
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
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkpink,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _chats.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          TextButton(onPressed: () => _loadChats(), child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => _loadChats(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Padding(
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
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: () => _loadChats(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chats.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey.shade200, height: 1, indent: 72),
        itemBuilder: (context, index) {
          final chat = _chats[index];

          return InkWell(
            onTap: () => _openChat(chat),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.darkpink.withOpacity(0.12),
                    child: Text(
                      chat.eventName.isNotEmpty
                          ? chat.eventName[0].toUpperCase()
                          : 'E',
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
                          chat.eventName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.burgundy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              chat.plannerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkpink.withOpacity(0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '-',
                              style: TextStyle(
                                color: AppColors.green.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                chat.lastMessageText,
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
                      if (chat.lastMessageTime.isNotEmpty)
                        Text(
                          chat.lastMessageTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.green.withOpacity(0.7),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (chat.unreadCount > 0)
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
                            chat.unreadCount.toString(),
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
      ),
    );
  }

  Future<void> _openChat(MessageChat chat) async {
    if (chat.id == 0) return;

    MessageRepository.markRead(chat.id);

    ApiService.markClientEventMessagesAsRead(chat.id).catchError((e) {
      debugPrint('Mark client messages as read error: $e');
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          eventId: chat.id,
          eventName: chat.eventName,
          plannerName: chat.plannerName,
          isPlanner: false,
          onRead: () => MessageRepository.markRead(chat.id),
        ),
      ),
    );

    if (mounted) {
      unawaited(MessageRepository.refreshInBackground());
    }
  }
}
