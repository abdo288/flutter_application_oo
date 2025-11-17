import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_breakpoints.dart';
import 'controllers/edit_item_controller.dart';
import 'widgets/dialog_actions.dart';
import 'widgets/dialog_content.dart';
import 'widgets/dialog_header.dart';

/// حوار تعديل عنصر المخزون المحسن بـ Riverpod
class ModernEditInventoryDialogRiverpod extends ConsumerStatefulWidget {
  const ModernEditInventoryDialogRiverpod({
    super.key,
    required this.item,
    required this.onItemUpdated,
  });

  final InventoryItem item;
  final VoidCallback onItemUpdated;

  @override
  ConsumerState<ModernEditInventoryDialogRiverpod> createState() =>
      _ModernEditInventoryDialogRiverpodState();
}

class _ModernEditInventoryDialogRiverpodState
    extends ConsumerState<ModernEditInventoryDialogRiverpod>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late EditItemController _editController;
  bool hasInitializedController = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    if (hasInitializedController && _editController.mounted) {
      _editController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  EditItemController _createController() {
    // إنشاء controller مع callback يغلق النافذة بعد النجاح
    return EditItemController(
      item: widget.item,
      onItemUpdated: () {
        debugPrint('تم تحديث عنصر المخزون بنجاح: ${widget.item.name}');
        // التحقق من أن الـ widget ما زال mounted قبل إجراء أي عمليات
        if (mounted && context.mounted && Navigator.of(context).mounted) {
          Navigator.of(context).pop();
          widget.onItemUpdated();
        }
      },
      ref: ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    // إنشاء controller في أول بناء فقط
    if (!hasInitializedController) {
      _editController = _createController();
      hasInitializedController = true;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
      ),
      elevation: 8,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (BuildContext context, Widget? child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: ConstrainedBox(
            constraints: context.dialogConstraints,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius * 2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DialogHeader(
                    item: widget.item,
                    onClose: () {
                      if (mounted &&
                          context.mounted &&
                          Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: context.responsiveScrollPhysics,
                      child: DialogContent(
                        editController: _editController,
                      ),
                    ),
                  ),
                  DialogActions(
                    editController: _editController,
                    onCancel: () {
                      if (mounted &&
                          context.mounted &&
                          Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
