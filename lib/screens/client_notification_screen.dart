import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/chat_screen.dart';

class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() =>
      _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  String selectedFilter = 'All';
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _totalCount = 0;
  int _unreadCount = 0;
  int _urgentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadStats();
  }

  Future<void> _handleNotificationTap(
    Map<String, dynamic> notification,
    int index,
  ) async {
    final id = notification['id'] as int;
    final type = notification['type'] ?? '';
    final actionUrl = notification['action_url'] ?? '';
    final title = notification['title'] ?? '';

    // Mark as read first
    if (notification['is_read'] != true) {
      await _markOneRead(id, index);
    }

    if (!mounted) return;

    if (type.toString().toLowerCase().contains('message')) {
      int? eventId;

      try {
        final uri = Uri.parse(actionUrl);
        final segments = uri.pathSegments;
        if (segments.length >= 2) {
          eventId = int.tryParse(segments.last);
        }
      } catch (_) {}

      String plannerName = 'Planner';
      if (title.startsWith('New Message from ')) {
        plannerName = title.replaceFirst('New Message from ', '');
      }

      if (eventId != null) {
        // ✅ Fetch event details to get the real event name
        String eventName = 'Chat';
        try {
          final eventResult = await ApiService.getEvent(eventId!);
          if (eventResult['success'] == true) {
            final eventData = eventResult['data'];
            eventName = eventData['name'] ?? 'Chat';
            // Get planner name from event if available
            if (eventData['planner'] != null) {
              plannerName = eventData['planner']['name'] ?? plannerName;
            }
          }
        } catch (_) {}

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              eventId: eventId!,
              eventName: eventName,
              plannerName: plannerName,
              isPlanner: false,
              onRead: null,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getNotifications();

      // ✅ Debug: Print the result to see structure
      print('Notification result: $result');

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        // Handle both cases: data as List or data as Map with notifications key
        List<dynamic> notificationsList;
        if (data is List) {
          notificationsList = data;
        } else if (data is Map) {
          notificationsList = data['notifications'] ?? data['data'] ?? [];
        } else {
          notificationsList = [];
        }

        setState(() {
          _notifications = notificationsList
              .map((n) => n as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Notification error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await ApiService.getNotificationStats();
      if (!mounted) return;

      if (result['success'] == true) {
        // ✅ Fix: data is nested
        final data = result['data'] ?? result;
        setState(() {
          _totalCount = data['total'] ?? _notifications.length;
          _unreadCount = data['unread'] ?? 0;
          _urgentCount = data['urgent'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final result = await ApiService.markAllNotificationsRead();
      if (!mounted) return;
      if (result['success'] == true) {
        await _loadNotifications();
        await _loadStats();
      }
    } catch (e) {
      _showSnackBar('Failed to mark all as read', backgroundColor: Colors.red);
    }
  }

  Future<void> _archiveAll() async {
    try {
      final result = await ApiService.archiveAllNotifications();
      if (!mounted) return;
      if (result['success'] == true) {
        await _loadNotifications();
        await _loadStats();
      }
    } catch (e) {
      _showSnackBar(
        'Failed to clear notifications',
        backgroundColor: AppColors.burgundy,
      );
    }
  }

  Future<void> _markOneRead(int id, int index) async {
    try {
      final result = await ApiService.markNotificationRead(id);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _notifications[index]['is_read'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        });
      }
    } catch (_) {}
  }

  Future<void> _archiveOne(int id) async {
    try {
      await ApiService.archiveNotification(id);
      if (!mounted) return;
      await _loadNotifications();
      await _loadStats();
    } catch (_) {}
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Map API notification type to filter category
  String _getFilterType(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString().toLowerCase();
    if (type.contains('message')) return 'Messages';
    if (type.contains('event')) return 'Events';
    return 'Events'; // default
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (selectedFilter == 'All') return _notifications;
    return _notifications
        .where((n) => _getFilterType(n) == selectedFilter)
        .toList();
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
                    onPressed: () => Navigator.pop(context),
                    icon: const FaIcon(
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
                style: TextStyle(
                  color: AppColors.green.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              // MINI STATS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    icon: Icons.notifications,
                    value: _totalCount.toString(),
                    label: 'Total',
                    color: Colors.blue,
                  ),
                  _buildMiniStat(
                    icon: Icons.mark_email_unread,
                    value: _unreadCount.toString(),
                    label: 'Unread',
                    color: Colors.orange,
                  ),
                  _buildMiniStat(
                    icon: Icons.priority_high,
                    value: _urgentCount.toString(),
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
                              size: 60,
                              color: AppColors.green.withOpacity(0.6),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.green.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadNotifications,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkpink,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 60,
                              color: AppColors.green.withOpacity(0.6),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: AppColors.green.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final n = filteredNotifications[index];
                            final isRead = n['is_read'] == true;
                            final id = n['id'] as int;

                            return Dismissible(
                              key: Key(id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.burgundy,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: AppColors.coral,
                                ),
                              ),
                              onDismissed: (_) => _archiveOne(id),
                              child: GestureDetector(
                                onTap: () => _handleNotificationTap(n, index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isRead
                                          ? Colors.grey.shade200
                                          : AppColors.darkpink.withOpacity(
                                              0.15,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isRead
                                              ? Colors.grey.shade100
                                              : AppColors.darkpink.withOpacity(
                                                  0.12,
                                                ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getFilterType(n) == 'Messages'
                                              ? Icons.message
                                              : Icons.event,
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
                                                    n['title'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      color: isRead
                                                          ? Colors.grey
                                                          : AppColors.burgundy,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  n['time_ago'] ??
                                                      n['created_at'] ??
                                                      '',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              n['message'] ?? n['body'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                            // ✅ Add a subtle "Tap to view" hint for unread
                                            if (!isRead)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  'Tap to view',
                                                  style: TextStyle(
                                                    color: AppColors.darkpink
                                                        .withOpacity(0.6),
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                            top: 4,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.darkpink,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              const SizedBox(height: 10),

              // BOTTOM BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _markAllRead,
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
                      onPressed: _archiveAll,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkpink,
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
      onTap: () => setState(() => selectedFilter = filter),
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
