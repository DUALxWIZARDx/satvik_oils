import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExpandableCardModal
//
// A reusable widget that gives any card a Hero-based card-to-modal transition
// matching the Framer-Motion layoutId pattern used in the React reference.
//
// Usage
// ─────
// Wrap the card you already have:
//
//   ExpandableCardModal(
//     heroTag: 'pricing-groundnut',        // globally unique string
//     tintColor: const Color(0xFFCDA36A),
//     borderRadius: BorderRadius.circular(16),
//     collapsedChild: YourCollapsedCardContent(),
//     expandedChild: YourExpandedModalContent(),
//   )
//
// The collapsed card sits exactly where it normally would.
// Tapping it flies into a centred modal overlay via Hero.
// Tapping the dimmed backdrop or the × button reverses the Hero back.
//
// Rules
// ─────
// • heroTag must be globally unique across the widget tree.
// • No providers / repositories / models are imported or touched here.
// • All existing content passed in via collapsedChild / expandedChild is
//   rendered without modification.
// ─────────────────────────────────────────────────────────────────────────────

class ExpandableCardModal extends StatelessWidget {
  const ExpandableCardModal({
    super.key,
    required this.heroTag,
    required this.tintColor,
    required this.collapsedChild,
    required this.expandedChild,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.collapsedDecoration,
  });

  /// Globally unique tag — drives the Hero shared-element transition.
  final String heroTag;

  /// Tint used for the modal's top accent strip and border glow.
  final Color tintColor;

  /// The widget shown in the grid / list (collapsed state).
  final Widget collapsedChild;

  /// The widget shown inside the expanded modal (scrollable content area).
  final Widget expandedChild;

  final BorderRadius borderRadius;

  /// Decoration applied to the collapsed card surface.
  /// If null a default surface decoration is used.
  final BoxDecoration? collapsedDecoration;

  // ── Animation constants ───────────────────────────────────────────────────
  static const Duration _duration = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final decoration = collapsedDecoration ??
        BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: tintColor.withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: tintColor.withValues(alpha: 0.06),
              blurRadius: 20,
            ),
          ],
        );

    return Hero(
      tag: heroTag,
      // createRectTween controls the flight path. The default RectTween gives
      // a straight-line morph which is exactly what we want — no bounce.
      flightShuttleBuilder: _shuttleBuilder,
      child: Material(
        // Material wrapper is required so InkWell ripples clip to the hero
        // shape and the Hero flight doesn't flash white.
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          splashColor: tintColor.withValues(alpha: 0.10),
          highlightColor: tintColor.withValues(alpha: 0.05),
          onTap: () => _openModal(context),
          child: DecoratedBox(
            decoration: decoration,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: collapsedChild,
            ),
          ),
        ),
      ),
    );
  }

  // ── Flight shuttle — what Hero renders DURING the transition ──────────────
  // We render the collapsed card surface as the shuttle so the shape morphs
  // smoothly without the contents flickering.
  Widget _shuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        // Interpolate the border radius from collapsed (16) to modal (20).
        final radius = BorderRadiusTween(
          begin: borderRadius,
          end: const BorderRadius.all(Radius.circular(20)),
        ).evaluate(CurvedAnimation(parent: animation, curve: _curve))!;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: tintColor.withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          child: ClipRRect(borderRadius: radius, child: collapsedChild),
        );
      },
    );
  }

  // ── Open modal ────────────────────────────────────────────────────────────
  void _openModal(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false, // we handle dismiss ourselves for animation
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent, // backdrop handled inside the dialog
      transitionDuration: _duration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _ModalPage(
          heroTag: heroTag,
          tintColor: tintColor,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          expandedChild: expandedChild,
          animation: animation,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ModalPage
//
// The full overlay: blurred backdrop + Hero'd modal card + close button.
// ─────────────────────────────────────────────────────────────────────────────

class _ModalPage extends StatelessWidget {
  const _ModalPage({
    required this.heroTag,
    required this.tintColor,
    required this.borderRadius,
    required this.expandedChild,
    required this.animation,
    required this.onClose,
  });

  final String heroTag;
  final Color tintColor;
  final BorderRadius borderRadius;
  final Widget expandedChild;
  final Animation<double> animation;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    // Modal dimensions — 80 % screen height, max 680 px wide.
    final modalMaxHeight = screenSize.height * 0.80;
    const modalMaxWidth = 680.0;

    return Stack(
      children: [
        // ── Backdrop: blur + dark tint ──────────────────────────────────
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
          child: GestureDetector(
            onTap: onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),

        // ── Modal card — Hero destination ──────────────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Hero(
              tag: heroTag,
              child: Material(
                color: Colors.transparent,
                borderRadius: borderRadius,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: modalMaxWidth,
                    maxHeight: modalMaxHeight,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: tintColor.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: tintColor.withValues(alpha: 0.08),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: Stack(
                      children: [
                        // Scrollable expanded content fades + slides in after
                        // the Hero shape transition is mostly complete.
                        _DelayedContent(
                          animation: animation,
                          child: expandedChild,
                        ),

                        // ── Close button ──────────────────────────────
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _CloseButton(onTap: onClose),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DelayedContent
//
// Fades + slides the expanded content in after the Hero flight is mostly done.
// ─────────────────────────────────────────────────────────────────────────────

class _DelayedContent extends StatelessWidget {
  const _DelayedContent({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Content starts appearing from 50 % of the transition onward.
    final delayed = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: delayed,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(delayed),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CloseButton
//
// Circular close × button, top-right corner of the modal.
// Matches the app's premium dark aesthetic.
// ─────────────────────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
