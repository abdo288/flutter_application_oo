import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';

/// خدمة التخزين المؤقت المحسنة للأداء
class CacheService {
  static final Logger _logger = Logger('CacheService');

  // Cache containers
  static final Map<String, Product> _productCache = <String, Product>{};
  static final Map<String, InventoryItem> _inventoryCache =
      <String, InventoryItem>{};
  static final Map<String, DateTime> _productCacheTimestamps =
      <String, DateTime>{};
  static final Map<String, DateTime> _inventoryCacheTimestamps =
      <String, DateTime>{};

  // Cache configuration - تحسين الحدود لتقليل استهلاك الذاكرة
  static const Duration _cacheExpiration =
      Duration(minutes: 15); // تقليل مدة التخزين
  static const int _maxCacheSize = 200; // تقليل حجم الكاش

  // Cache statistics
  static int _cacheHits = 0;
  static int _cacheMisses = 0;

  // LRU Cache implementation
  static final LinkedHashMap<String, Product> _lruProducts = LinkedHashMap();
  static final LinkedHashMap<String, InventoryItem> _lruInventory =
      LinkedHashMap();

  /// إضافة منتج إلى الكاش
  static void cacheProduct(Product product) {
    if (product.id == null) return;

    try {
      final DateTime now = DateTime.now();

      // إدارة LRU للمنتجات
      if (_lruProducts.containsKey(product.id)) {
        _lruProducts.remove(product.id);
      }

      _lruProducts[product.id!] = product;
      _productCache[product.id!] = product;
      _productCacheTimestamps[product.id!] = now;

      // تنظيف الكاش عند الوصول للحد الأقصى
      _cleanupProductCache();

      _logger.fine('تم حفظ المنتج في الكاش: ${product.name}');
    } on Exception catch (e) {
      _logger.warning('خطأ في حفظ المنتج في الكاش: $e');
    }
  }

  /// إرجاع جميع المنتجات المحفوظة مؤقتاً
  static List<Product> getAllCachedProducts() {
    try {
      return List<Product>.unmodifiable(_lruProducts.values);
    } on Exception catch (e) {
      _logger.warning('خطأ في جلب جميع المنتجات من الكاش: $e');
      return <Product>[];
    }
  }

  /// إرجاع جميع عناصر المخزون المحفوظة مؤقتاً
  static List<InventoryItem> getAllCachedInventoryItems() {
    try {
      return List<InventoryItem>.unmodifiable(_lruInventory.values);
    } on Exception catch (e) {
      _logger.warning('خطأ في جلب جميع عناصر المخزون من الكاش: $e');
      return <InventoryItem>[];
    }
  }

  /// هل الكاش فارغ؟
  static bool isCacheEmpty() =>
      _productCache.isEmpty && _inventoryCache.isEmpty;

  /// حجم الكاش الإجمالي
  static int getCacheSize() => _productCache.length + _inventoryCache.length;

  /// إضافة عنصر مخزون إلى الكاش
  static void cacheInventoryItem(InventoryItem item) {
    if (item.id == null) return;

    try {
      final DateTime now = DateTime.now();

      // إدارة LRU لعناصر المخزون
      if (_lruInventory.containsKey(item.id)) {
        _lruInventory.remove(item.id);
      }

      _lruInventory[item.id!] = item;
      _inventoryCache[item.id!] = item;
      _inventoryCacheTimestamps[item.id!] = now;

      // تنظيف الكاش عند الوصول للحد الأقصى
      _cleanupInventoryCache();

      _logger.fine('تم حفظ عنصر المخزون في الكاش: ${item.name}');
    } on Exception catch (e) {
      _logger.warning('خطأ في حفظ عنصر المخزون في الكاش: $e');
    }
  }

  /// البحث عن منتج في الكاش
  static Product? getCachedProduct(String id) {
    try {
      if (_isProductCacheValid(id)) {
        // تحديث ترتيب LRU
        final Product? product = _lruProducts.remove(id);
        if (product != null) {
          _lruProducts[id] = product;
          _cacheHits++;
          _logger.fine('تم العثور على المنتج في الكاش: $id');
          return product;
        }
      }

      _cacheMisses++;
      return null;
    } on Exception catch (e) {
      _logger.warning('خطأ في البحث عن المنتج في الكاش: $e');
      return null;
    }
  }

  /// البحث عن عنصر مخزون في الكاش
  static InventoryItem? getCachedInventoryItem(String id) {
    try {
      if (_isInventoryCacheValid(id)) {
        // تحديث ترتيب LRU
        final InventoryItem? item = _lruInventory.remove(id);
        if (item != null) {
          _lruInventory[id] = item;
          _cacheHits++;
          _logger.fine('تم العثور على عنصر المخزون في الكاش: $id');
          return item;
        }
      }

      _cacheMisses++;
      return null;
    } on Exception catch (e) {
      _logger.warning('خطأ في البحث عن عنصر المخزون في الكاش: $e');
      return null;
    }
  }

  /// إزالة منتج من الكاش
  static void removeCachedProduct(String id) {
    try {
      _productCache.remove(id);
      _productCacheTimestamps.remove(id);
      _lruProducts.remove(id);
      _logger.fine('تم إزالة المنتج من الكاش: $id');
    } on Exception catch (e) {
      _logger.warning('خطأ في إزالة المنتج من الكاش: $e');
    }
  }

  /// إزالة عنصر مخزون من الكاش
  static void removeCachedInventoryItem(String id) {
    try {
      _inventoryCache.remove(id);
      _inventoryCacheTimestamps.remove(id);
      _lruInventory.remove(id);
      _logger.fine('تم إزالة عنصر المخزون من الكاش: $id');
    } on Exception catch (e) {
      _logger.warning('خطأ في إزالة عنصر المخزون من الكاش: $e');
    }
  }

  /// مسح جميع البيانات المحفوظة مؤقتاً
  static void clearAllCache() {
    try {
      _productCache.clear();
      _inventoryCache.clear();
      _productCacheTimestamps.clear();
      _inventoryCacheTimestamps.clear();
      _lruProducts.clear();
      _lruInventory.clear();

      _cacheHits = 0;
      _cacheMisses = 0;

      _logger.info('تم مسح جميع البيانات المحفوظة مؤقتاً');
    } on Exception catch (e) {
      _logger.warning('خطأ في مسح الكاش: $e');
    }
  }

  /// التحقق من صحة كاش المنتجات
  static bool _isProductCacheValid(String id) {
    if (!_productCache.containsKey(id)) return false;

    final DateTime? timestamp = _productCacheTimestamps[id];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  /// التحقق من صحة كاش المخزون
  static bool _isInventoryCacheValid(String id) {
    if (!_inventoryCache.containsKey(id)) return false;

    final DateTime? timestamp = _inventoryCacheTimestamps[id];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  /// تنظيف كاش المنتجات
  static void _cleanupProductCache() {
    while (_lruProducts.length > _maxCacheSize) {
      final String oldestKey = _lruProducts.keys.first;
      _lruProducts.remove(oldestKey);
      _productCache.remove(oldestKey);
      _productCacheTimestamps.remove(oldestKey);

      _logger.fine('تم إزالة منتج قديم من الكاش: $oldestKey');
    }
  }

  /// تنظيف كاش المخزون
  static void _cleanupInventoryCache() {
    while (_lruInventory.length > _maxCacheSize) {
      final String oldestKey = _lruInventory.keys.first;
      _lruInventory.remove(oldestKey);
      _inventoryCache.remove(oldestKey);
      _inventoryCacheTimestamps.remove(oldestKey);

      _logger.fine('تم إزالة عنصر مخزون قديم من الكاش: $oldestKey');
    }
  }

  /// إحصائيات الكاش
  static Map<String, dynamic> getCacheStats() {
    final int totalRequests = _cacheHits + _cacheMisses;
    final double hitRatio =
        totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;

    return <String, dynamic>{
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRatio': hitRatio.toStringAsFixed(2),
      'productCacheSize': _productCache.length,
      'inventoryCacheSize': _inventoryCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheExpiration': _cacheExpiration.inMinutes,
    };
  }

  /// إعادة تعيين إحصائيات الكاش
  static void resetCacheStats() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _logger.info('تم إعادة تعيين إحصائيات الكاش');
  }

  /// تنظيف دوري للكاش المنتهي الصلاحية
  static void performPeriodicCleanup() {
    try {
      final DateTime now = DateTime.now();
      final List<String> expiredProducts = <String>[];
      final List<String> expiredInventory = <String>[];

      // البحث عن المنتجات المنتهية الصلاحية
      _productCacheTimestamps.forEach((String id, DateTime timestamp) {
        if (now.difference(timestamp) >= _cacheExpiration) {
          expiredProducts.add(id);
        }
      });

      // البحث عن عناصر المخزون المنتهية الصلاحية
      _inventoryCacheTimestamps.forEach((String id, DateTime timestamp) {
        if (now.difference(timestamp) >= _cacheExpiration) {
          expiredInventory.add(id);
        }
      });

      // إزالة المنتجات المنتهية الصلاحية
      for (final String id in expiredProducts) {
        removeCachedProduct(id);
      }

      // إزالة عناصر المخزون المنتهية الصلاحية
      for (final String id in expiredInventory) {
        removeCachedInventoryItem(id);
      }

      if (expiredProducts.isNotEmpty || expiredInventory.isNotEmpty) {
        _logger.info(
            'تم تنظيف ${expiredProducts.length} منتج و ${expiredInventory.length} عنصر مخزون منتهي الصلاحية');
      }
    } on Exception catch (e) {
      _logger.warning('خطأ في التنظيف الدوري للكاش: $e');
    }
  }

  /// بدء التنظيف الدوري للكاش
  static Timer? _cleanupTimer;

  static void startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => performPeriodicCleanup(),
    );
    _logger.info('تم بدء التنظيف الدوري للكاش');
  }

  /// إيقاف التنظيف الدوري للكاش
  static void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _logger.info('تم إيقاف التنظيف الدوري للكاش');
  }
}
