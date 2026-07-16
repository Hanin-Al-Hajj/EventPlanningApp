import 'package:event_planner/models/vendor.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class VendorCache {
  final List<Vendor> vendors;
  final DateTime loadedAt;

  VendorCache({required this.vendors, DateTime? loadedAt})
    : loadedAt = loadedAt ?? DateTime.now();

  VendorCache.empty()
    : vendors = const [],
      loadedAt = DateTime.fromMillisecondsSinceEpoch(0);

  VendorCache copyWith({List<Vendor>? vendors, DateTime? loadedAt}) {
    return VendorCache(
      vendors: vendors ?? this.vendors,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }
}

class VendorDetailsCache {
  final Vendor? vendor;
  final String? eventName;
  final List<Map<String, dynamic>> orders;
  final DateTime loadedAt;

  VendorDetailsCache({
    required this.vendor,
    this.eventName,
    List<Map<String, dynamic>>? orders,
    DateTime? loadedAt,
  }) : orders = orders ?? const [],
       loadedAt = loadedAt ?? DateTime.now();

  VendorDetailsCache.empty()
    : vendor = null,
      eventName = null,
      orders = const [],
      loadedAt = DateTime.fromMillisecondsSinceEpoch(0);
}

class VendorRepository {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static final Map<String, VendorCache> _cache = {};
  static final Map<String, Future<VendorCache>> _inFlight = {};
  static final Map<String, VendorDetailsCache> _detailCache = {};
  static final Map<String, Future<VendorDetailsCache>> _detailInFlight = {};

  static bool hasCache(String eventId) => _cache.containsKey(eventId);

  static VendorCache cachedFor(String eventId) {
    return _cache[eventId] ?? VendorCache.empty();
  }

  static Vendor? cachedVendor(String eventId, String vendorId) {
    final cache = _cache[eventId];
    if (cache == null) return null;

    for (final vendor in cache.vendors) {
      if (vendor.id.toString() == vendorId) return vendor;
    }
    return null;
  }

  static bool hasDetails(String? eventId, String vendorId) {
    return _detailCache.containsKey(_detailKey(eventId, vendorId));
  }

  static VendorDetailsCache cachedDetailsFor(String? eventId, String vendorId) {
    return _detailCache[_detailKey(eventId, vendorId)] ??
        VendorDetailsCache.empty();
  }

  static Future<VendorCache> load(String eventId, {bool forceRefresh = false}) {
    final cached = _cache[eventId];
    if (!forceRefresh && cached != null) {
      return Future.value(cached);
    }

    final running = _inFlight[eventId];
    if (running != null) return running;

    final request = _fetch(eventId).whenComplete(() {
      _inFlight.remove(eventId);
    });
    _inFlight[eventId] = request;
    return request;
  }

  static Future<VendorDetailsCache> loadDetails(
    String? eventId,
    String vendorId, {
    bool forceRefresh = false,
  }) {
    final key = _detailKey(eventId, vendorId);
    final cached = _detailCache[key];
    if (!forceRefresh && cached != null) {
      return Future.value(cached);
    }

    final running = _detailInFlight[key];
    if (running != null) return running;

    final request = _fetchDetails(eventId, vendorId).whenComplete(() {
      _detailInFlight.remove(key);
    });
    _detailInFlight[key] = request;
    return request;
  }

  static Future<void> refreshInBackground(String eventId) async {
    try {
      await load(eventId, forceRefresh: true);
    } catch (e) {
      debugPrint('Vendor background refresh failed: $e');
    }
  }

  static Future<void> refreshDetailsInBackground(
    String? eventId,
    String vendorId,
  ) async {
    try {
      await loadDetails(eventId, vendorId, forceRefresh: true);
    } catch (e) {
      debugPrint('Vendor details background refresh failed: $e');
    }
  }

  static void setFavorite(
    String eventId,
    String vendorId,
    bool isFavorite, {
    bool notify = true,
  }) {
    final cache = _cache[eventId];
    if (cache == null) return;

    var changed = false;
    for (final vendor in cache.vendors) {
      if (vendor.id.toString() == vendorId) {
        vendor.isFavorite = isFavorite;
        changed = true;
      }
    }

    for (final entry in _detailCache.entries) {
      if (!entry.key.startsWith('$eventId::')) continue;
      final detailVendor = entry.value.vendor;
      if (detailVendor != null && detailVendor.id.toString() == vendorId) {
        detailVendor.isFavorite = isFavorite;
        changed = true;
      }
    }

    if (changed && notify) _notify();
  }

  static Future<bool> toggleFavorite(
    String eventId,
    String vendorId, {
    required bool fallback,
  }) async {
    final result = await ApiService.toggleFavoriteVendor(eventId, vendorId);
    final serverValue = result['is_favorite'];
    final isFavorite = serverValue is bool ? serverValue : fallback;

    setFavorite(eventId, vendorId, isFavorite);
    return isFavorite;
  }

  static void clearEvent(String eventId) {
    _cache.remove(eventId);
    _inFlight.remove(eventId);
    _detailCache.removeWhere((key, _) => key.startsWith('$eventId::'));
    _detailInFlight.removeWhere((key, _) => key.startsWith('$eventId::'));
    _notify();
  }

  static void clearAll() {
    _cache.clear();
    _inFlight.clear();
    _detailCache.clear();
    _detailInFlight.clear();
    _notify();
  }

  static Future<VendorCache> _fetch(String eventId) async {
    final vendorsFuture = ApiService.getVendors(eventId);
    final favoritesFuture = ApiService.getFavoriteVendors(eventId).catchError((
      Object e,
    ) {
      debugPrint('Favorite vendors failed, continuing without them: $e');
      return <String, dynamic>{'vendors': <dynamic>[]};
    });

    final data = await vendorsFuture;
    final favoriteData = await favoritesFuture;

    final vendors = <Vendor>[];
    for (final item in _vendorsPayload(data)) {
      final itemJson = _asMap(item);
      if (itemJson == null) continue;
      vendors.add(Vendor.fromJson(itemJson));
    }

    final favoriteIds = <String>{};
    for (final item in _vendorsPayload(favoriteData)) {
      final id = _idFromFavoriteItem(item);
      if (id != null && id.isNotEmpty) favoriteIds.add(id);
    }

    for (final vendor in vendors) {
      vendor.isFavorite = favoriteIds.contains(vendor.id.toString());
    }

    final cache = VendorCache(vendors: vendors);
    _cache[eventId] = cache;
    _notify();
    return cache;
  }

  static Future<VendorDetailsCache> _fetchDetails(
    String? eventId,
    String vendorId,
  ) async {
    late final Map<String, dynamic> data;
    late final Map<String, dynamic>? vendorMap;
    String? eventName;
    final orders = <Map<String, dynamic>>[];

    if (eventId != null) {
      data = await ApiService.getVendor(eventId, vendorId);
      vendorMap = _asMap(data['vendor']);
      final event = _asMap(data['event']);
      eventName = (event?['name'] ?? data['event_name'])?.toString();
    } else {
      final assistantVendorId = int.tryParse(vendorId);
      if (assistantVendorId == null) {
        throw Exception('Invalid vendor id: $vendorId');
      }

      data = await ApiService.getAssistantVendor(assistantVendorId);
      vendorMap = _asMap(data['data'] ?? data['vendor']);
    }

    if (vendorMap == null) {
      throw Exception('Vendor not found');
    }

    final vendor = Vendor.fromJson(vendorMap);
    if (eventId != null) {
      final cached = cachedVendor(eventId, vendorId);
      if (cached != null) vendor.isFavorite = cached.isFavorite;
    }

    for (final item in _asList(vendorMap['orders'] ?? data['orders'])) {
      final itemJson = _asMap(item);
      if (itemJson != null) orders.add(itemJson);
    }

    final cache = VendorDetailsCache(
      vendor: vendor,
      eventName: eventName,
      orders: orders,
    );
    _detailCache[_detailKey(eventId, vendorId)] = cache;

    if (eventId != null) {
      _upsertVendor(eventId, vendor, notify: false);
    }

    _notify();
    return cache;
  }

  static void _upsertVendor(
    String eventId,
    Vendor vendor, {
    bool notify = true,
  }) {
    final cache = _cache[eventId];
    if (cache == null) return;

    final vendors = List<Vendor>.from(cache.vendors);
    final index = vendors.indexWhere((item) {
      return item.id.toString() == vendor.id.toString();
    });

    if (index == -1) {
      vendors.add(vendor);
    } else {
      vendors[index] = vendor;
    }

    _cache[eventId] = cache.copyWith(vendors: vendors);
    if (notify) _notify();
  }

  static List<dynamic> _vendorsPayload(Map<String, dynamic> data) {
    final direct = data['vendors'];
    if (direct is List) return direct;

    final payload = data['data'];
    if (payload is List) return payload;
    if (payload is Map && payload['vendors'] is List) {
      return payload['vendors'] as List;
    }

    return const [];
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static String? _idFromFavoriteItem(dynamic item) {
    if (item is Map) {
      return (item['id'] ?? item['vendor_id'] ?? item['vendorId'])?.toString();
    }
    return item?.toString();
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _detailKey(String? eventId, String vendorId) {
    return '${eventId ?? 'assistant'}::$vendorId';
  }

  static void _notify() {
    changes.value = changes.value + 1;
  }
}
