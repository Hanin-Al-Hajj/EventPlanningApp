import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/chat_screen.dart';
import 'package:event_planner/models/clientNotification.dart';

class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() =>
      _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  ClientNotificationFilter _selectedFilter = ClientNotificationFilter.all;
  List<ClientNotification> _notifications = [];
  ClientNotificationStats _stats = const ClientNotificationStats.empty();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadStats();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getNotifications();
      if (!mounted) return;

      if (result['success'] == true) {
        final response = ClientNotificationsResponse.fromApiData(
          result['data'],
        );

        setState(() {
          _notifications = response.notifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (_) {
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
        final data = result['data'] ?? result;

        setState(() {
          _stats = ClientNotificationStats.fromApiData(
            data,
            fallbackTotal: _notifications.length,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _handleNotificationTap(ClientNotification notification) async {
    var currentNotification = notification;

    if (!notification.isRead) {
      currentNotification = await _markOneRead(notification);
    }

    if (!mounted) return;
    if (!currentNotification.isMessage) return;

    final eventId = currentNotification.eventIdFromActionUrl;
    if (eventId == null) return;

    var eventName = 'Chat';
    var plannerName = currentNotification.plannerNameFromTitle;

    try {
      final eventResult = await ApiService.getEvent(eventId);
      if (eventResult['success'] == true) {
        final eventData = eventResult['data'];

        if (eventData is Map) {
          final details = ClientNotificationEventDetails.fromJson(
            Map<String, dynamic>.from(eventData),
          );

          eventName = details.eventName;
          plannerName = details.plannerName?.isNotEmpty == true
              ? details.plannerName!
              : plannerName;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          eventId: eventId,
          eventName: eventName,
          plannerName: plannerName,
          isPlanner: false,
          onRead: null,
        ),
      ),
    );
  }

  Future<ClientNotification> _markOneRead(
    ClientNotification notification,
  ) async {
    try {
      final result = await ApiService.markNotificationRead(notification.id);
      if (!mounted) return notification;

      if (result['success'] == true) {
        final updatedNotification = notification.copyWith(isRead: true);

        setState(() {
          _notifications = _notifications.map((item) {
            return item.id == notification.id ? updatedNotification : item;
          }).toList();

          _stats = _stats.copyWith(
            unread: (_stats.unread - 1).clamp(0, _stats.unread),
          );
        });

        return updatedNotification;
      }
    } catch (_) {}

    return notification;
  }

  Future<void> _archiveOne(ClientNotification notification) async {
    try {
      await ApiService.archiveNotification(notification.id);
      if (!mounted) return;

      await _loadNotifications();
      await _loadStats();
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
    } catch (_) {
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
    } catch (_) {
      _showSnackBar(
        'Failed to clear notifications',
        backgroundColor: AppColors.burgundy,
      );
    }
  }

  List<ClientNotification> get _filteredNotifications {
    return _notifications.where(_selectedFilter.matches).toList();
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

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    icon: Icons.notifications,
                    value: _stats.total.toString(),
                    label: 'Total',
                    color: Colors.blue,
                  ),
                  _buildMiniStat(
                    icon: Icons.mark_email_unread,
                    value: _stats.unread.toString(),
                    label: 'Unread',
                    color: Colors.orange,
                  ),
                  _buildMiniStat(
                    icon: Icons.priority_high,
                    value: _stats.urgent.toString(),
                    label: 'Urgent',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildFilterButton(ClientNotificationFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterButton(ClientNotificationFilter.events),
                  const SizedBox(width: 8),
                  _buildFilterButton(ClientNotificationFilter.messages),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.darkpink,
                        ),
                      )
                    : _errorMessage != null
                    ? _buildErrorState()
                    : filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationTile(
                              filteredNotifications[index],
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 10),
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

  Widget _buildNotificationTile(ClientNotification notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.burgundy,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: AppColors.coral),
      ),
      onDismissed: (_) => _archiveOne(notification),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
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
                  color: notification.isRead
                      ? Colors.grey.shade100
                      : AppColors.darkpink.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.isMessage ? Icons.message : Icons.event,
                  size: 18,
                  color: AppColors.darkpink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: notification.isRead
                                  ? Colors.grey
                                  : AppColors.burgundy,
                            ),
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (!notification.isRead)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Tap to view',
                          style: TextStyle(
                            color: AppColors.darkpink.withOpacity(0.6),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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

  Widget _buildFilterButton(ClientNotificationFilter filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
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
              _filterIcon(filter),
              size: 11,
              color: isSelected ? Colors.white : AppColors.darkpink,
            ),
            const SizedBox(width: 6),
            Text(
              filter.label,
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

  IconData _filterIcon(ClientNotificationFilter filter) {
    switch (filter) {
      case ClientNotificationFilter.events:
        return Icons.event;
      case ClientNotificationFilter.messages:
        return Icons.message;
      case ClientNotificationFilter.all:
        return FontAwesomeIcons.layerGroup;
    }
  }
}
