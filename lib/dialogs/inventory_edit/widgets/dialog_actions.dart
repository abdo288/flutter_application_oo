import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../controllers/edit_item_controller.dart';

class DialogActions extends StatelessWidget {
  const DialogActions({
    super.key,
    required this.editController,
    required this.onCancel,
  });

  final EditItemController editController;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppConstants.borderRadius * 2),
            bottomRight: Radius.circular(AppConstants.borderRadius * 2),
          ),
        ),
        child: context.shouldUseVerticalLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // عرض رسالة الخطأ إذا وجدت
                  if (editController.errorMessage != null)
                    Container(
                      margin: EdgeInsets.only(
                          bottom: context.responsiveSpacing * 0.5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.error_outline,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              editController.errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: context.responsiveFontSize(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: editController.isLoading
                        ? null
                        : editController.updateItem,
                    icon: editController.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      editController.isLoading
                          ? 'جاري الحفظ...'
                          : 'حفظ التغييرات',
                      style:
                          TextStyle(fontSize: context.responsiveFontSize(14)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsiveSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  OutlinedButton.icon(
                    onPressed: editController.isLoading ? null : onCancel,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text('إلغاء',
                        style: TextStyle(
                            fontSize: context.responsiveFontSize(14))),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsiveSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // عرض رسالة الخطأ إذا وجدت
                  if (editController.errorMessage != null)
                    Container(
                      margin: EdgeInsets.only(
                          bottom: context.responsiveSpacing * 0.5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.error_outline,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              editController.errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: context.responsiveFontSize(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: editController.isLoading ? null : onCancel,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: Text('إلغاء',
                              style: TextStyle(
                                  fontSize: context.responsiveFontSize(14))),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: context.responsiveSpacing),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.responsiveSpacing),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: editController.isLoading
                              ? null
                              : editController.updateItem,
                          icon: editController.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: Text(
                            editController.isLoading ? 'جاري الحفظ...' : 'حفظ',
                            style: TextStyle(
                                fontSize: context.responsiveFontSize(14)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: context.responsiveSpacing),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      );
}
