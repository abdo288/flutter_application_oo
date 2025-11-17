import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import '../../../utils/responsive_breakpoints.dart';
import 'inventory_card.dart';

class InventoryList extends ConsumerWidget {
  const InventoryList({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // استخدام ListView للويندوز لعرض البطاقات المضغوطة
    if (Platform.isWindows) {
      return ListView.separated(
        physics: context.responsiveScrollPhysics,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing * 0.3,
          vertical: context.responsiveSpacing * 0.2, // تقليل المسافة العمودية
        ),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 6), // مسافة صغيرة بين البطاقات
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) => InventoryCard(
          item: items[index],
          key: ValueKey('${items[index].id}_${items.length}'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final bool useGrid = width >= 700;

        if (useGrid) {
          return GridView.builder(
            physics: context.responsiveScrollPhysics,
            padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing * 0.5,
                vertical: context.responsiveSpacing * 0.4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.gridColumns,
              crossAxisSpacing: context.responsiveSpacing * 0.5,
              mainAxisSpacing: context.responsiveSpacing * 0.5,
              childAspectRatio: context.isSmallScreen ? 1.2 : 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) => InventoryCard(
              item: items[index],
              key: ValueKey('${items[index].id}_${items.length}'),
            ),
          );
        }
        return ListView.builder(
          physics: context.responsiveScrollPhysics,
          padding: EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing * 0.5,
              vertical: context.responsiveSpacing * 0.4),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            final InventoryItem item = items[index];
            return Container(
              margin: EdgeInsets.only(bottom: context.responsiveSpacing * 0.4),
              child: InventoryCard(
                item: item,
                key: ValueKey('${item.id}_${items.length}'),
              ),
            );
          },
        );
      },
    );
  }
}
