/*import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/models/timeline_task.dart';
import 'package:event_planner/db/timeline_storage.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/widgets/add_task.dart';

class CheckListScreen extends StatefulWidget {
  final Event event;

  const CheckListScreen({super.key, required this.event});

  @override
  State<CheckListScreen> createState() => _CheckListScreenState();
}

class _CheckListScreenState extends State<CheckListScreen> {
  List<TimelineTask> _timelineTasks = [];
  bool _isLoading = true;
  late Event _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadTimelineTasks();
  }

  Future<void> _popWithUpdatedEvent() async {
    try {
      await updateEventProgress(_currentEvent.id);
      final events = await loadEvents();
      final updatedEvent = events.firstWhere(
        (e) => e.id == _currentEvent.id,
        orElse: () => _currentEvent,
      );
      if (mounted) Navigator.pop(context, updatedEvent);
    } catch (e) {
      if (mounted) Navigator.pop(context, _currentEvent);
    }
  }

  @override
  void dispose() {
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
    return WillPopScope(
      onWillPop: () async {
        await _popWithUpdatedEvent();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          toolbarHeight: 76,
          automaticallyImplyLeading: false,
          titleSpacing: 0,

          title: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Row(
              children: [
                InkWell(
                  onTap: _popWithUpdatedEvent,
                  borderRadius: BorderRadius.circular(22),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.arrowLeft,
                        size: 20,
                        color: AppColors.darkpink,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _currentEvent.title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddTask(
                        eventId: _currentEvent.id,
                        onTaskAdded: _loadTimelineTasks,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.circlePlus,
                        size: 28,
                        color: AppColors.darkpink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        body: _buildTimelineTab(),
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
          Row(
            children: [
              Text(
                'Timeline Checklist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._timelineTasks.map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) => _toggleTaskCompletion(task),
                    activeColor: AppColors.darkpink,
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
                                ? AppColors.green
                                : AppColors.burgundy,
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
                            color: AppColors.green,
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
*/