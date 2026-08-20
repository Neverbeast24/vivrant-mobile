import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Allows swiping modules with any pointer, not just touch.
class _VivrantDragScrollBehavior extends MaterialScrollBehavior {
  const _VivrantDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Instagram-style swipeable tab body.
///
/// Drag horizontally to move between modules. Drive the footer pill with
/// [positionNotifier] so shells do not `setState` every frame.
class VivrantSlidingIndexedStack extends StatefulWidget {
  const VivrantSlidingIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.onIndexChanged,
    this.positionNotifier,
    this.onPositionChanged,
    this.duration = const Duration(milliseconds: 350),
    this.physicsEnabled = true,
    this.enableHaptics = true,
  });

  final int index;
  final List<Widget> children;
  final ValueChanged<int>? onIndexChanged;

  /// Preferred: update this notifier from scroll — pill rebuilds alone.
  final ValueNotifier<double>? positionNotifier;

  /// Legacy callback; prefer [positionNotifier] to avoid full-shell rebuilds.
  final ValueChanged<double>? onPositionChanged;
  final Duration duration;
  final bool physicsEnabled;
  final bool enableHaptics;

  @override
  State<VivrantSlidingIndexedStack> createState() =>
      _VivrantSlidingIndexedStackState();
}

class _VivrantSlidingIndexedStackState
    extends State<VivrantSlidingIndexedStack> {
  late final PageController _controller;
  int _lastReportedIndex = 0;
  bool _programmaticJump = false;
  bool _emittingPosition = false;

  /// True while mirroring a footer-driven [positionNotifier] into the page.
  int _externalSyncDepth = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.index.clamp(0, _maxIndex);
    _lastReportedIndex = initial;
    _controller = PageController(initialPage: initial);
    _controller.addListener(_handleScroll);
    widget.positionNotifier?.addListener(_handleExternalPosition);
    _emitPosition(initial.toDouble());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitPosition(
        _controller.hasClients
            ? (_controller.page ?? initial.toDouble())
            : initial.toDouble(),
      );
    });
  }

  int get _maxIndex => widget.children.isEmpty ? 0 : widget.children.length - 1;

  bool get _reduceMotion {
    final mq = MediaQuery.maybeOf(context);
    return mq?.disableAnimations == true;
  }

  Duration get _animDuration => _reduceMotion ? Duration.zero : widget.duration;

  void _emitPosition(double page) {
    void apply() {
      final notifier = widget.positionNotifier;
      if (notifier != null && notifier.value != page) {
        _emittingPosition = true;
        notifier.value = page;
        _emittingPosition = false;
      }
      widget.onPositionChanged?.call(page);
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) apply();
      });
      return;
    }
    apply();
  }

  /// A footer drag updates the shared notifier. Mirror that fractional tab
  /// position directly into the PageController so the module follows the
  /// user's finger instead of waiting for drag-end selection.
  void _handleExternalPosition() {
    if (_emittingPosition ||
        !_controller.hasClients ||
        !_controller.position.haveDimensions) {
      return;
    }
    final notifier = widget.positionNotifier;
    if (notifier == null) return;
    final page = notifier.value.clamp(0.0, _maxIndex.toDouble());
    final targetPixels = (page * _controller.position.viewportDimension).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    if ((_controller.position.pixels - targetPixels).abs() < 0.5) return;

    _externalSyncDepth++;
    try {
      _controller.jumpTo(targetPixels);
    } finally {
      _externalSyncDepth--;
    }
  }

  void _handleScroll() {
    if (!_controller.hasClients || !_controller.position.haveDimensions) {
      return;
    }
    final page = _controller.page;
    if (page == null) return;
    _emitPosition(page);
  }

  void _tickHaptic() {
    if (!widget.enableHaptics || _reduceMotion || kIsWeb) return;
    HapticFeedback.selectionClick();
  }

  void _animateTo(int target, {required bool animate}) {
    if (!_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateTo(target, animate: animate);
      });
      return;
    }

    final page = _controller.page ?? _controller.initialPage.toDouble();
    if ((page - target).abs() < 0.001) {
      _lastReportedIndex = target;
      _emitPosition(target.toDouble());
      return;
    }

    _programmaticJump = true;
    final shouldAnimate = animate && !_reduceMotion;
    if (!shouldAnimate) {
      _controller.jumpToPage(target);
      _lastReportedIndex = target;
      _programmaticJump = false;
      _emitPosition(target.toDouble());
      return;
    }

    _controller
        .animateToPage(
          target,
          duration: _animDuration,
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (!mounted) return;
          _programmaticJump = false;
          _lastReportedIndex = target;
          _emitPosition(target.toDouble());
        });
  }

  bool get _isUserScrolling {
    if (!_controller.hasClients || !_controller.position.haveDimensions) {
      return false;
    }
    return _controller.position.isScrollingNotifier.value;
  }

  @override
  void didUpdateWidget(VivrantSlidingIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.positionNotifier != oldWidget.positionNotifier) {
      oldWidget.positionNotifier?.removeListener(_handleExternalPosition);
      widget.positionNotifier?.addListener(_handleExternalPosition);
    }

    final target = widget.index.clamp(0, _maxIndex);

    if (widget.children.length != oldWidget.children.length) {
      _animateTo(target, animate: false);
      return;
    }

    if (widget.index != oldWidget.index) {
      if (target == _lastReportedIndex &&
          _controller.hasClients &&
          ((_controller.page ?? target.toDouble()) - target).abs() < 0.01) {
        return;
      }
      _animateTo(target, animate: true);
      return;
    }

    if (_controller.hasClients &&
        _controller.position.haveDimensions &&
        !_programmaticJump &&
        _externalSyncDepth == 0 &&
        !_isUserScrolling) {
      final page = _controller.page ?? target.toDouble();
      if ((page - target).abs() > 0.01) {
        _animateTo(target, animate: true);
      }
    }
  }

  @override
  void dispose() {
    widget.positionNotifier?.removeListener(_handleExternalPosition);
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_programmaticJump || _externalSyncDepth > 0) {
      return;
    }
    final changed = index != _lastReportedIndex;
    _lastReportedIndex = index;
    if (changed) _tickHaptic();
    widget.onIndexChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    final physics = !widget.physicsEnabled || _reduceMotion
        ? const NeverScrollableScrollPhysics()
        : const PageScrollPhysics(
            parent: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
          );

    return ScrollConfiguration(
      behavior: const _VivrantDragScrollBehavior(),
      child: PageView(
        controller: _controller,
        allowImplicitScrolling: true,
        physics: physics,
        onPageChanged: _onPageChanged,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            KeyedSubtree(
              key: ValueKey<int>(i),
              child: _KeepAlivePage(child: widget.children[i]),
            ),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
