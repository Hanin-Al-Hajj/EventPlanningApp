import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/timeline_task.dart';
import 'package:event_planner/db/timeline_storage.dart';

class AddTask extends StatefulWidget {
  final String eventId;
  final VoidCallback onTaskAdded;

  const AddTask({super.key, required this.eventId, required this.onTaskAdded});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final _titleController = TextEditingController();
  final _timeframeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    final timeframe = _timeframeController.text.trim();

    if (title.isEmpty) return;

    final newTask = TimelineTask(
      id: '${widget.eventId}_task_${DateTime.now().millisecondsSinceEpoch}',
      eventId: widget.eventId,
      title: title,
      timeframe: timeframe.isEmpty ? 'No timeframe' : timeframe,
      daysBeforeEvent: 0,
    );

    await TimelineStorage.insertTask(newTask);
    widget.onTaskAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add New Task',
        style: TextStyle(
          color: AppColors.darkpink,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Task title',
              filled: true,
              fillColor: Colors.white,
              labelStyle: TextStyle(color: AppColors.burgundy),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.burgundy),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.burgundy,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeframeController,
            decoration: InputDecoration(
              labelText: 'Timeframe',
              filled: true,
              fillColor: Colors.white,
              labelStyle: TextStyle(color: AppColors.burgundy),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.burgundy),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.burgundy,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.darkpink)),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkpink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
