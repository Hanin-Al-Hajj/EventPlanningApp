import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class FilteredVendorRepository {
  static final ValueNotifier<Map<int, List<Vendor>>> taskVendors =
      ValueNotifier<Map<int, List<Vendor>>>({});

  static final ValueNotifier<Map<int, Map<int, bool>>> orderStatuses =
      ValueNotifier<Map<int, Map<int, bool>>>({});

  static List<Vendor> getCachedVendors(int taskId) {
    return taskVendors.value[taskId] ?? [];
  }

  static Map<int, bool> getCachedOrderStatus(int taskId) {
    return orderStatuses.value[taskId] ?? {};
  }

  static bool hasCache(int taskId) {
    return taskVendors.value.containsKey(taskId);
  }

  static Future<void> loadTaskVendors(
    int taskId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && hasCache(taskId)) return;

    try {
      final response = await ApiService.getTaskVendors(taskId);
      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Failed to load vendors');
      }

      final data = response['data'];
      if (data == null) {
        throw Exception('No data received');
      }

      final vendorsList = data['vendors'] as List? ?? [];
      final parsed = <Vendor>[];
      for (final item in vendorsList) {
        try {
          parsed.add(Vendor.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {}
      }

      final current = Map<int, List<Vendor>>.from(taskVendors.value);
      current[taskId] = parsed;
      taskVendors.value = current;
    } catch (e) {
      debugPrint('FilteredVendorRepository loadTaskVendors error: $e');
      rethrow;
    }
  }

  static Future<void> loadOrderStatuses(int taskId) async {
    try {
      final result = await ApiService.getMyOrders();
      if (result['success'] == true) {
        final orders = result['data'] as List? ?? [];
        final Map<int, bool> statuses = {};

        for (var order in orders) {
          if (order['task_id'] == taskId) {
            final vendorId = order['vendor_id'];
            if (vendorId is int) {
              statuses[vendorId] = true;
            } else if (vendorId is String) {
              statuses[int.tryParse(vendorId) ?? 0] = true;
            }
          }
        }

        final currentStatuses = Map<int, Map<int, bool>>.from(
          orderStatuses.value,
        );
        currentStatuses[taskId] = statuses;
        orderStatuses.value = currentStatuses;
      }
    } catch (e) {
      debugPrint('FilteredVendorRepository loadOrderStatuses error: $e');
    }
  }
}
