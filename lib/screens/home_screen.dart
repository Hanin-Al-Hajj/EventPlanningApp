import 'package:event_planner/screens/GuestList_screen.dart';
import 'package:event_planner/screens/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/widgets/event_card.dart';
import 'package:event_planner/widgets/quick_action_button.dart';
import 'package:event_planner/db/event_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onAddEvent,
    required this.onDeleteEvent,
    required this.registeredEvents,
  });
  final Function(Event) onAddEvent;
  final Function(Event) onDeleteEvent;
  final List<Event> registeredEvents;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Calculate active events count
  int get activeEventsCount {
    return widget.registeredEvents
        .where(
          (event) =>
              event.status == 'In Progress' || event.status == 'Planning',
        )
        .length;
  }

  // Calculate days until next event
  int get daysUntilNextEvent {
    if (widget.registeredEvents.isEmpty) return 0;

    final now = DateTime.now();
    final upcomingEvents =
        widget.registeredEvents
            .where((event) => event.date.isAfter(now))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isEmpty) return 0;

    return upcomingEvents.first.date.difference(now).inDays;
  }

  // Navigate to Create Event screen and handle result
  void _navigateToCreateEvent() async {
    final newEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );

    if (newEvent != null) {
      widget.onAddEvent(newEvent);
    }
  }

  // Navigate to Edit Event screen
  void _editEvent(Event event) async {
    final updatedEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(eventToEdit: event),
      ),
    );

    if (updatedEvent != null) {
      widget.onDeleteEvent(event); // Remove old version
      widget.onAddEvent(updatedEvent);
      updateEvent(updatedEvent); // Add updated version
    }
  }

  void navigateToGuestList() {
    // If no events, show a SnackBar

    if (widget.registeredEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create an event first before adding guests'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If only one event, go directly to its guest list
    if (widget.registeredEvents.length == 1) {
      final event = widget.registeredEvents.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GuestListScreen(eventID: event.id, eventName: event.title),
        ),
      );
      return;
    }

    // If multiple events, **show a dialog to select one**
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Event'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.registeredEvents.length,
            itemBuilder: (context, index) {
              final event = widget.registeredEvents[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF545A3B),
                  child: const Icon(Icons.event, color: Colors.white, size: 20),
                ),
                title: Text(event.title),
                subtitle: Text(event.location),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GuestListScreen(
                        eventID: event.id,
                        eventName: event.title,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: const BoxDecoration(color: Color(0xFF586041)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EventFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: const Color.fromARGB(
                              255,
                              124,
                              132,
                              92,
                            ),
                            child: const Text(
                              'JD',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search Bar inside header
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search events, vendors...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 1),

                      // Stats Cards (now dynamic)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$activeEventsCount',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF151910),
                                    ),
                                  ),
                                  const Text(
                                    'Active Events',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15.7),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$daysUntilNextEvent',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF151910),
                                    ),
                                  ),
                                  const Text(
                                    'Days Until Next Event',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Upcoming Events Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF545A3B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Show events or empty state
                      widget.registeredEvents.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No events yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first event to get started',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: widget.registeredEvents.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: EventCard(
                                    event: event,
                                    onDelete: () => widget.onDeleteEvent(event),
                                    onTap: () => _editEvent(event),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 24),

                      // Quick Actions Section
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        children: [
                          QuickActionButton(
                            icon: Icons.add,
                            label: 'New Event',
                            onTap: _navigateToCreateEvent,
                          ),
                          QuickActionButton(
                            icon: Icons.group_add_outlined,
                            label: 'Add Guests',
                            onTap: navigateToGuestList,
                          ),
                          QuickActionButton(
                            icon: Icons.search,
                            label: 'Find Vendors',
                            onTap: () {},
                          ),
                          QuickActionButton(
                            icon: Icons.attach_money,
                            label: 'Track Budget',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
