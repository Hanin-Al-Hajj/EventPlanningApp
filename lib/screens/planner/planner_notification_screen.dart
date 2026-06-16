import 'package:event_planner/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/plannerNotification.dart';
import 'package:event_planner/widgets/planner/filterTab.dart';

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

  int get _total => _items.length;
  int get _unread => _items.where((n) => !n.isRead).length;
  int get _urgent => _items.where((n) => n.priority == 'urgent').length;

  List<plannerNotification> get _filtered {
    if (_filter == 'all') return _items;
    if (_filter == 'urgent') {
      return _items.where((n) => n.priority == 'urgent').toList();
    }
    return _items.where((n) => n.type == _filter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  //Api calls

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getPlannerNotifications();

      if (!mounted) return;
      if (data['success'] == true || data['notifications'] != null) {
        final raw = data['notifications'] as List<dynamic>? ?? [];
        setState(() {
          _items = raw
              .map(
                (e) => plannerNotification.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissNotification(plannerNotification n) async {
    // Optimistic removal
    setState(() => _items.removeWhere((item) => item.id == n.id));

    try {
      await ApiService.archivePlannerNotification(n.id);
    } catch (_) {
      // Restore on failure
      if (mounted) {
        setState(() => _items.insert(0, n));
        _showSnackBar('Could not archive notification.');
      }
    }
  }

  Future<void> _markAllRead() async {
    // Optimistic update
    setState(() {
      _items = _items
          .map(
            (n) => plannerNotification(
              id: n.id,
              userId: n.userId,
              type: n.type,
              priority: n.priority,
              title: n.title,
              message: n.message,
              icon: n.icon,
              actionUrl: n.actionUrl,
              isRead: true,
              readAt: n.readAt ?? DateTime.now(),
              createdAt: n.createdAt,
            ),
          )
          .toList();
    });

    try {
      await ApiService.markAllPlannerNotificationsRead();
    } catch (_) {
      if (mounted) _showSnackBar('Could not mark all as read.');
      await _loadNotifications(); // Refresh to real state
    }
  }

  Future<void> _clearAll() async {
    final backup = List<plannerNotification>.from(_items);

    // Optimistic clear
    setState(() => _items.clear());

    try {
      await ApiService.deleteAllPlannerNotifications();
    } catch (_) {
      if (mounted) {
        setState(() => _items = backup);
        _showSnackBar('Could not clear notifications.');
      }
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
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.close, color: AppColors.darkpink, size: 29),
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
              'Total',
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
        Column(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: Colors.pink.withOpacity(0.12),
              ),
              child: Icon(Icons.error_rounded, size: 24, color: Colors.pink),
            ),
            const SizedBox(height: 6),
            Text(
              '$_urgent',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.burgundy,
              ),
            ),
            Text(
              'Urgent',
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
            label: 'Tasks',
            ontap: () => setState(() => _filter = 'task'),
            icon: Icons.task_alt_rounded,
            isSelected: _filter == 'task',
          ),

          const SizedBox(width: 10),

          Filtertab(
            label: 'Urgent',
            ontap: () => setState(() => _filter = 'urgent'),
            icon: Icons.error_rounded,
            isSelected: _filter == 'urgent',
          ),
        ],
      ),
    );
  }

  //messages list
  Widget _buildList() {
    final list = _filtered;
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

    return ListView.separated(
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
              if (!n.isRead) {
                await ApiService.markPlannerNotificationRead(n.id);
                setState(() {
                  final index = _items.indexWhere((item) => item.id == n.id);
                  if (index != -1) {
                    _items[index] = plannerNotification(
                      id: n.id,
                      userId: n.userId,
                      type: n.type,
                      priority: n.priority,
                      title: n.title,
                      message: n.message,
                      icon: n.icon,
                      actionUrl: n.actionUrl,
                      isRead: true,
                      readAt: DateTime.now(),
                      createdAt: n.createdAt,
                    );
                  }
                });
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
                borderRadius: BorderRadiusGeometry.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
