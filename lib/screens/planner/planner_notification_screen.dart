import 'dart:async';

import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/planner_notification.dart';
import 'package:event_planner/repositories/planner_notification_repository.dart';
import 'package:event_planner/widgets/planner/filter_tab.dart';
import 'package:event_planner/screens/vendor_details_screen.dart';
import 'package:event_planner/screens/chat_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlannerNotificationScreen extends StatefulWidget {
  const PlannerNotificationScreen({super.key});

  @override
  State<PlannerNotificationScreen> createState() =>
      _PlannerNotificationScreenState();
}

class _PlannerNotificationScreenState extends State<PlannerNotificationScreen> {
  List<plannerNotification> _items = [];
  String _filter = 'all';
  bool _isLoading = true;
  String? _error;

  int get _total => _items.where((n) {
    final now = DateTime.now();
    final created = n.createdAt;
    return created.year == now.year &&
        created.month == now.month &&
        created.day == now.day;
  }).length;
  int get _unread => _items.where((n) => !n.isRead).length;

  List<plannerNotification> get _filtered {
    if (_filter == 'all') return _items;

    return _items.where((n) {
      final type = n.type.toLowerCase();
      final title = n.title.toLowerCase();
      final message = n.message.toLowerCase();

      final isOrder =
          type.contains('order') ||
          title.contains('order') ||
          message.contains('order');

      if (_filter == 'order') {
        return isOrder;
      }

      if (_filter == 'task') {
        return !isOrder && type.contains('task');
      }

      return type.contains(_filter) ||
          title.contains(_filter) ||
          message.contains(_filter);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    PlannerNotificationRepository.notifications.addListener(
      _onNotificationsChanged,
    );

    if (PlannerNotificationRepository.hasCache) {
      _items = PlannerNotificationRepository.cachedNotifications;
      _isLoading = false;
      unawaited(PlannerNotificationRepository.refreshInBackground());
    } else {
      unawaited(_loadNotifications());
    }
  }

  @override
  void dispose() {
    PlannerNotificationRepository.notifications.removeListener(
      _onNotificationsChanged,
    );
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _items = PlannerNotificationRepository.cachedNotifications;
        _isLoading = false;
        _error = null;
      });
    });
  }

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh && PlannerNotificationRepository.hasCache) {
      setState(() {
        _items = PlannerNotificationRepository.cachedNotifications;
        _isLoading = false;
        _error = null;
      });
      unawaited(PlannerNotificationRepository.refreshInBackground());
      return;
    }

    if (_items.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      await PlannerNotificationRepository.loadNotifications(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _items = PlannerNotificationRepository.cachedNotifications;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _items.isEmpty
            ? 'Something went wrong. Please try again.'
            : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissNotification(plannerNotification n) async {
    PlannerNotificationRepository.remove(n);
    setState(() => _items.removeWhere((item) => item.id == n.id));
    try {
      final result = await PlannerNotificationRepository.archiveNotification(
        n.id,
      );
      if (result is Map && result['success'] != true && mounted) {
        PlannerNotificationRepository.restore(n);
        setState(() => _items.insert(0, n));
        _showSnackBar('Could not archive notification.');
      }
    } catch (_) {
      if (mounted) {
        PlannerNotificationRepository.restore(n);
        setState(() => _items.insert(0, n));
        _showSnackBar('Could not archive notification.');
      }
    }
  }

  Future<void> _markAllRead() async {
    final backup = List<plannerNotification>.from(_items);

    PlannerNotificationRepository.markAllRead();
    setState(() => _items = PlannerNotificationRepository.cachedNotifications);

    try {
      final result = await PlannerNotificationRepository.markAllReadRemote();
      if (result is Map && result['success'] == false) {
        throw Exception('Failed to mark all read');
      }
    } catch (_) {
      PlannerNotificationRepository.setNotifications(backup);
      if (mounted) {
        setState(() => _items = backup);
        _showSnackBar('Could not mark all as read.');
      }
      unawaited(_loadNotifications(forceRefresh: true));
    }
  }

  Future<void> _clearAll() async {
    final backup = List<plannerNotification>.from(_items);

    PlannerNotificationRepository.clearNotifications();
    setState(() => _items.clear());

    try {
      final result = await PlannerNotificationRepository.clearAllRemote();
      if (result is Map && result['success'] == false) {
        throw Exception('Failed to clear notifications');
      }
    } catch (_) {
      PlannerNotificationRepository.setNotifications(backup);
      if (mounted) {
        setState(() => _items = backup);
        _showSnackBar('Could not clear notifications.');
      }
    }
  }

  Future<void> _markNotificationRead(plannerNotification n) async {
    if (n.isRead) return;

    // Optimistic update first
    PlannerNotificationRepository.markOneRead(n);
    setState(() => _items = PlannerNotificationRepository.cachedNotifications);

    try {
      final result = await PlannerNotificationRepository.markNotificationRead(
        n.id,
      );
      if (result is Map && result['success'] == false) {
        throw Exception('Failed to mark notification read');
      }
    } catch (e) {
      debugPrint('Mark notification read error: $e');
      // Reload to get correct state
      unawaited(_loadNotifications(forceRefresh: true));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.burgundy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadNotifications(forceRefresh: true),
          color: AppColors.darkpink,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                Text(
                  'Stay on top of everything',
                  style: TextStyle(fontSize: 15, color: AppColors.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSummaryRow(),
                const SizedBox(height: 20),
                _buildFilterTabs(),
                const SizedBox(height: 16),
                Expanded(child: _buildList()),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //build header
  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context, _unread);
            },
            child: const Icon(
              FontAwesomeIcons.xmark,
              color: AppColors.darkpink,
              size: 22,
            ),
          ),
        ),
        Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: AppColors.burgundy,
          ),
        ),
      ],
    );
  }

  // notifications icons
  Widget _buildSummaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.blue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_total',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.burgundy,
              ),
            ),
            Text(
              'Total Today',
              style: TextStyle(color: AppColors.green, fontSize: 13),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: Colors.orange.withOpacity(0.12),
              ),
              child: Icon(Icons.inbox_rounded, size: 24, color: Colors.orange),
            ),
            const SizedBox(height: 6),
            Text(
              '$_unread',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.burgundy,
              ),
            ),
            Text(
              'Unread',
              style: TextStyle(color: AppColors.green, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  //filter tabs

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Filtertab(
            label: 'All',
            ontap: () => setState(() => _filter = 'all'),
            icon: Icons.apps_rounded,
            isSelected: _filter == 'all',
          ),

          const SizedBox(width: 10),

          Filtertab(
            label: 'Requests',
            ontap: () => setState(() => _filter = 'request'),
            icon: Icons.request_page_rounded,
            isSelected: _filter == 'request',
          ),

          const SizedBox(width: 10),

          Filtertab(
            label: 'Messages',
            ontap: () => setState(() => _filter = 'message'),
            icon: Icons.chat_bubble_outline_rounded,
            isSelected: _filter == 'message',
          ),

          const SizedBox(width: 10),

          Filtertab(
            label: 'Orders',
            ontap: () => setState(() => _filter = 'order'),
            icon: Icons.shopping_cart_rounded,
            isSelected: _filter == 'order',
          ),
          const SizedBox(width: 10),

          Filtertab(
            label: 'Tasks',
            ontap: () => setState(() => _filter = 'task'),
            icon: Icons.task_alt_rounded,
            isSelected: _filter == 'task',
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;

    if (_isLoading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkpink),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.green.withOpacity(0.5),
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.green, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadNotifications(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.notifications_off_rounded,
              color: AppColors.green.withOpacity(0.5),
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              'No notifications',
              style: TextStyle(color: AppColors.green, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(forceRefresh: true),
      child: ListView.separated(
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final n = list[i];
          return Dismissible(
            key: Key(n.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.burgundy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.coral,
                size: 30,
              ),
            ),
            onDismissed: (_) => _dismissNotification(n),
            child: GestureDetector(
              onTap: () async {
                // Mark as read first
                if (!n.isRead) {
                  await _markNotificationRead(n);
                }

                // Then navigate based on notification type
                if (n.title == 'New Order Placed' && n.actionUrl != null) {
                  final uri = Uri.tryParse(n.actionUrl!);
                  final segments = uri?.pathSegments ?? [];
                  final eventIndex = segments.indexOf('events');
                  final vendorIndex = segments.indexOf('vendors');
                  if (eventIndex != -1 && vendorIndex != -1 && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorDetailsScreen(
                          eventId: segments[eventIndex + 1],
                          vendorId: segments[vendorIndex + 1],
                        ),
                      ),
                    );
                  }
                } else if (n.title.startsWith('New Message from') &&
                    n.actionUrl != null) {
                  final uri = Uri.tryParse(n.actionUrl!);
                  final segments = uri?.pathSegments ?? [];
                  final eventIndex = segments.indexOf('events');
                  if (eventIndex != -1 &&
                      eventIndex + 1 < segments.length &&
                      mounted) {
                    final eventId = int.tryParse(segments[eventIndex + 1]);
                    if (eventId != null) {
                      final clientName = n.title
                          .replaceFirst('New Message from', '')
                          .trim();
                      final eventName = n.message
                          .replaceFirst('Regarding your event:', '')
                          .trim();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            eventId: eventId,
                            eventName: eventName.isNotEmpty
                                ? eventName
                                : 'Chat',
                            plannerName: clientName.isNotEmpty
                                ? clientName
                                : 'Client',
                            isPlanner: true,
                            onRead: null,
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: n.isRead
                            ? Colors.pink.withOpacity(0.01)
                            : Colors.pink.withOpacity(0.1),
                      ),
                      child: Icon(
                        n.type == 'request'
                            ? Icons.request_page_rounded
                            : n.type == 'message'
                            ? Icons.chat_bubble_outline_rounded
                            : n.type == 'task'
                            ? Icons.task_alt_rounded
                            : n.type == 'order'
                            ? Icons.shopping_cart_rounded
                            : n.priority == 'urgent'
                            ? Icons.error_rounded
                            : Icons.notifications_none_rounded,
                        color: AppColors.darkpink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: n.isRead
                                        ? Colors.grey
                                        : AppColors.burgundy,
                                    fontWeight: n.isRead
                                        ? FontWeight.w400
                                        : FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                n.timeAgo(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            n.message,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _unread == 0 ? null : _markAllRead,

            icon: const Icon(
              Icons.done_all_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              'Mark Read',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              disabledBackgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _items.isEmpty ? null : _clearAll,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.darkpink,
            ),
            label: const Text(
              'Clear',
              style: TextStyle(color: AppColors.darkpink),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkpink,
              backgroundColor: AppColors.cream,
              side: BorderSide(color: AppColors.darkpink),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
