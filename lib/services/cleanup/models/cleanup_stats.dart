/// إحصائيات التنظيف
class CleanupStats {
  CleanupStats({
    this.productsCount = 0,
    this.inventoryItemsCount = 0,
    this.salesCount = 0,
    this.syncOperationsCount = 0,
    this.productsDeleted = 0,
    this.inventoryItemsDeleted = 0,
    this.salesDeleted = 0,
    this.syncOperationsDeleted = 0,
    this.additionalInfo,
  });

  final int productsCount;
  final int inventoryItemsCount;
  final int salesCount;
  final int syncOperationsCount;
  final int productsDeleted;
  final int inventoryItemsDeleted;
  final int salesDeleted;
  final int syncOperationsDeleted;
  final String? additionalInfo;
}
