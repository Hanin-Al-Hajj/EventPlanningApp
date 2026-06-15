import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventPlannerFAB extends StatefulWidget {
  final VoidCallback? onMyEvent;
  final VoidCallback? onArchiveEvent;
  final VoidCallback? onAnalytics;
  final VoidCallback? onMessage;

  const EventPlannerFAB({
    super.key,
    this.onMyEvent,
    this.onArchiveEvent,
    this.onAnalytics,
    this.onMessage,
  });

  @override
  State<EventPlannerFAB> createState() => _EventPlannerFABState();
}

class _EventPlannerFABState extends State<EventPlannerFAB>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _controller.forward() : _controller.reverse();
  }

  void _close() {
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        //  Sub buttons anchored ABOVE the main FAB
        Positioned(
          bottom: 64, // sits just above the 56px FAB
          right: 7,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fabItem(
                    label: 'My Events',
                    icon: Icons.event,
                    color: AppColors.darkpink,
                    onTap: () {
                      _close();
                      widget.onMyEvent?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _fabItem(
                    label: 'Archive',
                    icon: Icons.archive_outlined,
                    color: AppColors.darkpink,
                    onTap: () {
                      _close();
                      widget.onArchiveEvent?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _fabItem(
                    label: 'Analytics',
                    icon: Icons.analytics_outlined,
                    color: AppColors.darkpink,
                    onTap: () {
                      _close();
                      widget.onAnalytics?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _fabItem(
                    label: 'Messages',
                    icon: FontAwesomeIcons.message,
                    color: AppColors.darkpink,
                    onTap: () {
                      _close();
                      widget.onMessage?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),

        //  Main FAB
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isOpen ? AppColors.burgundy : AppColors.darkpink,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkpink.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 250),
              turns: _isOpen ? 0.125 : 0,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  // In _fabItem, wrap the whole Row in a Container with Material
  Widget _fabItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coral.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 10),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                // ✅ Wrap icon in Material
                color: color,
                shape: const CircleBorder(),
                elevation: 4,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
