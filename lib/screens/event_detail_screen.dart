import 'package:event_planner/screens/vendors_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/models/timeline_task.dart';
import 'package:event_planner/db/timeline_storage.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/screens/GuestList_screen.dart';
import 'package:event_planner/screens/budget_tracker_screen.dart';
import 'package:intl/intl.dart';

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
      // Ensure default tasks exist for this event
      await TimelineStorage.ensureDefaultTasks(widget.event.id);

      // Load tasks
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
    // Update event progress after timeline change
    await updateEventProgress(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF586041),
        foregroundColor: Colors.white,
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit event screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151910),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • h:mm a',
                      ).format(widget.event.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.event.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${widget.event.guests} Guests Expected',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '\$${widget.event.budget.toStringAsFixed(0)} Budget',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF586041),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF586041),
              tabs: const [
                Tab(text: 'Timeline'),
                Tab(text: 'Guests'),
                Tab(text: 'Vendors'),
                Tab(text: 'Budget'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Timeline Tab
                _buildTimelineTab(),
                // Guests Tab
                _buildGuestsTab(),
                // Vendors Tab
                _buildVendorsTab(),
                // Budget Tab
                _buildBudgetTab(),
              ],
            ),
          ),
        ],
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
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGuestsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Guest Management',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuestListScreen(
                    eventID: widget.event.id,
                    eventName: widget.event.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.group_add),
            label: const Text('Manage Guests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF586041),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Vendor Management',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VendorsScreen()),
              );
            },
            icon: const Icon(Icons.business),
            label: const Text('Manage Vendors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF586041),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Budget Tracking',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BudgetTrackerScreen(event: widget.event),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Manage Budget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF586041),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
