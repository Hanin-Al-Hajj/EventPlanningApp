import 'dart:async';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/vendor_order.dart';
import 'package:event_planner/repositories/vendor_order_repository.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/assistant/place_order_screen.dart';
import 'package:event_planner/screens/assistant/filtered_vendor_screen.dart';
import 'package:event_planner/screens/assistant/assistant_setting.dart';
import 'package:event_planner/screens/assistant/assistant_profile_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<VendorOrder> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    VendorOrderRepository.orders.addListener(_onOrdersChanged);

    if (VendorOrderRepository.hasCache) {
      _orders = VendorOrderRepository.cachedOrders;
      _isLoading = false;
      unawaited(VendorOrderRepository.refreshInBackground());
    } else {
      unawaited(_loadOrders());
    }
  }

  @override
  void dispose() {
    VendorOrderRepository.orders.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _orders = VendorOrderRepository.cachedOrders;
        _isLoading = false;
        _errorMessage = null;
      });
    });
  }

  Future<void> _loadOrders({bool forceRefresh = false}) async {
    if (!forceRefresh && VendorOrderRepository.hasCache) {
      setState(() {
        _orders = VendorOrderRepository.cachedOrders;
        _isLoading = false;
        _errorMessage = null;
      });
      unawaited(VendorOrderRepository.refreshInBackground());
      return;
    }

    if (_orders.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await VendorOrderRepository.loadOrders(forceRefresh: forceRefresh);
      if (!mounted) return;

      setState(() {
        _orders = VendorOrderRepository.cachedOrders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _orders.isEmpty
            ? 'Something went wrong. Please try again.'
            : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.burgundy),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.burgundy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.burgundy),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ApiService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkpink),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.darkpink)),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(VendorOrder order) async {
    VendorOrderRepository.remove(order);
    setState(() => _orders.removeWhere((item) => item.id == order.id));

    try {
      final result = await VendorOrderRepository.deleteOrder(order.id);
      if (result is Map && result['success'] != true && mounted) {
        VendorOrderRepository.restore(order);
        setState(() => _orders.insert(0, order));
        _showSnackBar('Could not delete order.', isError: true);
      } else if (mounted) {
        _showSnackBar('Order deleted successfully.');
      }
    } catch (_) {
      if (mounted) {
        VendorOrderRepository.restore(order);
        setState(() => _orders.insert(0, order));
        _showSnackBar('Could not delete order.', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.burgundy : AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PopupMenuButton<String>(
                          offset: const Offset(0, 45),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            _popupItem(
                              'profile',
                              Icons.person_outline,
                              'Profile',
                            ),
                            _popupItem(
                              'settings',
                              Icons.settings_outlined,
                              'Settings',
                            ),
                            _popupItem('logout', Icons.logout, 'Logout'),
                          ],
                          onSelected: (value) {
                            if (value == 'profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AssistantProfileScreen(),
                                ),
                              );
                            } else if (value == 'settings') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AssistantSetting(),
                                ),
                              );
                            } else if (value == 'logout') {
                              _handleLogout();
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.darkpink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const Text(
                            'My Orders',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.burgundy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track all your vendor orders',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkpink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Orders List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.darkpink,
                          ),
                        )
                      : _errorMessage != null && _orders.isEmpty
                      ? _buildError()
                      : _orders.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () => _loadOrders(forceRefresh: true),
                          color: AppColors.darkpink,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) =>
                                _buildOrderCard(_orders[index]),
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _loadOrders(forceRefresh: true),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            // ignore: deprecated_member_use
            color: AppColors.green.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders placed yet',
            style: TextStyle(
              fontSize: 16,
              // ignore: deprecated_member_use
              color: AppColors.green.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders you place for tasks will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(VendorOrder order) {
    return Dismissible(
      key: Key(order.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.burgundy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Order',
              style: TextStyle(color: AppColors.burgundy),
            ),
            content: Text('Remove this order for "${order.vendorName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.burgundy),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkpink,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteOrder(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.taskTitle.isNotEmpty
                        ? order.taskTitle
                        : 'Unnamed Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${order.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vendor
            Row(
              children: [
                const Icon(Icons.store, size: 14, color: AppColors.darkpink),
                const SizedBox(width: 5),
                Text(
                  order.vendorName.isNotEmpty
                      ? order.vendorName
                      : 'Unknown Vendor',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.darkpink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Event name
            if (order.eventName.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    order.eventName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

            // Notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppColors.cream.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2,
                      size: 13,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),

            // Date + Edit button + View Vendors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Row(
                  children: [
                    // View Vendors button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FilteredVendorScreen(taskId: order.taskId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'View Vendors',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit Order button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceOrderScreen(
                              taskId: order.taskId,
                              vendorId: order.vendorId,
                              vendorName: order.vendorName,
                            ),
                          ),
                        ).then((_) => _loadOrders(forceRefresh: true));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.darkpink),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Edit Order',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkpink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    // ignore: deprecated_member_use
    p.color = AppColors.coral.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 130, p);
    // ignore: deprecated_member_use
    p.color = AppColors.darkpink.withOpacity(0.07);
    canvas.drawCircle(Offset(size.width * -0.12, size.height * 0.48), 170, p);
    // ignore: deprecated_member_use
    p.color = const Color.fromARGB(255, 176, 27, 44).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.72), 190, p);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => false;
}
