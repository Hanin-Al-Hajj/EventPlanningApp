import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/plannerNotification.dart';
import 'package:event_planner/widgets/planner/filterTab.dart';

class PlannerNotificationScreen extends StatefulWidget {
  final List<plannerNotification> notifications;
  const PlannerNotificationScreen({super.key, required this.notifications});

  @override
  State<PlannerNotificationScreen> createState() =>
      _PlannerNotificationScreenState();
}

class _PlannerNotificationScreenState extends State<PlannerNotificationScreen> {
  late List<plannerNotification> _items;
  String _filter = 'all';

  int get _total => _items.length;
  int get _unread => _items.where((n) => n.isRead).length;
  int get _urgent => _items.where((n) => n.priority == 'urgent').length;

  List<plannerNotification> get _filtered => _filter == 'all'
      ? _items
      : _items.where((n) => n.type == _filter).toList();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.notifications);
  }

  @override
  void dispose() {
    super.dispose();
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
            ontap: () => setState(() => _filter = 'requests'),
            icon: Icons.request_page_rounded,
            isSelected: _filter == 'requests',
          ),

          const SizedBox(width: 10),

          Filtertab(
            label: 'Messages',
            ontap: () => setState(() => _filter = 'messages'),
            icon: Icons.chat_bubble_outline_rounded,
            isSelected: _filter == 'messages',
          ),

          const SizedBox(width: 10),

          Filtertab(
            label: 'Tasks',
            ontap: () => setState(() => _filter = 'tasks'),
            icon: Icons.task_alt_rounded,
            isSelected: _filter == 'tasks',
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
              size: 18,
            ),
          ),
          onDismissed: (_) {
            setState(() => _items.removeWhere((item) => item.id == n.id));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    color: Colors.pink.withOpacity(0.5),
                  ),
                  child: Icon(
                    n.type == 'requests'
                        ? Icons.request_page_rounded
                        : n.type == 'messages'
                        ? Icons.chat_bubble_outline_rounded
                        : n.type == 'tasks'
                        ? Icons.task_alt_rounded
                        : n.type == 'urgent'
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
                          Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.burgundy,
                            ),
                          ),
                          Text(
                            n.createdAt.toString(),
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        style: TextStyle(color: AppColors.green, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
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
            onPressed: () {},
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
            onPressed: () {},
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
