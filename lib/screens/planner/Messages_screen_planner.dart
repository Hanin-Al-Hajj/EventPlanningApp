import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/message_chat.dart';
import 'package:event_planner/repositories/planner_message_repository.dart';
import 'package:event_planner/screens/chat_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MessagesScreenPlanner extends StatefulWidget {
  const MessagesScreenPlanner({super.key});

  @override
  State<MessagesScreenPlanner> createState() => _MessagesScreenPlannerState();
}

class _MessagesScreenPlannerState extends State<MessagesScreenPlanner> {
  List<MessageChat> _chats = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    PlannerMessageRepository.chats.addListener(_onChatsChanged);
    _chats = PlannerMessageRepository.cachedChats;

    if (PlannerMessageRepository.hasCache) {
      unawaited(PlannerMessageRepository.refreshInBackground());
    } else {
      unawaited(_loadChats());
    }
  }

  @override
  void dispose() {
    PlannerMessageRepository.chats.removeListener(_onChatsChanged);
    super.dispose();
  }

  void _onChatsChanged() {
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyRepositoryCache();
      });
      return;
    }

    _applyRepositoryCache();
  }

  void _applyRepositoryCache() {
    if (!mounted) return;

    setState(() {
      _chats = PlannerMessageRepository.cachedChats;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadChats({bool showLoader = true}) async {
    if (!mounted) return;

    final hasCache = PlannerMessageRepository.hasCache;

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
      await PlannerMessageRepository.loadChats(forceRefresh: true);
      if (!mounted) return;

      setState(() {
        _chats = PlannerMessageRepository.cachedChats;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (!PlannerMessageRepository.hasCache && _chats.isEmpty) {
          _errorMessage = 'Something went wrong. Please try again.';
        }
      });
    }
  }

  Future<void> _openChat(MessageChat chat) async {
    PlannerMessageRepository.markRead(chat.id);
    unawaited(PlannerMessageRepository.markReadOnServer(chat.id));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          eventId: chat.id,
          eventName: chat.eventName,
          plannerName: chat.clientName,
          isPlanner: true,
          onRead: () {
            PlannerMessageRepository.markRead(chat.id);
          },
        ),
      ),
    );

    if (!mounted) return;
    unawaited(_loadChats(showLoader: false));
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
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkpink,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      color: AppColors.darkpink,
                      onRefresh: () => _loadChats(showLoader: false),
                      child: _chats.isEmpty
                          ? _buildEmptyState()
                          : _buildChatList(),
                    ),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
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
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _chats.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.grey.shade200, height: 1, indent: 72),
      itemBuilder: (_, index) {
        final chat = _chats[index];
        final clientName = chat.clientName;
        final eventName = chat.eventName;
        final lastMessage = chat.lastMessageText;
        final lastTime = chat.lastMessageTime;
        final unreadCount = chat.unreadCount;

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
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.coral,
                          ),
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
                            '-',
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
