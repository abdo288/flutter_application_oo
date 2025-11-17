/// حالة تبويب نموذج المنتج
class InventoryState {
  const InventoryState({
    this.isLoading = false,
    this.isDeleting = false,
    this.showAdvancedOptions = false,
    this.generatedBarcode,
    this.productName = '',
    this.wholesalePrice = '',
    this.retailPrice = '',
    this.quantity = '',
    this.expiryDate = '',
    this.errorMessage,
    this.sortBy = 'name',
    this.sortAscending = true,
    this.filterCriteria = '',
    this.filterDate,
    this.isFormValid = false,
  });

  final bool isLoading;
  final bool isDeleting;
  final bool showAdvancedOptions;
  final String? generatedBarcode;
  final String productName;
  final String wholesalePrice;
  final String retailPrice;
  final String quantity;
  final String expiryDate;
  final String? errorMessage;
  final String sortBy;
  final bool sortAscending;
  final String filterCriteria;
  final DateTime? filterDate;
  final bool isFormValid;

  InventoryState copyWith({
    bool? isLoading,
    bool? isDeleting,
    bool? showAdvancedOptions,
    String? generatedBarcode,
    String? productName,
    String? wholesalePrice,
    String? retailPrice,
    String? quantity,
    String? expiryDate,
    String? errorMessage,
    String? sortBy,
    bool? sortAscending,
    String? filterCriteria,
    DateTime? filterDate,
    bool? isFormValid,
  }) =>
      InventoryState(
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        showAdvancedOptions: showAdvancedOptions ?? this.showAdvancedOptions,
        generatedBarcode: generatedBarcode ?? this.generatedBarcode,
        productName: productName ?? this.productName,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        quantity: quantity ?? this.quantity,
        expiryDate: expiryDate ?? this.expiryDate,
        errorMessage: errorMessage ?? this.errorMessage,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
        filterCriteria: filterCriteria ?? this.filterCriteria,
        filterDate: filterDate ?? this.filterDate,
        isFormValid: isFormValid ?? this.isFormValid,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isDeleting == other.isDeleting &&
          showAdvancedOptions == other.showAdvancedOptions &&
          generatedBarcode == other.generatedBarcode &&
          productName == other.productName &&
          wholesalePrice == other.wholesalePrice &&
          retailPrice == other.retailPrice &&
          quantity == other.quantity &&
          expiryDate == other.expiryDate &&
          errorMessage == other.errorMessage &&
          sortBy == other.sortBy &&
          sortAscending == other.sortAscending &&
          filterCriteria == other.filterCriteria &&
          filterDate == other.filterDate &&
          isFormValid == other.isFormValid;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      isDeleting.hashCode ^
      showAdvancedOptions.hashCode ^
      generatedBarcode.hashCode ^
      productName.hashCode ^
      wholesalePrice.hashCode ^
      retailPrice.hashCode ^
      quantity.hashCode ^
      expiryDate.hashCode ^
      errorMessage.hashCode ^
      sortBy.hashCode ^
      sortAscending.hashCode ^
      filterCriteria.hashCode ^
      filterDate.hashCode ^
      isFormValid.hashCode;
}
