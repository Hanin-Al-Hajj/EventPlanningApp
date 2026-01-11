import 'package:event_planner/screens/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/widgets/event_card.dart';
import 'package:event_planner/widgets/quick_action_button.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/screens/vendors_screen.dart';

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
  bool _isLoadingEvents = false;

  int get activeEventsCount {
    return widget.registeredEvents
        .where(
          (event) =>
              event.status == 'In Progress' || event.status == 'Planning',
        )
        .length;
  }

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

  Future<void> _refreshEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final updatedEvents = await loadEventsWithCalculatedProgress();

      for (var event in widget.registeredEvents.toList()) {
        widget.onDeleteEvent(event);
      }

      for (var event in updatedEvents) {
        widget.onAddEvent(event);
      }
    } catch (e) {
      print('Error refreshing events: $e');
    } finally {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _navigateToCreateEvent() async {
    final newEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );

    if (newEvent != null) {
      widget.onAddEvent(newEvent);
      await _refreshEvents();
    }
  }

  Future<void> _editEvent(Event event) async {
    final updatedEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(eventToEdit: event),
      ),
    );

    if (updatedEvent != null) {
      widget.onDeleteEvent(event);
      widget.onAddEvent(updatedEvent);
      updateEvent(updatedEvent);
      await _refreshEvents();
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Color(0xFF586041)),
              child: Column(
                children: [
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EventFlow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            //main context
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshEvents,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //stat cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$activeEventsCount',
                                      style: const TextStyle(
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
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$daysUntilNextEvent',
                                      style: const TextStyle(
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
                        const SizedBox(height: 24),

                        //upcomming events
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

                        //list of events that are created
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
                                      onDelete: () =>
                                          widget.onDeleteEvent(event),
                                      onTap: () => _editEvent(event),
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 24),

                        //action button
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
                              icon: Icons.search,
                              label: 'Find Vendors',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const VendorsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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
