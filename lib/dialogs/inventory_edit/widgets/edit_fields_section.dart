import 'package:flutter/material.dart';

import '../../../utils/responsive_breakpoints.dart';
import '../controllers/edit_item_controller.dart';
import 'changes_summary.dart';
import 'custom_text_field.dart';

class EditFieldsSection extends StatelessWidget {
  const EditFieldsSection({
    super.key,
    required this.editController,
  });

  final EditItemController editController;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'تعديل البيانات',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),

          // اسم المنتج
          CustomTextField(
            controller: editController.nameController,
            label: 'اسم المنتج',
            icon: Icons.label,
            color: Colors.blue,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم المنتج مطلوب';
              }
              return null;
            },
            onChanged: (_) {},
          ),

          SizedBox(height: context.responsiveSpacing),

          // الأسعار - responsive layout
          if (context.shouldUseVerticalLayout)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CustomTextField(
                  controller: editController.wholesalePriceController,
                  label: 'سعر الجملة',
                  icon: Icons.attach_money,
                  color: Colors.green,
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'سعر الجملة مطلوب';
                    }
                    final int? price = int.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'يجب أن يكون السعر أكبر من صفر';
                    }
                    return null;
                  },
                  onChanged: (_) {},
                ),
                SizedBox(height: context.responsiveSpacing),
                CustomTextField(
                  controller: editController.retailPriceController,
                  label: 'سعر التجزئة',
                  icon: Icons.sell,
                  color: Colors.orange,
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'سعر التجزئة مطلوب';
                    }
                    final int? price = int.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'يجب أن يكون السعر أكبر من صفر';
                    }
                    return null;
                  },
                  onChanged: (_) {},
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: CustomTextField(
                    controller: editController.wholesalePriceController,
                    label: 'سعر الجملة',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    keyboardType: TextInputType.number,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'سعر الجملة مطلوب';
                      }
                      final int? price = int.tryParse(value.trim());
                      if (price == null || price <= 0) {
                        return 'يجب أن يكون السعر أكبر من صفر';
                      }
                      return null;
                    },
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(width: context.responsiveSpacing),
                Expanded(
                  child: CustomTextField(
                    controller: editController.retailPriceController,
                    label: 'سعر التجزئة',
                    icon: Icons.sell,
                    color: Colors.orange,
                    keyboardType: TextInputType.number,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'سعر التجزئة مطلوب';
                      }
                      final int? price = int.tryParse(value.trim());
                      if (price == null || price <= 0) {
                        return 'يجب أن يكون السعر أكبر من صفر';
                      }
                      return null;
                    },
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),

          SizedBox(height: context.responsiveSpacing),

          // الكمية
          CustomTextField(
            controller: editController.quantityController,
            label: 'الكمية',
            icon: Icons.inventory_2,
            color: Colors.blue,
            keyboardType: TextInputType.number,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'الكمية مطلوبة';
              }
              final int? quantity = int.tryParse(value.trim());
              if (quantity == null || quantity < 0) {
                return 'يجب أن تكون الكمية أكبر من أو تساوي صفر';
              }
              return null;
            },
            onChanged: (_) {},
          ),

          SizedBox(height: context.responsiveSpacing),

          // ملخص التغييرات
          ChangesSummary(editController: editController),
        ],
      );
}
