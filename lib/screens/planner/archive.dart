import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Archive extends StatefulWidget {
  const Archive({super.key});

  @override
  State<Archive> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<Archive> {
  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _unarchivedSomething = false;

  @override
  void initState() {
    super.initState();
    _loadArchivedEvents();
  }

  Future<void> _loadArchivedEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getArchivedPlannerEvents();
      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final eventsJson = data is Map ? data['events'] : null;

        if (eventsJson is! List) {
          setState(() {
            _errorMessage = 'Invalid events data';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _events = eventsJson
              .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load archived events';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Future<void> _unarchiveEvent(Event event) async {
    final parsedId = int.tryParse(event.id);
    if (parsedId == null) return;

    final removedIndex = _events.indexWhere((e) => e.id == event.id);
    final removedEvent = removedIndex != -1 ? _events[removedIndex] : null;

    // Optimistically remove from the archived list
    setState(() {
      _events.removeWhere((e) => e.id == event.id);
    });

    try {
      final result = await ApiService.unarchivePlannerEvent(parsedId);
      if (!mounted) return;

      if (result['success'] == true) {
        _unarchivedSomething = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${event.title}" moved back to My Events'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        if (removedEvent != null) {
          setState(() {
            _events.insert(removedIndex, removedEvent);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to unarchive event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (removedEvent != null) {
        setState(() {
          _events.insert(removedIndex, removedEvent);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () =>
                            Navigator.pop(context, _unarchivedSomething),
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
                      const SizedBox(width: 15),
                      const Text(
                        'Archived events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.darkpink,
                          ),
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadArchivedEvents,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.archive_outlined,
                                size: 64,
                                color: AppColors.green.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No archived events',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.green.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadArchivedEvents,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              return _buildEventCard(event);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final formattedDate =
        '${event.date.day}/${event.date.month}/${event.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.burgundy,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _unarchiveEvent(event),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.unarchive_outlined,
                        size: 14,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline, event.clientName ?? 'N/A'),
          const SizedBox(height: 4),
          Row(
            children: [
              _infoRow(FontAwesomeIcons.calendarDays, formattedDate),
              const SizedBox(width: 16),
              Expanded(child: _infoRow(Icons.location_on, event.location)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _infoRow(Icons.people_outline, '${event.guests} guests'),
              const SizedBox(width: 16),
              _infoRow(Icons.attach_money, '\$${event.budget}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.coral),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = AppColors.coral.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 130, p);
    p.color = AppColors.darkpink.withOpacity(0.07);
    canvas.drawCircle(Offset(size.width * -0.12, size.height * 0.48), 170, p);
    p.color = const Color.fromARGB(255, 176, 27, 44).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.72), 190, p);
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => false;
}
