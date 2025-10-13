import 'package:flutter/material.dart';
import 'constants.dart';

/// Custom page route with modern transitions
class ModernPageRoute<T> extends PageRoute<T> {
  ModernPageRoute({
    required this.builder,
    this.transitionType = PageTransitionType.fade,
    this.duration = AppConstants.animationNormal,
    RouteSettings? settings,
    this.fullscreenDialog = false,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog);

  final WidgetBuilder builder;
  final PageTransitionType transitionType;
  final Duration duration;
  final bool fullscreenDialog;

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (transitionType) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case PageTransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case PageTransitionType.rotate:
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case PageTransitionType.fadeSlideFromRight:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );

      case PageTransitionType.scaleRotate:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: RotationTransition(
            turns: Tween<double>(begin: -0.1, end: 0.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
    }
  }
}

/// Page transition types
enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  scale,
  rotate,
  fadeSlideFromRight,
  scaleRotate,
}

/// Helper method to navigate with custom transition
Future<T?> navigateWithTransition<T>(
  BuildContext context,
  Widget page, {
  PageTransitionType transition = PageTransitionType.fadeSlideFromRight,
  Duration? duration,
  bool fullscreenDialog = false,
}) {
  return Navigator.of(context).push<T>(
    ModernPageRoute<T>(
      builder: (context) => page,
      transitionType: transition,
      duration: duration ?? AppConstants.animationNormal,
      fullscreenDialog: fullscreenDialog,
    ),
  );
}

/// Hero transition helper
class HeroTransition extends StatelessWidget {
  const HeroTransition({
    super.key,
    required this.tag,
    required this.child,
  });

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}

/// Shared axis transition
class SharedAxisTransition<T> extends PageRouteBuilder<T> {
  SharedAxisTransition({
    required this.page,
    this.transitionType = SharedAxisTransitionType.horizontal,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: AppConstants.animationNormal,
          reverseTransitionDuration: AppConstants.animationNormal,
          pageBuilder: (context, animation, secondaryAnimation) => page,
        );

  final Widget page;
  final SharedAxisTransitionType transitionType;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final tween = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    final slideAnimation = tween.animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOut,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Offset _getBeginOffset() {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        return const Offset(0.3, 0);
      case SharedAxisTransitionType.vertical:
        return const Offset(0, 0.3);
      case SharedAxisTransitionType.scaled:
        return Offset.zero;
    }
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// Fade through transition (for switching between tabs/pages)
class FadeThroughTransition extends StatelessWidget {
  const FadeThroughTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        child: child,
      ),
    );
  }
}
