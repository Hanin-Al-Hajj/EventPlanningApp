import 'package:event_planner/models/order.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class OrderRepository {
  static final ValueNotifier<Map<int, Order>> orders =
      ValueNotifier<Map<int, Order>>({});

  // Key: taskId_vendorId -> Order
  static Order? getOrder(int taskId, int vendorId) {
    return orders.value[_makeKey(taskId, vendorId)];
  }

  static bool hasOrder(int taskId, int vendorId) {
    return orders.value.containsKey(_makeKey(taskId, vendorId));
  }

  static int _makeKey(int taskId, int vendorId) {
    return taskId * 1000000 + vendorId;
  }

  static Future<void> loadAllOrders() async {
    try {
      final result = await ApiService.getMyOrders();
      if (result['success'] == true) {
        final ordersList = result['data'] as List? ?? [];
        final Map<int, Order> parsed = {};

        for (var order in ordersList) {
          try {
            final o = Order.fromJson(Map<String, dynamic>.from(order as Map));
            parsed[_makeKey(o.taskId, o.vendorId)] = o;
          } catch (_) {}
        }

        orders.value = parsed;
      }
    } catch (e) {
      debugPrint('OrderRepository loadAllOrders error: $e');
    }
  }

  static Future<Map<String, dynamic>> submitOrder({
    required int taskId,
    required int vendorId,
    required double price,
    String? notes,
  }) async {
    try {
      final result = await ApiService.submitOrder(
        taskId: taskId,
        vendorId: vendorId,
        price: price,
        notes: notes,
      );

      if (result['success'] == true) {
        // Reload orders to get the updated list
        await loadAllOrders();
      }

      return result;
    } catch (e) {
      debugPrint('OrderRepository submitOrder error: $e');
      rethrow;
    }
  }

  static void clear() {
    orders.value = {};
  }
}
