import 'package:event_planner/models/vendor_order.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class VendorOrderRepository {
  static final ValueNotifier<List<VendorOrder>> orders =
      ValueNotifier<List<VendorOrder>>([]);

  static bool _loadedOnce = false;
  static Future<void>? _runningLoad;

  static List<VendorOrder> get cachedOrders => orders.value;

  static bool get hasCache => _loadedOnce;

  static Future<void> loadOrders({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;

    final runningLoad = _runningLoad;
    if (runningLoad != null) return runningLoad;

    _runningLoad = _fetchOrders();

    try {
      await _runningLoad;
    } finally {
      _runningLoad = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadOrders(forceRefresh: true);
    } catch (e) {
      debugPrint('Vendor orders background refresh error: $e');
    }
  }

  static Future<dynamic> deleteOrder(int orderId) {
    return ApiService.deleteOrder(orderId);
  }

  static void setOrders(List<VendorOrder> items) {
    orders.value = List<VendorOrder>.from(items);
    _loadedOnce = true;
  }

  static void remove(VendorOrder order) {
    orders.value = orders.value.where((item) => item.id != order.id).toList();
    _loadedOnce = true;
  }

  static void restore(VendorOrder order) {
    final nextOrders = List<VendorOrder>.from(orders.value);

    if (nextOrders.any((item) => item.id == order.id)) return;

    nextOrders.insert(0, order);
    orders.value = nextOrders;
    _loadedOnce = true;
  }

  static void clearOrders() {
    orders.value = [];
    _loadedOnce = true;
  }

  static void clear() {
    orders.value = [];
    _loadedOnce = false;
    _runningLoad = null;
  }

  static Future<void> _fetchOrders() async {
    final response = await ApiService.getMyOrders();
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Failed to load orders');
    }

    final raw = _orderListFrom(response);
    final parsed = <VendorOrder>[];

    for (final item in raw) {
      try {
        parsed.add(
          VendorOrder.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      } catch (_) {}
    }

    orders.value = parsed;
    _loadedOnce = true;
  }

  static List<dynamic> _orderListFrom(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) return data;
    if (data is Map && data['orders'] is List) {
      return data['orders'] as List;
    }

    final orders = response['orders'];
    if (orders is List) return orders;

    return const [];
  }
}
