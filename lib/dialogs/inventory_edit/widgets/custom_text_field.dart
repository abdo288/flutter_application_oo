import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.keyboardType,
    this.inputFormatters,
    required this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?) validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: context.responsiveFontSize(14)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
            prefixIcon:
                Icon(icon, color: color, size: context.isSmallScreen ? 20 : 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: color.withOpacity(0.05),
            contentPadding: context.responsivePadding,
            isDense: context.isSmallScreen,
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      );
}
