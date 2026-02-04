import 'package:flutter/material.dart';
import 'package:event_planner/widgets/app_drawer.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF586041),
        foregroundColor: Colors.white,
        title: const Text('Messages'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMessageCard(
            name: 'Sarah Johnson',
            message: 'Thanks for confirming! See you at the venue.',
            time: '10:30 AM',
            unread: true,
            avatar: 'S',
          ),
          const SizedBox(height: 12),
          _buildMessageCard(
            name: 'Elite Catering Co.',
            message: 'We have updated the menu as per your request.',
            time: 'Yesterday',
            unread: true,
            avatar: 'E',
          ),
          const SizedBox(height: 12),
          _buildMessageCard(
            name: 'Michael Chen',
            message: 'Perfect! I\'ll bring the decorations on Friday.',
            time: '2 days ago',
            unread: false,
            avatar: 'M',
          ),
          const SizedBox(height: 12),
          _buildMessageCard(
            name: 'Luxury Venues Ltd',
            message: 'Your booking has been confirmed for June 15th.',
            time: '3 days ago',
            unread: false,
            avatar: 'L',
          ),
          const SizedBox(height: 12),
          _buildMessageCard(
            name: 'Emma Williams',
            message: 'Can we schedule a call to discuss the timeline?',
            time: '1 week ago',
            unread: false,
            avatar: 'E',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New message feature coming soon!')),
          );
        },
        backgroundColor: const Color(0xFF586041),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildMessageCard({
    required String name,
    required String message,
    required String time,
    required bool unread,
    required String avatar,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread
              ? const Color(0xFF586041).withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF586041),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                        color: const Color(0xFF151910),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: unread ? Colors.grey.shade800 : Colors.grey.shade600,
                    fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF586041),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
