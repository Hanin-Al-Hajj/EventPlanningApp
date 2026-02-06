import 'package:event_planner/screens/vendors_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/models/timeline_task.dart';
import 'package:event_planner/db/timeline_storage.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/screens/GuestList_screen.dart';
import 'package:event_planner/screens/budget_tracker_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TimelineTask> _timelineTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadTimelineTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTimelineTasks() async {
    setState(() => _isLoading = true);
    try {
      await TimelineStorage.ensureDefaultTasks(widget.event.id);
      final tasks = await TimelineStorage.getTasksByEvent(widget.event.id);
      setState(() {
        _timelineTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading timeline: $e')));
      }
    }
  }

  Future<void> _toggleTaskCompletion(TimelineTask task) async {
    await TimelineStorage.toggleTaskCompletion(task.id);
    await _loadTimelineTasks();
    await updateEventProgress(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: _tabController.index == 0
          ? AppBar(
              backgroundColor: const Color(0xFF586041),
              foregroundColor: Colors.white,
              title: Text(widget.event.title),
              actions: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
              ],
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildTimelineTab(),
          GuestListScreen(
            eventID: widget.event.id,
            eventName: widget.event.title,
          ),
          const VendorsScreen(),
          BudgetTrackerScreen(event: widget.event),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF586041),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF586041),
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.people), text: 'Guests'),
            Tab(icon: Icon(Icons.business), text: 'Vendors'),
            Tab(icon: Icon(Icons.attach_money), text: 'Budget'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline Checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151910),
            ),
          ),
          const SizedBox(height: 16),
          ..._timelineTasks.map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) => _toggleTaskCompletion(task),
                    activeColor: const Color(0xFF586041),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? Colors.grey.shade500
                                : const Color(0xFF151910),
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.timeframe,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
