import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SmoothPageSwitcher extends StatefulWidget {
  const SmoothPageSwitcher({
    required this.currentIndex,
    required this.children,
    required this.animatedIndices,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;
  final Set<int> animatedIndices;

  @override
  State<SmoothPageSwitcher> createState() => _SmoothPageSwitcherState();
}

class _SmoothPageSwitcherState extends State<SmoothPageSwitcher>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 400);
  static const _curve = Cubic(0.32, 0.72, 0, 1);

  late final AnimationController _controller;
  int? _previousIndex;
  late int _selectedIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant SmoothPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == _selectedIndex) {
      return;
    }

    final nextIndex = widget.currentIndex;
    final shouldAnimate =
        widget.animatedIndices.contains(_selectedIndex) &&
        widget.animatedIndices.contains(nextIndex);

    if (!shouldAnimate) {
      _previousIndex = null;
      _selectedIndex = nextIndex;
      _controller.value = 1;
      return;
    }

    _direction = _mainWindowPosition(nextIndex) >
            _mainWindowPosition(_selectedIndex)
        ? 1
        : -1;
    _previousIndex = _selectedIndex;
    _selectedIndex = nextIndex;
    _controller.forward(from: 0);
  }

  int _mainWindowPosition(int index) {
    return const [1, 0, 2, 4].indexOf(index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_previousIndex == null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              for (var index = 0; index < widget.children.length; index++)
                if (index != _selectedIndex)
                  Offstage(
                    offstage: true,
                    child: KeyedSubtree(
                      key: ValueKey(index),
                      child: widget.children[index],
                    ),
                  )
                else
                  KeyedSubtree(
                    key: ValueKey(index),
                    child: widget.children[index],
                  ),
            ],
          );
        }

        final progress = CurvedAnimation(
          parent: _controller,
          curve: _curve,
        ).value;

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var index = 0; index < widget.children.length; index++)
              if (index != _selectedIndex && index != _previousIndex)
                Offstage(
                  offstage: true,
                  child: KeyedSubtree(
                    key: ValueKey(index),
                    child: widget.children[index],
                  ),
                ),
            if (_previousIndex != null)
              _buildAnimatedPage(
                index: _previousIndex!,
                offset: -_direction * progress,
                opacity: 1 - progress,
                scale: 1 - (0.05 * progress),
                blur: 8 * progress,
              ),
            _buildAnimatedPage(
              index: _selectedIndex,
              offset: _direction * (1 - progress),
              opacity: progress,
              scale: 0.95 + (0.05 * progress),
              blur: 8 * (1 - progress),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedPage({
    required int index,
    required double offset,
    required double opacity,
    required double scale,
    required double blur,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return IgnorePointer(
          ignoring: index != _selectedIndex || opacity < 1,
          child: Opacity(
            opacity: opacity,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Transform.translate(
                offset: Offset(width * offset, 0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: KeyedSubtree(
                    key: ValueKey(index),
                    child: widget.children[index],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}