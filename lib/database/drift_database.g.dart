// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wholesalePriceMeta =
      const VerificationMeta('wholesalePrice');
  @override
  late final GeneratedColumn<int> wholesalePrice = GeneratedColumn<int>(
      'wholesale_price', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _retailPriceMeta =
      const VerificationMeta('retailPrice');
  @override
  late final GeneratedColumn<int> retailPrice = GeneratedColumn<int>(
      'retail_price', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<String> savedAt = GeneratedColumn<String>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supplierMeta =
      const VerificationMeta('supplier');
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
      'supplier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
      'images', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dimensionsMeta =
      const VerificationMeta('dimensions');
  @override
  late final GeneratedColumn<String> dimensions = GeneratedColumn<String>(
      'dimensions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _minimumStockMeta =
      const VerificationMeta('minimumStock');
  @override
  late final GeneratedColumn<int> minimumStock = GeneratedColumn<int>(
      'minimum_stock', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maximumStockMeta =
      const VerificationMeta('maximumStock');
  @override
  late final GeneratedColumn<int> maximumStock = GeneratedColumn<int>(
      'maximum_stock', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _discountRateMeta =
      const VerificationMeta('discountRate');
  @override
  late final GeneratedColumn<double> discountRate = GeneratedColumn<double>(
      'discount_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        wholesalePrice,
        retailPrice,
        savedAt,
        userId,
        isSynced,
        lastModified,
        description,
        barcode,
        category,
        supplier,
        status,
        images,
        tags,
        weight,
        dimensions,
        minimumStock,
        maximumStock,
        taxRate,
        discountRate,
        isActive,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(Insertable<ProductsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('wholesale_price')) {
      context.handle(
          _wholesalePriceMeta,
          wholesalePrice.isAcceptableOrUnknown(
              data['wholesale_price']!, _wholesalePriceMeta));
    }
    if (data.containsKey('retail_price')) {
      context.handle(
          _retailPriceMeta,
          retailPrice.isAcceptableOrUnknown(
              data['retail_price']!, _retailPriceMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('supplier')) {
      context.handle(_supplierMeta,
          supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('images')) {
      context.handle(_imagesMeta,
          images.isAcceptableOrUnknown(data['images']!, _imagesMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('dimensions')) {
      context.handle(
          _dimensionsMeta,
          dimensions.isAcceptableOrUnknown(
              data['dimensions']!, _dimensionsMeta));
    }
    if (data.containsKey('minimum_stock')) {
      context.handle(
          _minimumStockMeta,
          minimumStock.isAcceptableOrUnknown(
              data['minimum_stock']!, _minimumStockMeta));
    }
    if (data.containsKey('maximum_stock')) {
      context.handle(
          _maximumStockMeta,
          maximumStock.isAcceptableOrUnknown(
              data['maximum_stock']!, _maximumStockMeta));
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('discount_rate')) {
      context.handle(
          _discountRateMeta,
          discountRate.isAcceptableOrUnknown(
              data['discount_rate']!, _discountRateMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      wholesalePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wholesale_price'])!,
      retailPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retail_price'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}saved_at'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_modified'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      supplier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supplier']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      images: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}images']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      dimensions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dimensions']),
      minimumStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minimum_stock']),
      maximumStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}maximum_stock']),
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate']),
      discountRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount_rate']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String name;
  final int wholesalePrice;
  final int retailPrice;
  final String savedAt;
  final String? userId;
  final bool isSynced;
  final String lastModified;
  final String? description;
  final String? barcode;
  final String? category;
  final String? supplier;
  final String status;
  final String? images;
  final String? tags;
  final double? weight;
  final String? dimensions;
  final int? minimumStock;
  final int? maximumStock;
  final double? taxRate;
  final double? discountRate;
  final bool isActive;
  final String? notes;
  const ProductsTableData(
      {required this.id,
      required this.name,
      required this.wholesalePrice,
      required this.retailPrice,
      required this.savedAt,
      this.userId,
      required this.isSynced,
      required this.lastModified,
      this.description,
      this.barcode,
      this.category,
      this.supplier,
      required this.status,
      this.images,
      this.tags,
      this.weight,
      this.dimensions,
      this.minimumStock,
      this.maximumStock,
      this.taxRate,
      this.discountRate,
      required this.isActive,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['wholesale_price'] = Variable<int>(wholesalePrice);
    map['retail_price'] = Variable<int>(retailPrice);
    map['saved_at'] = Variable<String>(savedAt);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<String>(lastModified);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || images != null) {
      map['images'] = Variable<String>(images);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || dimensions != null) {
      map['dimensions'] = Variable<String>(dimensions);
    }
    if (!nullToAbsent || minimumStock != null) {
      map['minimum_stock'] = Variable<int>(minimumStock);
    }
    if (!nullToAbsent || maximumStock != null) {
      map['maximum_stock'] = Variable<int>(maximumStock);
    }
    if (!nullToAbsent || taxRate != null) {
      map['tax_rate'] = Variable<double>(taxRate);
    }
    if (!nullToAbsent || discountRate != null) {
      map['discount_rate'] = Variable<double>(discountRate);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      name: Value(name),
      wholesalePrice: Value(wholesalePrice),
      retailPrice: Value(retailPrice),
      savedAt: Value(savedAt),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      supplier: supplier == null && nullToAbsent
          ? const Value.absent()
          : Value(supplier),
      status: Value(status),
      images:
          images == null && nullToAbsent ? const Value.absent() : Value(images),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      dimensions: dimensions == null && nullToAbsent
          ? const Value.absent()
          : Value(dimensions),
      minimumStock: minimumStock == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumStock),
      maximumStock: maximumStock == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumStock),
      taxRate: taxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(taxRate),
      discountRate: discountRate == null && nullToAbsent
          ? const Value.absent()
          : Value(discountRate),
      isActive: Value(isActive),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory ProductsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      wholesalePrice: serializer.fromJson<int>(json['wholesalePrice']),
      retailPrice: serializer.fromJson<int>(json['retailPrice']),
      savedAt: serializer.fromJson<String>(json['savedAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<String>(json['lastModified']),
      description: serializer.fromJson<String?>(json['description']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      category: serializer.fromJson<String?>(json['category']),
      supplier: serializer.fromJson<String?>(json['supplier']),
      status: serializer.fromJson<String>(json['status']),
      images: serializer.fromJson<String?>(json['images']),
      tags: serializer.fromJson<String?>(json['tags']),
      weight: serializer.fromJson<double?>(json['weight']),
      dimensions: serializer.fromJson<String?>(json['dimensions']),
      minimumStock: serializer.fromJson<int?>(json['minimumStock']),
      maximumStock: serializer.fromJson<int?>(json['maximumStock']),
      taxRate: serializer.fromJson<double?>(json['taxRate']),
      discountRate: serializer.fromJson<double?>(json['discountRate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'wholesalePrice': serializer.toJson<int>(wholesalePrice),
      'retailPrice': serializer.toJson<int>(retailPrice),
      'savedAt': serializer.toJson<String>(savedAt),
      'userId': serializer.toJson<String?>(userId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<String>(lastModified),
      'description': serializer.toJson<String?>(description),
      'barcode': serializer.toJson<String?>(barcode),
      'category': serializer.toJson<String?>(category),
      'supplier': serializer.toJson<String?>(supplier),
      'status': serializer.toJson<String>(status),
      'images': serializer.toJson<String?>(images),
      'tags': serializer.toJson<String?>(tags),
      'weight': serializer.toJson<double?>(weight),
      'dimensions': serializer.toJson<String?>(dimensions),
      'minimumStock': serializer.toJson<int?>(minimumStock),
      'maximumStock': serializer.toJson<int?>(maximumStock),
      'taxRate': serializer.toJson<double?>(taxRate),
      'discountRate': serializer.toJson<double?>(discountRate),
      'isActive': serializer.toJson<bool>(isActive),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  ProductsTableData copyWith(
          {String? id,
          String? name,
          int? wholesalePrice,
          int? retailPrice,
          String? savedAt,
          Value<String?> userId = const Value.absent(),
          bool? isSynced,
          String? lastModified,
          Value<String?> description = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> supplier = const Value.absent(),
          String? status,
          Value<String?> images = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          Value<double?> weight = const Value.absent(),
          Value<String?> dimensions = const Value.absent(),
          Value<int?> minimumStock = const Value.absent(),
          Value<int?> maximumStock = const Value.absent(),
          Value<double?> taxRate = const Value.absent(),
          Value<double?> discountRate = const Value.absent(),
          bool? isActive,
          Value<String?> notes = const Value.absent()}) =>
      ProductsTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        savedAt: savedAt ?? this.savedAt,
        userId: userId.present ? userId.value : this.userId,
        isSynced: isSynced ?? this.isSynced,
        lastModified: lastModified ?? this.lastModified,
        description: description.present ? description.value : this.description,
        barcode: barcode.present ? barcode.value : this.barcode,
        category: category.present ? category.value : this.category,
        supplier: supplier.present ? supplier.value : this.supplier,
        status: status ?? this.status,
        images: images.present ? images.value : this.images,
        tags: tags.present ? tags.value : this.tags,
        weight: weight.present ? weight.value : this.weight,
        dimensions: dimensions.present ? dimensions.value : this.dimensions,
        minimumStock:
            minimumStock.present ? minimumStock.value : this.minimumStock,
        maximumStock:
            maximumStock.present ? maximumStock.value : this.maximumStock,
        taxRate: taxRate.present ? taxRate.value : this.taxRate,
        discountRate:
            discountRate.present ? discountRate.value : this.discountRate,
        isActive: isActive ?? this.isActive,
        notes: notes.present ? notes.value : this.notes,
      );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      wholesalePrice: data.wholesalePrice.present
          ? data.wholesalePrice.value
          : this.wholesalePrice,
      retailPrice:
          data.retailPrice.present ? data.retailPrice.value : this.retailPrice,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      description:
          data.description.present ? data.description.value : this.description,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      category: data.category.present ? data.category.value : this.category,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      status: data.status.present ? data.status.value : this.status,
      images: data.images.present ? data.images.value : this.images,
      tags: data.tags.present ? data.tags.value : this.tags,
      weight: data.weight.present ? data.weight.value : this.weight,
      dimensions:
          data.dimensions.present ? data.dimensions.value : this.dimensions,
      minimumStock: data.minimumStock.present
          ? data.minimumStock.value
          : this.minimumStock,
      maximumStock: data.maximumStock.present
          ? data.maximumStock.value
          : this.maximumStock,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      discountRate: data.discountRate.present
          ? data.discountRate.value
          : this.discountRate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('savedAt: $savedAt, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('description: $description, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('supplier: $supplier, ')
          ..write('status: $status, ')
          ..write('images: $images, ')
          ..write('tags: $tags, ')
          ..write('weight: $weight, ')
          ..write('dimensions: $dimensions, ')
          ..write('minimumStock: $minimumStock, ')
          ..write('maximumStock: $maximumStock, ')
          ..write('taxRate: $taxRate, ')
          ..write('discountRate: $discountRate, ')
          ..write('isActive: $isActive, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        wholesalePrice,
        retailPrice,
        savedAt,
        userId,
        isSynced,
        lastModified,
        description,
        barcode,
        category,
        supplier,
        status,
        images,
        tags,
        weight,
        dimensions,
        minimumStock,
        maximumStock,
        taxRate,
        discountRate,
        isActive,
        notes
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.wholesalePrice == this.wholesalePrice &&
          other.retailPrice == this.retailPrice &&
          other.savedAt == this.savedAt &&
          other.userId == this.userId &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified &&
          other.description == this.description &&
          other.barcode == this.barcode &&
          other.category == this.category &&
          other.supplier == this.supplier &&
          other.status == this.status &&
          other.images == this.images &&
          other.tags == this.tags &&
          other.weight == this.weight &&
          other.dimensions == this.dimensions &&
          other.minimumStock == this.minimumStock &&
          other.maximumStock == this.maximumStock &&
          other.taxRate == this.taxRate &&
          other.discountRate == this.discountRate &&
          other.isActive == this.isActive &&
          other.notes == this.notes);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> wholesalePrice;
  final Value<int> retailPrice;
  final Value<String> savedAt;
  final Value<String?> userId;
  final Value<bool> isSynced;
  final Value<String> lastModified;
  final Value<String?> description;
  final Value<String?> barcode;
  final Value<String?> category;
  final Value<String?> supplier;
  final Value<String> status;
  final Value<String?> images;
  final Value<String?> tags;
  final Value<double?> weight;
  final Value<String?> dimensions;
  final Value<int?> minimumStock;
  final Value<int?> maximumStock;
  final Value<double?> taxRate;
  final Value<double?> discountRate;
  final Value<bool> isActive;
  final Value<String?> notes;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.description = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.supplier = const Value.absent(),
    this.status = const Value.absent(),
    this.images = const Value.absent(),
    this.tags = const Value.absent(),
    this.weight = const Value.absent(),
    this.dimensions = const Value.absent(),
    this.minimumStock = const Value.absent(),
    this.maximumStock = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.discountRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String name,
    this.wholesalePrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    required String savedAt,
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String lastModified,
    this.description = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.supplier = const Value.absent(),
    this.status = const Value.absent(),
    this.images = const Value.absent(),
    this.tags = const Value.absent(),
    this.weight = const Value.absent(),
    this.dimensions = const Value.absent(),
    this.minimumStock = const Value.absent(),
    this.maximumStock = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.discountRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        savedAt = Value(savedAt),
        lastModified = Value(lastModified);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? wholesalePrice,
    Expression<int>? retailPrice,
    Expression<String>? savedAt,
    Expression<String>? userId,
    Expression<bool>? isSynced,
    Expression<String>? lastModified,
    Expression<String>? description,
    Expression<String>? barcode,
    Expression<String>? category,
    Expression<String>? supplier,
    Expression<String>? status,
    Expression<String>? images,
    Expression<String>? tags,
    Expression<double>? weight,
    Expression<String>? dimensions,
    Expression<int>? minimumStock,
    Expression<int>? maximumStock,
    Expression<double>? taxRate,
    Expression<double>? discountRate,
    Expression<bool>? isActive,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (savedAt != null) 'saved_at': savedAt,
      if (userId != null) 'user_id': userId,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (description != null) 'description': description,
      if (barcode != null) 'barcode': barcode,
      if (category != null) 'category': category,
      if (supplier != null) 'supplier': supplier,
      if (status != null) 'status': status,
      if (images != null) 'images': images,
      if (tags != null) 'tags': tags,
      if (weight != null) 'weight': weight,
      if (dimensions != null) 'dimensions': dimensions,
      if (minimumStock != null) 'minimum_stock': minimumStock,
      if (maximumStock != null) 'maximum_stock': maximumStock,
      if (taxRate != null) 'tax_rate': taxRate,
      if (discountRate != null) 'discount_rate': discountRate,
      if (isActive != null) 'is_active': isActive,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? wholesalePrice,
      Value<int>? retailPrice,
      Value<String>? savedAt,
      Value<String?>? userId,
      Value<bool>? isSynced,
      Value<String>? lastModified,
      Value<String?>? description,
      Value<String?>? barcode,
      Value<String?>? category,
      Value<String?>? supplier,
      Value<String>? status,
      Value<String?>? images,
      Value<String?>? tags,
      Value<double?>? weight,
      Value<String?>? dimensions,
      Value<int?>? minimumStock,
      Value<int?>? maximumStock,
      Value<double?>? taxRate,
      Value<double?>? discountRate,
      Value<bool>? isActive,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      savedAt: savedAt ?? this.savedAt,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      taxRate: taxRate ?? this.taxRate,
      discountRate: discountRate ?? this.discountRate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (wholesalePrice.present) {
      map['wholesale_price'] = Variable<int>(wholesalePrice.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<int>(retailPrice.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<String>(savedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (dimensions.present) {
      map['dimensions'] = Variable<String>(dimensions.value);
    }
    if (minimumStock.present) {
      map['minimum_stock'] = Variable<int>(minimumStock.value);
    }
    if (maximumStock.present) {
      map['maximum_stock'] = Variable<int>(maximumStock.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (discountRate.present) {
      map['discount_rate'] = Variable<double>(discountRate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('savedAt: $savedAt, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('description: $description, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('supplier: $supplier, ')
          ..write('status: $status, ')
          ..write('images: $images, ')
          ..write('tags: $tags, ')
          ..write('weight: $weight, ')
          ..write('dimensions: $dimensions, ')
          ..write('minimumStock: $minimumStock, ')
          ..write('maximumStock: $maximumStock, ')
          ..write('taxRate: $taxRate, ')
          ..write('discountRate: $discountRate, ')
          ..write('isActive: $isActive, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryTableTable extends InventoryTable
    with TableInfo<$InventoryTableTable, InventoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _wholesalePriceMeta =
      const VerificationMeta('wholesalePrice');
  @override
  late final GeneratedColumn<int> wholesalePrice = GeneratedColumn<int>(
      'wholesale_price', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _retailPriceMeta =
      const VerificationMeta('retailPrice');
  @override
  late final GeneratedColumn<int> retailPrice = GeneratedColumn<int>(
      'retail_price', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _originalQuantityMeta =
      const VerificationMeta('originalQuantity');
  @override
  late final GeneratedColumn<int> originalQuantity = GeneratedColumn<int>(
      'original_quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _addedDateMeta =
      const VerificationMeta('addedDate');
  @override
  late final GeneratedColumn<String> addedDate = GeneratedColumn<String>(
      'added_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedTimeMeta =
      const VerificationMeta('addedTime');
  @override
  late final GeneratedColumn<String> addedTime = GeneratedColumn<String>(
      'added_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        barcode,
        wholesalePrice,
        retailPrice,
        quantity,
        originalQuantity,
        addedDate,
        addedTime,
        userId,
        isSynced,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_table';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('wholesale_price')) {
      context.handle(
          _wholesalePriceMeta,
          wholesalePrice.isAcceptableOrUnknown(
              data['wholesale_price']!, _wholesalePriceMeta));
    }
    if (data.containsKey('retail_price')) {
      context.handle(
          _retailPriceMeta,
          retailPrice.isAcceptableOrUnknown(
              data['retail_price']!, _retailPriceMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('original_quantity')) {
      context.handle(
          _originalQuantityMeta,
          originalQuantity.isAcceptableOrUnknown(
              data['original_quantity']!, _originalQuantityMeta));
    }
    if (data.containsKey('added_date')) {
      context.handle(_addedDateMeta,
          addedDate.isAcceptableOrUnknown(data['added_date']!, _addedDateMeta));
    } else if (isInserting) {
      context.missing(_addedDateMeta);
    }
    if (data.containsKey('added_time')) {
      context.handle(_addedTimeMeta,
          addedTime.isAcceptableOrUnknown(data['added_time']!, _addedTimeMeta));
    } else if (isInserting) {
      context.missing(_addedTimeMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      wholesalePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wholesale_price'])!,
      retailPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retail_price'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      originalQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_quantity'])!,
      addedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}added_date'])!,
      addedTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}added_time'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $InventoryTableTable createAlias(String alias) {
    return $InventoryTableTable(attachedDatabase, alias);
  }
}

class InventoryTableData extends DataClass
    implements Insertable<InventoryTableData> {
  final String id;
  final String name;
  final String? barcode;
  final int wholesalePrice;
  final int retailPrice;
  final int quantity;
  final int originalQuantity;
  final String addedDate;
  final String addedTime;
  final String? userId;
  final bool isSynced;
  final String lastModified;
  const InventoryTableData(
      {required this.id,
      required this.name,
      this.barcode,
      required this.wholesalePrice,
      required this.retailPrice,
      required this.quantity,
      required this.originalQuantity,
      required this.addedDate,
      required this.addedTime,
      this.userId,
      required this.isSynced,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['wholesale_price'] = Variable<int>(wholesalePrice);
    map['retail_price'] = Variable<int>(retailPrice);
    map['quantity'] = Variable<int>(quantity);
    map['original_quantity'] = Variable<int>(originalQuantity);
    map['added_date'] = Variable<String>(addedDate);
    map['added_time'] = Variable<String>(addedTime);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<String>(lastModified);
    return map;
  }

  InventoryTableCompanion toCompanion(bool nullToAbsent) {
    return InventoryTableCompanion(
      id: Value(id),
      name: Value(name),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      wholesalePrice: Value(wholesalePrice),
      retailPrice: Value(retailPrice),
      quantity: Value(quantity),
      originalQuantity: Value(originalQuantity),
      addedDate: Value(addedDate),
      addedTime: Value(addedTime),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory InventoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      wholesalePrice: serializer.fromJson<int>(json['wholesalePrice']),
      retailPrice: serializer.fromJson<int>(json['retailPrice']),
      quantity: serializer.fromJson<int>(json['quantity']),
      originalQuantity: serializer.fromJson<int>(json['originalQuantity']),
      addedDate: serializer.fromJson<String>(json['addedDate']),
      addedTime: serializer.fromJson<String>(json['addedTime']),
      userId: serializer.fromJson<String?>(json['userId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<String>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'barcode': serializer.toJson<String?>(barcode),
      'wholesalePrice': serializer.toJson<int>(wholesalePrice),
      'retailPrice': serializer.toJson<int>(retailPrice),
      'quantity': serializer.toJson<int>(quantity),
      'originalQuantity': serializer.toJson<int>(originalQuantity),
      'addedDate': serializer.toJson<String>(addedDate),
      'addedTime': serializer.toJson<String>(addedTime),
      'userId': serializer.toJson<String?>(userId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<String>(lastModified),
    };
  }

  InventoryTableData copyWith(
          {String? id,
          String? name,
          Value<String?> barcode = const Value.absent(),
          int? wholesalePrice,
          int? retailPrice,
          int? quantity,
          int? originalQuantity,
          String? addedDate,
          String? addedTime,
          Value<String?> userId = const Value.absent(),
          bool? isSynced,
          String? lastModified}) =>
      InventoryTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        barcode: barcode.present ? barcode.value : this.barcode,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        quantity: quantity ?? this.quantity,
        originalQuantity: originalQuantity ?? this.originalQuantity,
        addedDate: addedDate ?? this.addedDate,
        addedTime: addedTime ?? this.addedTime,
        userId: userId.present ? userId.value : this.userId,
        isSynced: isSynced ?? this.isSynced,
        lastModified: lastModified ?? this.lastModified,
      );
  InventoryTableData copyWithCompanion(InventoryTableCompanion data) {
    return InventoryTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      wholesalePrice: data.wholesalePrice.present
          ? data.wholesalePrice.value
          : this.wholesalePrice,
      retailPrice:
          data.retailPrice.present ? data.retailPrice.value : this.retailPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      originalQuantity: data.originalQuantity.present
          ? data.originalQuantity.value
          : this.originalQuantity,
      addedDate: data.addedDate.present ? data.addedDate.value : this.addedDate,
      addedTime: data.addedTime.present ? data.addedTime.value : this.addedTime,
      userId: data.userId.present ? data.userId.value : this.userId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('quantity: $quantity, ')
          ..write('originalQuantity: $originalQuantity, ')
          ..write('addedDate: $addedDate, ')
          ..write('addedTime: $addedTime, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      barcode,
      wholesalePrice,
      retailPrice,
      quantity,
      originalQuantity,
      addedDate,
      addedTime,
      userId,
      isSynced,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.wholesalePrice == this.wholesalePrice &&
          other.retailPrice == this.retailPrice &&
          other.quantity == this.quantity &&
          other.originalQuantity == this.originalQuantity &&
          other.addedDate == this.addedDate &&
          other.addedTime == this.addedTime &&
          other.userId == this.userId &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class InventoryTableCompanion extends UpdateCompanion<InventoryTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> barcode;
  final Value<int> wholesalePrice;
  final Value<int> retailPrice;
  final Value<int> quantity;
  final Value<int> originalQuantity;
  final Value<String> addedDate;
  final Value<String> addedTime;
  final Value<String?> userId;
  final Value<bool> isSynced;
  final Value<String> lastModified;
  final Value<int> rowid;
  const InventoryTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.originalQuantity = const Value.absent(),
    this.addedDate = const Value.absent(),
    this.addedTime = const Value.absent(),
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryTableCompanion.insert({
    required String id,
    required String name,
    this.barcode = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.originalQuantity = const Value.absent(),
    required String addedDate,
    required String addedTime,
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String lastModified,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        addedDate = Value(addedDate),
        addedTime = Value(addedTime),
        lastModified = Value(lastModified);
  static Insertable<InventoryTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? barcode,
    Expression<int>? wholesalePrice,
    Expression<int>? retailPrice,
    Expression<int>? quantity,
    Expression<int>? originalQuantity,
    Expression<String>? addedDate,
    Expression<String>? addedTime,
    Expression<String>? userId,
    Expression<bool>? isSynced,
    Expression<String>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (quantity != null) 'quantity': quantity,
      if (originalQuantity != null) 'original_quantity': originalQuantity,
      if (addedDate != null) 'added_date': addedDate,
      if (addedTime != null) 'added_time': addedTime,
      if (userId != null) 'user_id': userId,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? barcode,
      Value<int>? wholesalePrice,
      Value<int>? retailPrice,
      Value<int>? quantity,
      Value<int>? originalQuantity,
      Value<String>? addedDate,
      Value<String>? addedTime,
      Value<String?>? userId,
      Value<bool>? isSynced,
      Value<String>? lastModified,
      Value<int>? rowid}) {
    return InventoryTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      quantity: quantity ?? this.quantity,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      addedDate: addedDate ?? this.addedDate,
      addedTime: addedTime ?? this.addedTime,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (wholesalePrice.present) {
      map['wholesale_price'] = Variable<int>(wholesalePrice.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<int>(retailPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (originalQuantity.present) {
      map['original_quantity'] = Variable<int>(originalQuantity.value);
    }
    if (addedDate.present) {
      map['added_date'] = Variable<String>(addedDate.value);
    }
    if (addedTime.present) {
      map['added_time'] = Variable<String>(addedTime.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('quantity: $quantity, ')
          ..write('originalQuantity: $originalQuantity, ')
          ..write('addedDate: $addedDate, ')
          ..write('addedTime: $addedTime, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationsTableTable extends SyncOperationsTable
    with TableInfo<$SyncOperationsTableTable, SyncOperationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTableMeta =
      const VerificationMeta('targetTable');
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
      'target_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isProcessedMeta =
      const VerificationMeta('isProcessed');
  @override
  late final GeneratedColumn<bool> isProcessed = GeneratedColumn<bool>(
      'is_processed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_processed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operation,
        targetTable,
        recordId,
        data,
        timestamp,
        createdAt,
        isProcessed,
        retryCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operations_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<SyncOperationsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
          _targetTableMeta,
          targetTable.isAcceptableOrUnknown(
              data['target_table']!, _targetTableMeta));
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_processed')) {
      context.handle(
          _isProcessedMeta,
          isProcessed.isAcceptableOrUnknown(
              data['is_processed']!, _isProcessedMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperationsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperationsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      targetTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timestamp'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      isProcessed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_processed'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
    );
  }

  @override
  $SyncOperationsTableTable createAlias(String alias) {
    return $SyncOperationsTableTable(attachedDatabase, alias);
  }
}

class SyncOperationsTableData extends DataClass
    implements Insertable<SyncOperationsTableData> {
  final int id;
  final String operation;
  final String targetTable;
  final String recordId;
  final String data;
  final String timestamp;
  final String createdAt;
  final bool isProcessed;
  final int retryCount;
  const SyncOperationsTableData(
      {required this.id,
      required this.operation,
      required this.targetTable,
      required this.recordId,
      required this.data,
      required this.timestamp,
      required this.createdAt,
      required this.isProcessed,
      required this.retryCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation'] = Variable<String>(operation);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['data'] = Variable<String>(data);
    map['timestamp'] = Variable<String>(timestamp);
    map['created_at'] = Variable<String>(createdAt);
    map['is_processed'] = Variable<bool>(isProcessed);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncOperationsTableCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationsTableCompanion(
      id: Value(id),
      operation: Value(operation),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      data: Value(data),
      timestamp: Value(timestamp),
      createdAt: Value(createdAt),
      isProcessed: Value(isProcessed),
      retryCount: Value(retryCount),
    );
  }

  factory SyncOperationsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperationsTableData(
      id: serializer.fromJson<int>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      data: serializer.fromJson<String>(json['data']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      isProcessed: serializer.fromJson<bool>(json['isProcessed']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operation': serializer.toJson<String>(operation),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'data': serializer.toJson<String>(data),
      'timestamp': serializer.toJson<String>(timestamp),
      'createdAt': serializer.toJson<String>(createdAt),
      'isProcessed': serializer.toJson<bool>(isProcessed),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncOperationsTableData copyWith(
          {int? id,
          String? operation,
          String? targetTable,
          String? recordId,
          String? data,
          String? timestamp,
          String? createdAt,
          bool? isProcessed,
          int? retryCount}) =>
      SyncOperationsTableData(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        targetTable: targetTable ?? this.targetTable,
        recordId: recordId ?? this.recordId,
        data: data ?? this.data,
        timestamp: timestamp ?? this.timestamp,
        createdAt: createdAt ?? this.createdAt,
        isProcessed: isProcessed ?? this.isProcessed,
        retryCount: retryCount ?? this.retryCount,
      );
  SyncOperationsTableData copyWithCompanion(SyncOperationsTableCompanion data) {
    return SyncOperationsTableData(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      data: data.data.present ? data.data.value : this.data,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isProcessed:
          data.isProcessed.present ? data.isProcessed.value : this.isProcessed,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsTableData(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp, ')
          ..write('createdAt: $createdAt, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operation, targetTable, recordId, data,
      timestamp, createdAt, isProcessed, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperationsTableData &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.data == this.data &&
          other.timestamp == this.timestamp &&
          other.createdAt == this.createdAt &&
          other.isProcessed == this.isProcessed &&
          other.retryCount == this.retryCount);
}

class SyncOperationsTableCompanion
    extends UpdateCompanion<SyncOperationsTableData> {
  final Value<int> id;
  final Value<String> operation;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> data;
  final Value<String> timestamp;
  final Value<String> createdAt;
  final Value<bool> isProcessed;
  final Value<int> retryCount;
  const SyncOperationsTableCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.data = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isProcessed = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncOperationsTableCompanion.insert({
    this.id = const Value.absent(),
    required String operation,
    required String targetTable,
    required String recordId,
    required String data,
    required String timestamp,
    required String createdAt,
    this.isProcessed = const Value.absent(),
    this.retryCount = const Value.absent(),
  })  : operation = Value(operation),
        targetTable = Value(targetTable),
        recordId = Value(recordId),
        data = Value(data),
        timestamp = Value(timestamp),
        createdAt = Value(createdAt);
  static Insertable<SyncOperationsTableData> custom({
    Expression<int>? id,
    Expression<String>? operation,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? data,
    Expression<String>? timestamp,
    Expression<String>? createdAt,
    Expression<bool>? isProcessed,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (data != null) 'data': data,
      if (timestamp != null) 'timestamp': timestamp,
      if (createdAt != null) 'created_at': createdAt,
      if (isProcessed != null) 'is_processed': isProcessed,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncOperationsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? operation,
      Value<String>? targetTable,
      Value<String>? recordId,
      Value<String>? data,
      Value<String>? timestamp,
      Value<String>? createdAt,
      Value<bool>? isProcessed,
      Value<int>? retryCount}) {
    return SyncOperationsTableCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isProcessed: isProcessed ?? this.isProcessed,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (isProcessed.present) {
      map['is_processed'] = Variable<bool>(isProcessed.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsTableCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp, ')
          ..write('createdAt: $createdAt, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $SalesTableTable extends SalesTable
    with TableInfo<$SalesTableTable, SalesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
      'items', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<int> totalAmount = GeneratedColumn<int>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalProfitMeta =
      const VerificationMeta('totalProfit');
  @override
  late final GeneratedColumn<int> totalProfit = GeneratedColumn<int>(
      'total_profit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _saleDateMeta =
      const VerificationMeta('saleDate');
  @override
  late final GeneratedColumn<String> saleDate = GeneratedColumn<String>(
      'sale_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('نقدي'));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<int> discount = GeneratedColumn<int>(
      'discount', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        items,
        totalAmount,
        totalProfit,
        saleDate,
        customerName,
        notes,
        paymentMethod,
        discount,
        userId,
        isSynced,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_table';
  @override
  VerificationContext validateIntegrity(Insertable<SalesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('items')) {
      context.handle(
          _itemsMeta, items.isAcceptableOrUnknown(data['items']!, _itemsMeta));
    } else if (isInserting) {
      context.missing(_itemsMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    }
    if (data.containsKey('total_profit')) {
      context.handle(
          _totalProfitMeta,
          totalProfit.isAcceptableOrUnknown(
              data['total_profit']!, _totalProfitMeta));
    }
    if (data.containsKey('sale_date')) {
      context.handle(_saleDateMeta,
          saleDate.isAcceptableOrUnknown(data['sale_date']!, _saleDateMeta));
    } else if (isInserting) {
      context.missing(_saleDateMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      items: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_amount'])!,
      totalProfit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_profit'])!,
      saleDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_date'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}discount'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $SalesTableTable createAlias(String alias) {
    return $SalesTableTable(attachedDatabase, alias);
  }
}

class SalesTableData extends DataClass implements Insertable<SalesTableData> {
  final String id;
  final String items;
  final int totalAmount;
  final int totalProfit;
  final String saleDate;
  final String? customerName;
  final String? notes;
  final String paymentMethod;
  final int discount;
  final String? userId;
  final bool isSynced;
  final String lastModified;
  const SalesTableData(
      {required this.id,
      required this.items,
      required this.totalAmount,
      required this.totalProfit,
      required this.saleDate,
      this.customerName,
      this.notes,
      required this.paymentMethod,
      required this.discount,
      this.userId,
      required this.isSynced,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['items'] = Variable<String>(items);
    map['total_amount'] = Variable<int>(totalAmount);
    map['total_profit'] = Variable<int>(totalProfit);
    map['sale_date'] = Variable<String>(saleDate);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    map['discount'] = Variable<int>(discount);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['last_modified'] = Variable<String>(lastModified);
    return map;
  }

  SalesTableCompanion toCompanion(bool nullToAbsent) {
    return SalesTableCompanion(
      id: Value(id),
      items: Value(items),
      totalAmount: Value(totalAmount),
      totalProfit: Value(totalProfit),
      saleDate: Value(saleDate),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      paymentMethod: Value(paymentMethod),
      discount: Value(discount),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      isSynced: Value(isSynced),
      lastModified: Value(lastModified),
    );
  }

  factory SalesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesTableData(
      id: serializer.fromJson<String>(json['id']),
      items: serializer.fromJson<String>(json['items']),
      totalAmount: serializer.fromJson<int>(json['totalAmount']),
      totalProfit: serializer.fromJson<int>(json['totalProfit']),
      saleDate: serializer.fromJson<String>(json['saleDate']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      notes: serializer.fromJson<String?>(json['notes']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      discount: serializer.fromJson<int>(json['discount']),
      userId: serializer.fromJson<String?>(json['userId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastModified: serializer.fromJson<String>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'items': serializer.toJson<String>(items),
      'totalAmount': serializer.toJson<int>(totalAmount),
      'totalProfit': serializer.toJson<int>(totalProfit),
      'saleDate': serializer.toJson<String>(saleDate),
      'customerName': serializer.toJson<String?>(customerName),
      'notes': serializer.toJson<String?>(notes),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'discount': serializer.toJson<int>(discount),
      'userId': serializer.toJson<String?>(userId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastModified': serializer.toJson<String>(lastModified),
    };
  }

  SalesTableData copyWith(
          {String? id,
          String? items,
          int? totalAmount,
          int? totalProfit,
          String? saleDate,
          Value<String?> customerName = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? paymentMethod,
          int? discount,
          Value<String?> userId = const Value.absent(),
          bool? isSynced,
          String? lastModified}) =>
      SalesTableData(
        id: id ?? this.id,
        items: items ?? this.items,
        totalAmount: totalAmount ?? this.totalAmount,
        totalProfit: totalProfit ?? this.totalProfit,
        saleDate: saleDate ?? this.saleDate,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        notes: notes.present ? notes.value : this.notes,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        discount: discount ?? this.discount,
        userId: userId.present ? userId.value : this.userId,
        isSynced: isSynced ?? this.isSynced,
        lastModified: lastModified ?? this.lastModified,
      );
  SalesTableData copyWithCompanion(SalesTableCompanion data) {
    return SalesTableData(
      id: data.id.present ? data.id.value : this.id,
      items: data.items.present ? data.items.value : this.items,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      totalProfit:
          data.totalProfit.present ? data.totalProfit.value : this.totalProfit,
      saleDate: data.saleDate.present ? data.saleDate.value : this.saleDate,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      notes: data.notes.present ? data.notes.value : this.notes,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      discount: data.discount.present ? data.discount.value : this.discount,
      userId: data.userId.present ? data.userId.value : this.userId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesTableData(')
          ..write('id: $id, ')
          ..write('items: $items, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('totalProfit: $totalProfit, ')
          ..write('saleDate: $saleDate, ')
          ..write('customerName: $customerName, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('discount: $discount, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      items,
      totalAmount,
      totalProfit,
      saleDate,
      customerName,
      notes,
      paymentMethod,
      discount,
      userId,
      isSynced,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesTableData &&
          other.id == this.id &&
          other.items == this.items &&
          other.totalAmount == this.totalAmount &&
          other.totalProfit == this.totalProfit &&
          other.saleDate == this.saleDate &&
          other.customerName == this.customerName &&
          other.notes == this.notes &&
          other.paymentMethod == this.paymentMethod &&
          other.discount == this.discount &&
          other.userId == this.userId &&
          other.isSynced == this.isSynced &&
          other.lastModified == this.lastModified);
}

class SalesTableCompanion extends UpdateCompanion<SalesTableData> {
  final Value<String> id;
  final Value<String> items;
  final Value<int> totalAmount;
  final Value<int> totalProfit;
  final Value<String> saleDate;
  final Value<String?> customerName;
  final Value<String?> notes;
  final Value<String> paymentMethod;
  final Value<int> discount;
  final Value<String?> userId;
  final Value<bool> isSynced;
  final Value<String> lastModified;
  final Value<int> rowid;
  const SalesTableCompanion({
    this.id = const Value.absent(),
    this.items = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.totalProfit = const Value.absent(),
    this.saleDate = const Value.absent(),
    this.customerName = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.discount = const Value.absent(),
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesTableCompanion.insert({
    required String id,
    required String items,
    this.totalAmount = const Value.absent(),
    this.totalProfit = const Value.absent(),
    required String saleDate,
    this.customerName = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.discount = const Value.absent(),
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String lastModified,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        items = Value(items),
        saleDate = Value(saleDate),
        lastModified = Value(lastModified);
  static Insertable<SalesTableData> custom({
    Expression<String>? id,
    Expression<String>? items,
    Expression<int>? totalAmount,
    Expression<int>? totalProfit,
    Expression<String>? saleDate,
    Expression<String>? customerName,
    Expression<String>? notes,
    Expression<String>? paymentMethod,
    Expression<int>? discount,
    Expression<String>? userId,
    Expression<bool>? isSynced,
    Expression<String>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (items != null) 'items': items,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (totalProfit != null) 'total_profit': totalProfit,
      if (saleDate != null) 'sale_date': saleDate,
      if (customerName != null) 'customer_name': customerName,
      if (notes != null) 'notes': notes,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (discount != null) 'discount': discount,
      if (userId != null) 'user_id': userId,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? items,
      Value<int>? totalAmount,
      Value<int>? totalProfit,
      Value<String>? saleDate,
      Value<String?>? customerName,
      Value<String?>? notes,
      Value<String>? paymentMethod,
      Value<int>? discount,
      Value<String?>? userId,
      Value<bool>? isSynced,
      Value<String>? lastModified,
      Value<int>? rowid}) {
    return SalesTableCompanion(
      id: id ?? this.id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      totalProfit: totalProfit ?? this.totalProfit,
      saleDate: saleDate ?? this.saleDate,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<int>(totalAmount.value);
    }
    if (totalProfit.present) {
      map['total_profit'] = Variable<int>(totalProfit.value);
    }
    if (saleDate.present) {
      map['sale_date'] = Variable<String>(saleDate.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (discount.present) {
      map['discount'] = Variable<int>(discount.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesTableCompanion(')
          ..write('id: $id, ')
          ..write('items: $items, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('totalProfit: $totalProfit, ')
          ..write('saleDate: $saleDate, ')
          ..write('customerName: $customerName, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('discount: $discount, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  _$AppDatabase.connect(DatabaseConnection c) : super.connect(c);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $InventoryTableTable inventoryTable = $InventoryTableTable(this);
  late final $SyncOperationsTableTable syncOperationsTable =
      $SyncOperationsTableTable(this);
  late final $SalesTableTable salesTable = $SalesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [productsTable, inventoryTable, syncOperationsTable, salesTable];
}

typedef $$ProductsTableTableCreateCompanionBuilder = ProductsTableCompanion
    Function({
  required String id,
  required String name,
  Value<int> wholesalePrice,
  Value<int> retailPrice,
  required String savedAt,
  Value<String?> userId,
  Value<bool> isSynced,
  required String lastModified,
  Value<String?> description,
  Value<String?> barcode,
  Value<String?> category,
  Value<String?> supplier,
  Value<String> status,
  Value<String?> images,
  Value<String?> tags,
  Value<double?> weight,
  Value<String?> dimensions,
  Value<int?> minimumStock,
  Value<int?> maximumStock,
  Value<double?> taxRate,
  Value<double?> discountRate,
  Value<bool> isActive,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$ProductsTableTableUpdateCompanionBuilder = ProductsTableCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<int> wholesalePrice,
  Value<int> retailPrice,
  Value<String> savedAt,
  Value<String?> userId,
  Value<bool> isSynced,
  Value<String> lastModified,
  Value<String?> description,
  Value<String?> barcode,
  Value<String?> category,
  Value<String?> supplier,
  Value<String> status,
  Value<String?> images,
  Value<String?> tags,
  Value<double?> weight,
  Value<String?> dimensions,
  Value<int?> minimumStock,
  Value<int?> maximumStock,
  Value<double?> taxRate,
  Value<double?> discountRate,
  Value<bool> isActive,
  Value<String?> notes,
  Value<int> rowid,
});

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supplier => $composableBuilder(
      column: $table.supplier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get images => $composableBuilder(
      column: $table.images, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dimensions => $composableBuilder(
      column: $table.dimensions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minimumStock => $composableBuilder(
      column: $table.minimumStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maximumStock => $composableBuilder(
      column: $table.maximumStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountRate => $composableBuilder(
      column: $table.discountRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supplier => $composableBuilder(
      column: $table.supplier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get images => $composableBuilder(
      column: $table.images, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dimensions => $composableBuilder(
      column: $table.dimensions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minimumStock => $composableBuilder(
      column: $table.minimumStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maximumStock => $composableBuilder(
      column: $table.maximumStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountRate => $composableBuilder(
      column: $table.discountRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice, builder: (column) => column);

  GeneratedColumn<int> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => column);

  GeneratedColumn<String> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get dimensions => $composableBuilder(
      column: $table.dimensions, builder: (column) => column);

  GeneratedColumn<int> get minimumStock => $composableBuilder(
      column: $table.minimumStock, builder: (column) => column);

  GeneratedColumn<int> get maximumStock => $composableBuilder(
      column: $table.maximumStock, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<double> get discountRate => $composableBuilder(
      column: $table.discountRate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$ProductsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTableTable,
    ProductsTableData,
    $$ProductsTableTableFilterComposer,
    $$ProductsTableTableOrderingComposer,
    $$ProductsTableTableAnnotationComposer,
    $$ProductsTableTableCreateCompanionBuilder,
    $$ProductsTableTableUpdateCompanionBuilder,
    (
      ProductsTableData,
      BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>
    ),
    ProductsTableData,
    PrefetchHooks Function()> {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> wholesalePrice = const Value.absent(),
            Value<int> retailPrice = const Value.absent(),
            Value<String> savedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String> lastModified = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> supplier = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> images = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<String?> dimensions = const Value.absent(),
            Value<int?> minimumStock = const Value.absent(),
            Value<int?> maximumStock = const Value.absent(),
            Value<double?> taxRate = const Value.absent(),
            Value<double?> discountRate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsTableCompanion(
            id: id,
            name: name,
            wholesalePrice: wholesalePrice,
            retailPrice: retailPrice,
            savedAt: savedAt,
            userId: userId,
            isSynced: isSynced,
            lastModified: lastModified,
            description: description,
            barcode: barcode,
            category: category,
            supplier: supplier,
            status: status,
            images: images,
            tags: tags,
            weight: weight,
            dimensions: dimensions,
            minimumStock: minimumStock,
            maximumStock: maximumStock,
            taxRate: taxRate,
            discountRate: discountRate,
            isActive: isActive,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> wholesalePrice = const Value.absent(),
            Value<int> retailPrice = const Value.absent(),
            required String savedAt,
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required String lastModified,
            Value<String?> description = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> supplier = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> images = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<String?> dimensions = const Value.absent(),
            Value<int?> minimumStock = const Value.absent(),
            Value<int?> maximumStock = const Value.absent(),
            Value<double?> taxRate = const Value.absent(),
            Value<double?> discountRate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsTableCompanion.insert(
            id: id,
            name: name,
            wholesalePrice: wholesalePrice,
            retailPrice: retailPrice,
            savedAt: savedAt,
            userId: userId,
            isSynced: isSynced,
            lastModified: lastModified,
            description: description,
            barcode: barcode,
            category: category,
            supplier: supplier,
            status: status,
            images: images,
            tags: tags,
            weight: weight,
            dimensions: dimensions,
            minimumStock: minimumStock,
            maximumStock: maximumStock,
            taxRate: taxRate,
            discountRate: discountRate,
            isActive: isActive,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTableTable,
    ProductsTableData,
    $$ProductsTableTableFilterComposer,
    $$ProductsTableTableOrderingComposer,
    $$ProductsTableTableAnnotationComposer,
    $$ProductsTableTableCreateCompanionBuilder,
    $$ProductsTableTableUpdateCompanionBuilder,
    (
      ProductsTableData,
      BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>
    ),
    ProductsTableData,
    PrefetchHooks Function()>;
typedef $$InventoryTableTableCreateCompanionBuilder = InventoryTableCompanion
    Function({
  required String id,
  required String name,
  Value<String?> barcode,
  Value<int> wholesalePrice,
  Value<int> retailPrice,
  Value<int> quantity,
  Value<int> originalQuantity,
  required String addedDate,
  required String addedTime,
  Value<String?> userId,
  Value<bool> isSynced,
  required String lastModified,
  Value<int> rowid,
});
typedef $$InventoryTableTableUpdateCompanionBuilder = InventoryTableCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> barcode,
  Value<int> wholesalePrice,
  Value<int> retailPrice,
  Value<int> quantity,
  Value<int> originalQuantity,
  Value<String> addedDate,
  Value<String> addedTime,
  Value<String?> userId,
  Value<bool> isSynced,
  Value<String> lastModified,
  Value<int> rowid,
});

class $$InventoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalQuantity => $composableBuilder(
      column: $table.originalQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addedDate => $composableBuilder(
      column: $table.addedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addedTime => $composableBuilder(
      column: $table.addedTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));
}

class $$InventoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalQuantity => $composableBuilder(
      column: $table.originalQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addedDate => $composableBuilder(
      column: $table.addedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addedTime => $composableBuilder(
      column: $table.addedTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$InventoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice, builder: (column) => column);

  GeneratedColumn<int> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get originalQuantity => $composableBuilder(
      column: $table.originalQuantity, builder: (column) => column);

  GeneratedColumn<String> get addedDate =>
      $composableBuilder(column: $table.addedDate, builder: (column) => column);

  GeneratedColumn<String> get addedTime =>
      $composableBuilder(column: $table.addedTime, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);
}

class $$InventoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryTableTable,
    InventoryTableData,
    $$InventoryTableTableFilterComposer,
    $$InventoryTableTableOrderingComposer,
    $$InventoryTableTableAnnotationComposer,
    $$InventoryTableTableCreateCompanionBuilder,
    $$InventoryTableTableUpdateCompanionBuilder,
    (
      InventoryTableData,
      BaseReferences<_$AppDatabase, $InventoryTableTable, InventoryTableData>
    ),
    InventoryTableData,
    PrefetchHooks Function()> {
  $$InventoryTableTableTableManager(
      _$AppDatabase db, $InventoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<int> wholesalePrice = const Value.absent(),
            Value<int> retailPrice = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<int> originalQuantity = const Value.absent(),
            Value<String> addedDate = const Value.absent(),
            Value<String> addedTime = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryTableCompanion(
            id: id,
            name: name,
            barcode: barcode,
            wholesalePrice: wholesalePrice,
            retailPrice: retailPrice,
            quantity: quantity,
            originalQuantity: originalQuantity,
            addedDate: addedDate,
            addedTime: addedTime,
            userId: userId,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> barcode = const Value.absent(),
            Value<int> wholesalePrice = const Value.absent(),
            Value<int> retailPrice = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<int> originalQuantity = const Value.absent(),
            required String addedDate,
            required String addedTime,
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required String lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryTableCompanion.insert(
            id: id,
            name: name,
            barcode: barcode,
            wholesalePrice: wholesalePrice,
            retailPrice: retailPrice,
            quantity: quantity,
            originalQuantity: originalQuantity,
            addedDate: addedDate,
            addedTime: addedTime,
            userId: userId,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryTableTable,
    InventoryTableData,
    $$InventoryTableTableFilterComposer,
    $$InventoryTableTableOrderingComposer,
    $$InventoryTableTableAnnotationComposer,
    $$InventoryTableTableCreateCompanionBuilder,
    $$InventoryTableTableUpdateCompanionBuilder,
    (
      InventoryTableData,
      BaseReferences<_$AppDatabase, $InventoryTableTable, InventoryTableData>
    ),
    InventoryTableData,
    PrefetchHooks Function()>;
typedef $$SyncOperationsTableTableCreateCompanionBuilder
    = SyncOperationsTableCompanion Function({
  Value<int> id,
  required String operation,
  required String targetTable,
  required String recordId,
  required String data,
  required String timestamp,
  required String createdAt,
  Value<bool> isProcessed,
  Value<int> retryCount,
});
typedef $$SyncOperationsTableTableUpdateCompanionBuilder
    = SyncOperationsTableCompanion Function({
  Value<int> id,
  Value<String> operation,
  Value<String> targetTable,
  Value<String> recordId,
  Value<String> data,
  Value<String> timestamp,
  Value<String> createdAt,
  Value<bool> isProcessed,
  Value<int> retryCount,
});

class $$SyncOperationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOperationsTableTable> {
  $$SyncOperationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isProcessed => $composableBuilder(
      column: $table.isProcessed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));
}

class $$SyncOperationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOperationsTableTable> {
  $$SyncOperationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isProcessed => $composableBuilder(
      column: $table.isProcessed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));
}

class $$SyncOperationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOperationsTableTable> {
  $$SyncOperationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isProcessed => $composableBuilder(
      column: $table.isProcessed, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);
}

class $$SyncOperationsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncOperationsTableTable,
    SyncOperationsTableData,
    $$SyncOperationsTableTableFilterComposer,
    $$SyncOperationsTableTableOrderingComposer,
    $$SyncOperationsTableTableAnnotationComposer,
    $$SyncOperationsTableTableCreateCompanionBuilder,
    $$SyncOperationsTableTableUpdateCompanionBuilder,
    (
      SyncOperationsTableData,
      BaseReferences<_$AppDatabase, $SyncOperationsTableTable,
          SyncOperationsTableData>
    ),
    SyncOperationsTableData,
    PrefetchHooks Function()> {
  $$SyncOperationsTableTableTableManager(
      _$AppDatabase db, $SyncOperationsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> targetTable = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<String> timestamp = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<bool> isProcessed = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SyncOperationsTableCompanion(
            id: id,
            operation: operation,
            targetTable: targetTable,
            recordId: recordId,
            data: data,
            timestamp: timestamp,
            createdAt: createdAt,
            isProcessed: isProcessed,
            retryCount: retryCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String operation,
            required String targetTable,
            required String recordId,
            required String data,
            required String timestamp,
            required String createdAt,
            Value<bool> isProcessed = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SyncOperationsTableCompanion.insert(
            id: id,
            operation: operation,
            targetTable: targetTable,
            recordId: recordId,
            data: data,
            timestamp: timestamp,
            createdAt: createdAt,
            isProcessed: isProcessed,
            retryCount: retryCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncOperationsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncOperationsTableTable,
    SyncOperationsTableData,
    $$SyncOperationsTableTableFilterComposer,
    $$SyncOperationsTableTableOrderingComposer,
    $$SyncOperationsTableTableAnnotationComposer,
    $$SyncOperationsTableTableCreateCompanionBuilder,
    $$SyncOperationsTableTableUpdateCompanionBuilder,
    (
      SyncOperationsTableData,
      BaseReferences<_$AppDatabase, $SyncOperationsTableTable,
          SyncOperationsTableData>
    ),
    SyncOperationsTableData,
    PrefetchHooks Function()>;
typedef $$SalesTableTableCreateCompanionBuilder = SalesTableCompanion Function({
  required String id,
  required String items,
  Value<int> totalAmount,
  Value<int> totalProfit,
  required String saleDate,
  Value<String?> customerName,
  Value<String?> notes,
  Value<String> paymentMethod,
  Value<int> discount,
  Value<String?> userId,
  Value<bool> isSynced,
  required String lastModified,
  Value<int> rowid,
});
typedef $$SalesTableTableUpdateCompanionBuilder = SalesTableCompanion Function({
  Value<String> id,
  Value<String> items,
  Value<int> totalAmount,
  Value<int> totalProfit,
  Value<String> saleDate,
  Value<String?> customerName,
  Value<String?> notes,
  Value<String> paymentMethod,
  Value<int> discount,
  Value<String?> userId,
  Value<bool> isSynced,
  Value<String> lastModified,
  Value<int> rowid,
});

class $$SalesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SalesTableTable> {
  $$SalesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalProfit => $composableBuilder(
      column: $table.totalProfit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saleDate => $composableBuilder(
      column: $table.saleDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));
}

class $$SalesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTableTable> {
  $$SalesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalProfit => $composableBuilder(
      column: $table.totalProfit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saleDate => $composableBuilder(
      column: $table.saleDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$SalesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTableTable> {
  $$SalesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<int> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<int> get totalProfit => $composableBuilder(
      column: $table.totalProfit, builder: (column) => column);

  GeneratedColumn<String> get saleDate =>
      $composableBuilder(column: $table.saleDate, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<int> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);
}

class $$SalesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesTableTable,
    SalesTableData,
    $$SalesTableTableFilterComposer,
    $$SalesTableTableOrderingComposer,
    $$SalesTableTableAnnotationComposer,
    $$SalesTableTableCreateCompanionBuilder,
    $$SalesTableTableUpdateCompanionBuilder,
    (
      SalesTableData,
      BaseReferences<_$AppDatabase, $SalesTableTable, SalesTableData>
    ),
    SalesTableData,
    PrefetchHooks Function()> {
  $$SalesTableTableTableManager(_$AppDatabase db, $SalesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> items = const Value.absent(),
            Value<int> totalAmount = const Value.absent(),
            Value<int> totalProfit = const Value.absent(),
            Value<String> saleDate = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<int> discount = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesTableCompanion(
            id: id,
            items: items,
            totalAmount: totalAmount,
            totalProfit: totalProfit,
            saleDate: saleDate,
            customerName: customerName,
            notes: notes,
            paymentMethod: paymentMethod,
            discount: discount,
            userId: userId,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String items,
            Value<int> totalAmount = const Value.absent(),
            Value<int> totalProfit = const Value.absent(),
            required String saleDate,
            Value<String?> customerName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<int> discount = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            required String lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesTableCompanion.insert(
            id: id,
            items: items,
            totalAmount: totalAmount,
            totalProfit: totalProfit,
            saleDate: saleDate,
            customerName: customerName,
            notes: notes,
            paymentMethod: paymentMethod,
            discount: discount,
            userId: userId,
            isSynced: isSynced,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SalesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalesTableTable,
    SalesTableData,
    $$SalesTableTableFilterComposer,
    $$SalesTableTableOrderingComposer,
    $$SalesTableTableAnnotationComposer,
    $$SalesTableTableCreateCompanionBuilder,
    $$SalesTableTableUpdateCompanionBuilder,
    (
      SalesTableData,
      BaseReferences<_$AppDatabase, $SalesTableTable, SalesTableData>
    ),
    SalesTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$InventoryTableTableTableManager get inventoryTable =>
      $$InventoryTableTableTableManager(_db, _db.inventoryTable);
  $$SyncOperationsTableTableTableManager get syncOperationsTable =>
      $$SyncOperationsTableTableTableManager(_db, _db.syncOperationsTable);
  $$SalesTableTableTableManager get salesTable =>
      $$SalesTableTableTableManager(_db, _db.salesTable);
}
