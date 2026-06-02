import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/screens/profile_screen.dart';
import 'package:event_planner/screens/system_screen.dart';

class MessagesScreenClient extends StatefulWidget {
  const MessagesScreenClient({super.key});

  @override
  State<MessagesScreenClient> createState() => _MessagesScreenClientState();
}

class _MessagesScreenClientState extends State<MessagesScreenClient> {
  // TEMP DATA (replace later with API /client/threads)
  final List<Map<String, dynamic>> eventsWithPlanners = [
    // Example:
    // {
    //   "planner_name": "John Doe",
    //   "event_name": "Wedding",
    //   "last_message": "See you tomorrow"
    // }
  ];

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),

          child: Column(
            children: [
              Row(
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

                  // TITLE
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

              const SizedBox(height: 10),

              // SUBTITLE
              Text(
                'Chat with your event planners',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.green.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: eventsWithPlanners.isEmpty
                    ? _buildEmptyState()
                    : _buildChatList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No event planner to chat with',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.green.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create an event and choose a planner to start chatting',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.green.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      itemCount: eventsWithPlanners.length,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey.shade300, height: 20),
      itemBuilder: (context, index) {
        final item = eventsWithPlanners[index];

        return InkWell(
          onTap: () {
            // TODO: open chat screen (thread/event)
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // AVATAR
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.darkpink.withOpacity(0.15),
                  child: const Icon(Icons.person, color: AppColors.darkpink),
                ),

                const SizedBox(width: 12),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['planner_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['event_name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['last_message'] ?? 'Start conversation...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
