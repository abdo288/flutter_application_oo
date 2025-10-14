import 'package:flutter/material.dart';
import '../utils/responsive_breakpoints.dart';

/// Widget قابل لإعادة الاستخدام للـ layouts المتجاوبة
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.constraints,
    this.alignment,
    this.decoration,
    this.clipBehavior,
    this.safeArea = false,
    this.scrollable = false,
    this.physics,
    this.shrinkWrap = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxConstraints? constraints;
  final Alignment? alignment;
  final Decoration? decoration;
  final Clip? clipBehavior;
  final bool safeArea;
  final bool scrollable;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // إضافة constraints إذا تم توفيرها
    if (constraints != null) {
      content = ConstrainedBox(
        constraints: constraints!,
        child: content,
      );
    }

    // إضافة padding
    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    // إضافة margin
    if (margin != null) {
      content = Container(
        margin: margin!,
        child: content,
      );
    }

    // إضافة decoration
    if (decoration != null) {
      content = Container(
        decoration: decoration,
        clipBehavior: clipBehavior ?? Clip.none,
        child: content,
      );
    }

    // إضافة alignment
    if (alignment != null) {
      content = Align(
        alignment: alignment!,
        child: content,
      );
    }

    // إضافة scrollable إذا كان مطلوباً
    if (scrollable) {
      content = SingleChildScrollView(
        physics: physics ?? context.responsiveScrollPhysics,
        child: content,
      );
    }

    // إضافة SafeArea إذا كان مطلوباً
    if (safeArea && context.shouldUseSafeArea) {
      content = SafeArea(
        child: content,
      );
    }

    return content;
  }
}

/// Responsive Dialog Wrapper
class ResponsiveDialogWrapper extends StatelessWidget {
  const ResponsiveDialogWrapper({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: context.dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Container(
                width: double.infinity,
                padding: context.responsivePadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsiveFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  physics: context.responsiveScrollPhysics,
                  padding: context.responsivePadding,
                  child: child,
                ),
              )
            else
              Padding(
                padding: context.responsivePadding,
                child: child,
              ),
            if (actions != null) ...[
              const Divider(height: 1),
              Padding(
                padding: context.responsivePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
}

/// Responsive Grid Wrapper
class ResponsiveGridWrapper extends StatelessWidget {
  const ResponsiveGridWrapper({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.crossAxisCount,
    this.aspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? crossAxisCount;
  final double? aspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final int columns = crossAxisCount ?? context.responsiveGridColumns;
    final double aspectRatioValue = aspectRatio ?? context.responsiveAspectRatio;
    
    if (context.shouldUseSingleColumn) {
      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics ?? context.responsiveScrollPhysics,
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: children[index],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? context.responsiveScrollPhysics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing ?? spacing,
        mainAxisSpacing: mainAxisSpacing ?? spacing,
        childAspectRatio: aspectRatioValue,
      ),
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) => children[index],
    );
  }
}

/// Responsive Row/Column Wrapper
class ResponsiveFlexWrapper extends StatelessWidget {
  const ResponsiveFlexWrapper({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.wrap = false,
  });

  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (wrap || context.shouldUseWrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
    }

    if (context.shouldUseVerticalLayout) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children
            .expand((Widget child) => <Widget>[child, SizedBox(height: spacing)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children
          .expand((Widget child) => <Widget>[child, SizedBox(width: spacing)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

/// Responsive Card Wrapper
class ResponsiveCardWrapper extends StatelessWidget {
  const ResponsiveCardWrapper({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.shape,
    this.color,
    this.semanticContainer = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final ShapeBorder? shape;
  final Color? color;
  final bool semanticContainer;

  @override
  Widget build(BuildContext context) => Card(
      margin: margin ?? EdgeInsets.all(context.responsiveSpacing),
      elevation: elevation ?? (context.isSmallScreen ? 2 : 4),
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.isSmallScreen ? 8 : 12),
      ),
      color: color,
      semanticContainer: semanticContainer,
      child: Padding(
        padding: padding ?? context.responsivePadding,
        child: child,
      ),
    );
}

/// Responsive Text Wrapper
class ResponsiveTextWrapper extends StatelessWidget {
  const ResponsiveTextWrapper({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: context.textConstraints,
      child: Text(
        text,
        style: style ?? TextStyle(
          fontSize: context.responsiveFontSize(14),
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
}

/// Responsive Input Wrapper
class ResponsiveInputWrapper extends StatelessWidget {
  const ResponsiveInputWrapper({
    super.key,
    required this.child,
    this.label,
    this.helperText,
    this.errorText,
    this.isRequired = false,
  });

  final Widget child;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool isRequired;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            isRequired ? '$label *' : label!,
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),
        ],
        ConstrainedBox(
          constraints: context.inputConstraints,
          child: child,
        ),
        if (helperText != null) ...[
          SizedBox(height: context.responsiveSpacing * 0.5),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: context.responsiveFontSize(12),
              color: Colors.grey[600],
            ),
          ),
        ],
        if (errorText != null) ...[
          SizedBox(height: context.responsiveSpacing * 0.5),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: context.responsiveFontSize(12),
              color: Colors.red[600],
            ),
          ),
        ],
      ],
    );
}

/// Responsive Button Wrapper
class ResponsiveButtonWrapper extends StatelessWidget {
  const ResponsiveButtonWrapper({
    super.key,
    required this.child,
    this.fullWidth = false,
    this.minHeight,
  });

  final Widget child;
  final bool fullWidth;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    Widget button = child;

    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    if (minHeight != null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight!,
        ),
        child: button,
      );
    }

    return button;
  }
}
