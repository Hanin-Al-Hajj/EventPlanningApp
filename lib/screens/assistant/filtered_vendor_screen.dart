import 'dart:async';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/repositories/filtered_vendor_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/screens/assistant/place_order_screen.dart';
import 'package:event_planner/screens/vendor_details_screen.dart';

class FilteredVendorScreen extends StatefulWidget {
  final int taskId;

  const FilteredVendorScreen({super.key, required this.taskId});

  @override
  State<FilteredVendorScreen> createState() => _FilteredVendorScreenState();
}

class _FilteredVendorScreenState extends State<FilteredVendorScreen> {
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, bool> _orderStatus = {};

  @override
  void initState() {
    super.initState();
    FilteredVendorRepository.taskVendors.addListener(_onVendorsChanged);
    FilteredVendorRepository.orderStatuses.addListener(_onOrderStatusesChanged);

    if (FilteredVendorRepository.hasCache(widget.taskId)) {
      _vendors = FilteredVendorRepository.getCachedVendors(widget.taskId);
      _orderStatus = FilteredVendorRepository.getCachedOrderStatus(
        widget.taskId,
      );
      _isLoading = false;
      unawaited(
        FilteredVendorRepository.loadTaskVendors(
          widget.taskId,
          forceRefresh: true,
        ),
      );
      unawaited(FilteredVendorRepository.loadOrderStatuses(widget.taskId));
    } else {
      unawaited(_loadData());
    }
  }

  @override
  void dispose() {
    FilteredVendorRepository.taskVendors.removeListener(_onVendorsChanged);
    FilteredVendorRepository.orderStatuses.removeListener(
      _onOrderStatusesChanged,
    );
    super.dispose();
  }

  void _onVendorsChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _vendors = FilteredVendorRepository.getCachedVendors(widget.taskId);
        _isLoading = false;
        _errorMessage = null;
      });
    });
  }

  void _onOrderStatusesChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _orderStatus = FilteredVendorRepository.getCachedOrderStatus(
          widget.taskId,
        );
      });
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!forceRefresh && FilteredVendorRepository.hasCache(widget.taskId)) {
      setState(() {
        _vendors = FilteredVendorRepository.getCachedVendors(widget.taskId);
        _orderStatus = FilteredVendorRepository.getCachedOrderStatus(
          widget.taskId,
        );
        _isLoading = false;
        _errorMessage = null;
      });
      unawaited(
        FilteredVendorRepository.loadTaskVendors(
          widget.taskId,
          forceRefresh: true,
        ),
      );
      unawaited(FilteredVendorRepository.loadOrderStatuses(widget.taskId));
      return;
    }

    if (_vendors.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await FilteredVendorRepository.loadTaskVendors(
        widget.taskId,
        forceRefresh: forceRefresh,
      );
      await FilteredVendorRepository.loadOrderStatuses(widget.taskId);

      if (!mounted) return;

      setState(() {
        _vendors = FilteredVendorRepository.getCachedVendors(widget.taskId);
        _orderStatus = FilteredVendorRepository.getCachedOrderStatus(
          widget.taskId,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _vendors.isEmpty
            ? 'Something went wrong. Please try again.'
            : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
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
              ),
              const Text(
                'Assigned Vendors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.burgundy,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.darkpink),
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
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadData(forceRefresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _vendors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    // ignore: deprecated_member_use
                    color: AppColors.green.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vendors assigned',
                    style: TextStyle(
                      fontSize: 16,
                      // ignore: deprecated_member_use
                      color: AppColors.green.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadData(forceRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vendors.length,
                itemBuilder: (context, index) =>
                    _buildVendorCard(_vendors[index]),
              ),
            ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 150,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: _getVendorImage(vendor.imageIcon),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendor.category,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${vendor.rating}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'View Details',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VendorDetailsScreen(vendorId: vendor.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: _orderStatus[int.parse(vendor.id)] == true
                        ? 'Update Order'
                        : 'Place Order',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceOrderScreen(
                            taskId: widget.taskId,
                            vendorId: int.parse(vendor.id),
                            vendorName: vendor.name,
                          ),
                        ),
                      ).then(
                        (_) => FilteredVendorRepository.loadOrderStatuses(
                          widget.taskId,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: onPressed == null ? Colors.grey : AppColors.darkpink,
        side: BorderSide(
          color: onPressed == null ? Colors.grey : AppColors.darkpink,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(label),
    );
  }

  ImageProvider _getVendorImage(String imageIcon) {
    if (imageIcon.isEmpty) return const AssetImage('assets/images/image.png');
    if (imageIcon.startsWith('http://') || imageIcon.startsWith('https://')) {
      return NetworkImage(imageIcon);
    }
    return NetworkImage('http://127.0.0.1:8000/$imageIcon');
  }
}
