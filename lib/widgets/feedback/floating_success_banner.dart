import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// A non-blocking, top-centred success confirmation for completed actions.
///
/// Calls made while the banner is visible replace the current banner instead
/// of adding another overlay entry.
class FloatingSuccessBanner extends StatefulWidget {
  const FloatingSuccessBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final VoidCallback onDismissed;

  static OverlayEntry? _entry;
  static _FloatingSuccessBannerState? _currentState;
  static Timer? _replacementTimer;
  static int _requestId = 0;

  static void showOrderSaved(BuildContext context) {
    show(
      context,
      title: 'Order Saved Successfully',
      message: "Order has been added to today's sales.",
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final requestId = ++_requestId;

    void insertBanner() {
      if (requestId != _requestId || !overlay.mounted) return;

      final key = GlobalKey<_FloatingSuccessBannerState>();
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimens.topBarHeight + 16),
              child: IgnorePointer(
                child: Center(
                  child: FloatingSuccessBanner(
                    key: key,
                    title: title,
                    message: message,
                    onDismissed: () {
                      entry.remove();
                      if (identical(_entry, entry)) {
                        _entry = null;
                        _currentState = null;
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      _entry = entry;
      overlay.insert(entry);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (requestId == _requestId) _currentState = key.currentState;
      });
    }

    _replacementTimer?.cancel();
    if (_entry == null) {
      insertBanner();
      return;
    }

    final currentState = _currentState;
    if (currentState == null) {
      _entry?.remove();
      _entry = null;
      insertBanner();
      return;
    }

    currentState.dismiss();
    _replacementTimer = Timer(const Duration(milliseconds: 240), insertBanner);
  }

  @override
  State<FloatingSuccessBanner> createState() => _FloatingSuccessBannerState();
}

class _FloatingSuccessBannerState extends State<FloatingSuccessBanner>
    with SingleTickerProviderStateMixin {
  static const _entryDuration = Duration(milliseconds: 250);
  static const _exitDuration = Duration(milliseconds: 220);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _visibilityTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _entryDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _visibilityTimer = Timer(const Duration(seconds: 2), dismiss);
  }

  void dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _visibilityTimer?.cancel();
    _controller.reverseDuration = _exitDuration;
    _controller.reverse().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.message,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
