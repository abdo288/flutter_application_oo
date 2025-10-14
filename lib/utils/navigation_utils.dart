import 'package:flutter/material.dart';

/// Utility class for safe navigation operations
/// Prevents Navigator assertion errors by checking canPop() before popping
class NavigationUtils {
  /// Safely pops the current route if possible
  /// Returns true if popped, false if no routes to pop
  static bool safePop(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

  /// Safely pops the current route with a result if possible
  /// Returns true if popped, false if no routes to pop
  static bool safePopWithResult<T>(BuildContext context, T result) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop<T>(result);
      return true;
    }
    return false;
  }

  /// Safely pops until a specific route is reached
  /// Returns true if popped, false if no routes to pop
  static bool safePopUntil(BuildContext context, RoutePredicate predicate) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil(predicate);
      return true;
    }
    return false;
  }

  /// Safely pops to root route
  /// Returns true if popped, false if no routes to pop
  static bool safePopToRoot(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      return true;
    }
    return false;
  }

  /// Safely pushes a new route
  /// Returns the result of the push operation
  static Future<T?> safePush<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) {
    if (context.mounted) {
      return Navigator.of(context).push<T>(route);
    }
    return Future<T?>.value();
  }

  /// Safely pushes a named route
  /// Returns the result of the push operation
  static Future<T?> safePushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (context.mounted) {
      return Navigator.of(context)
          .pushNamed<T>(routeName, arguments: arguments);
    }
    return Future<T?>.value();
  }

  /// Safely pushes and replaces the current route
  /// Returns the result of the push operation
  static Future<T?> safePushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) {
    if (context.mounted) {
      return Navigator.of(context)
          .pushReplacement<T, TO>(newRoute, result: result);
    }
    return Future<T?>.value();
  }

  /// Safely pushes and replaces a named route
  /// Returns the result of the push operation
  static Future<T?>
      safePushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    if (context.mounted) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    }
    return Future<T?>.value();
  }

  /// Safely pushes and removes all previous routes
  /// Returns the result of the push operation
  static Future<T?> safePushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Route<T> newRoute,
    RoutePredicate predicate,
  ) {
    if (context.mounted) {
      return Navigator.of(context).pushAndRemoveUntil<T>(newRoute, predicate);
    }
    return Future<T?>.value();
  }

  /// Safely pushes a named route and removes all previous routes
  /// Returns the result of the push operation
  static Future<T?> safePushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    if (context.mounted) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        newRouteName,
        predicate,
        arguments: arguments,
      );
    }
    return Future<T?>.value();
  }

  /// Checks if the context is mounted and can pop
  static bool canPop(BuildContext context) => context.mounted && Navigator.of(context).canPop();

  /// Safely shows a dialog
  static Future<T?> safeShowDialog<T extends Object?>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    if (context.mounted) {
      return showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );
    }
    return Future<T?>.value();
  }

  /// Safely shows a modal bottom sheet
  static Future<T?> safeShowModalBottomSheet<T extends Object?>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) {
    if (context.mounted) {
      return showModalBottomSheet<T>(
        context: context,
        builder: builder,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
        anchorPoint: anchorPoint,
      );
    }
    return Future<T?>.value();
  }

  /// Safely shows a general dialog
  static Future<T?> safeShowGeneralDialog<T extends Object?>({
    required BuildContext context,
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    if (context.mounted) {
      return showGeneralDialog<T>(
        context: context,
        pageBuilder: pageBuilder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );
    }
    return Future<T?>.value();
  }
}

/// Extension methods for easier navigation
extension NavigationUtilsExtension on BuildContext {
  /// Safely pops the current route if possible
  bool safePop() => NavigationUtils.safePop(this);

  /// Safely pops the current route with a result if possible
  bool safePopWithResult<T>(T result) =>
      NavigationUtils.safePopWithResult<T>(this, result);

  /// Safely pops until a specific route is reached
  bool safePopUntil(RoutePredicate predicate) =>
      NavigationUtils.safePopUntil(this, predicate);

  /// Safely pops to root route
  bool safePopToRoot() => NavigationUtils.safePopToRoot(this);

  /// Safely pushes a new route
  Future<T?> safePush<T extends Object?>(Route<T> route) =>
      NavigationUtils.safePush<T>(this, route);

  /// Safely pushes a named route
  Future<T?> safePushNamed<T extends Object?>(String routeName,
          {Object? arguments}) =>
      NavigationUtils.safePushNamed<T>(this, routeName, arguments: arguments);

  /// Safely pushes and replaces the current route
  Future<T?> safePushReplacement<T extends Object?, TO extends Object?>(
    Route<T> newRoute, {
    TO? result,
  }) =>
      NavigationUtils.safePushReplacement<T, TO>(this, newRoute,
          result: result);

  /// Safely pushes and replaces a named route
  Future<T?> safePushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) =>
      NavigationUtils.safePushReplacementNamed<T, TO>(this, routeName,
          arguments: arguments, result: result);

  /// Safely pushes and removes all previous routes
  Future<T?> safePushAndRemoveUntil<T extends Object?>(
    Route<T> newRoute,
    RoutePredicate predicate,
  ) =>
      NavigationUtils.safePushAndRemoveUntil<T>(this, newRoute, predicate);

  /// Safely pushes a named route and removes all previous routes
  Future<T?> safePushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) =>
      NavigationUtils.safePushNamedAndRemoveUntil<T>(
          this, newRouteName, predicate,
          arguments: arguments);

  /// Checks if the context can pop
  bool get canPop => NavigationUtils.canPop(this);

  /// Safely shows a dialog
  Future<T?> safeShowDialog<T extends Object?>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) =>
      NavigationUtils.safeShowDialog<T>(
        context: this,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );

  /// Safely shows a modal bottom sheet
  Future<T?> safeShowModalBottomSheet<T extends Object?>({
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) =>
      NavigationUtils.safeShowModalBottomSheet<T>(
        context: this,
        builder: builder,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
        anchorPoint: anchorPoint,
      );
}
