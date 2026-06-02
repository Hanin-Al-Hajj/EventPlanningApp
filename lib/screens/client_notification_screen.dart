import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/constants/app_colors.dart';

class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() =>
      _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  String selectedFilter = 'All';

  // TEMP DATA
  // later replace with API data
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Event Reminder',
      'message': 'Wedding event starts tomorrow.',
      'type': 'Events',
      'time': '2 min ago',
      'isRead': false,
    },
    {
      'title': 'New Message',
      'message': 'You received a new client message.',
      'type': 'Messages',
      'time': '10 min ago',
      'isRead': true,
    },
  ];

  List<Map<String, dynamic>> get filteredNotifications {
    if (selectedFilter == 'All') return notifications;

    return notifications.where((n) => n['type'] == selectedFilter).toList();
  }

  int get unreadCount {
    return notifications.where((n) => n['isRead'] == false).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              // HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 18,
                      color: AppColors.darkpink,
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Notifications',
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

              Text(
                'Stay updated with your events and messages',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),

              const SizedBox(height: 22),

              // MINI STATS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    icon: Icons.notifications,
                    value: notifications.length.toString(),
                    label: 'Total',
                    color: Colors.blue,
                  ),

                  _buildMiniStat(
                    icon: Icons.mark_email_unread,
                    value: unreadCount.toString(),
                    label: 'Unread',
                    color: Colors.orange,
                  ),

                  _buildMiniStat(
                    icon: Icons.priority_high,
                    value: '0',
                    label: 'Urgent',
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // FILTERS
              Row(
                children: [
                  _buildFilterButton('All'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Events'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Messages'),
                ],
                
              ),

              const SizedBox(height: 20),

              // NOTIFICATIONS LIST
              Expanded(
                child: filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),

                            const SizedBox(height: 14),

                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: notification['isRead']
                                    ? Colors.grey.shade200
                                    : AppColors.darkpink.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: notification['isRead']
                                        ? Colors.grey.shade100
                                        : AppColors.darkpink.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notification['type'] == 'Events'
                                        ? Icons.event
                                        : Icons.message,
                                    size: 18,
                                    color: AppColors.darkpink,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: notification['isRead']
                                                    ? Colors.grey
                                                    : AppColors.burgundy,
                                              ),
                                            ),
                                          ),

                                          Text(
                                            notification['time'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        notification['message'],
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              // BOTTOM BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text(
                        'Mark Read',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.darkpink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.burgundy,
          ),
        ),

        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkpink
              : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.darkpink
                : AppColors.darkpink.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              filter == 'Events'
                  ? Icons.event
                  : filter == 'Messages'
                  ? Icons.message
                  : FontAwesomeIcons.layerGroup,
              size: 11,
              color: isSelected ? Colors.white : AppColors.darkpink,
            ),

            const SizedBox(width: 6),

            Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.darkpink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
