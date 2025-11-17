import 'package:flutter/material.dart';

import '../../../utils/responsive_breakpoints.dart';
import '../controllers/edit_item_controller.dart';
import 'edit_fields_section.dart';
import 'info_card.dart';

class DialogContent extends StatelessWidget {
  const DialogContent({
    super.key,
    required this.editController,
  });

  final EditItemController editController;

  @override
  Widget build(BuildContext context) => Padding(
        padding: context.responsivePadding,
        child: Form(
          key: editController.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // معلومات العنصر
              InfoCard(editController: editController),
              SizedBox(height: context.responsiveSpacing),

              // حقول التعديل
              EditFieldsSection(editController: editController),
            ],
          ),
        ),
      );
}
