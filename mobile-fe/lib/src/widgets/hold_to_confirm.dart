import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';

enum HoldToConfirmTone { neutral, caution }

/// A deliberate-action button whose fill reaches the end only after a
/// continuous press.
///
/// Its animation state is owned here, rather than by timer/sync providers, so
/// unrelated parent rebuilds do not interrupt an in-progress hold.
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    required this.label,
    required this.onConfirmed,
    required this.duration,
    this.durationLabel,
    this.semanticLabel,
    this.semanticHint,
    this.accessibilityActionLabel,
    this.tone = HoldToConfirmTone.caution,
    this.enabled = true,
    this.enableHaptics = true,
    this.focusNode,
    super.key,
  });

  final String label;
  final VoidCallback onConfirmed;
  final Duration duration;

  /// Localized duration text, for example `hold 1.2 s` or `przytrzymaj 1,2 s`.
  /// When omitted, only the locale-independent numeric duration is shown.
  final String? durationLabel;
  final String? semanticLabel;
  final String? semanticHint;
  final String? accessibilityActionLabel;
  final HoldToConfirmTone tone;
  final bool enabled;
  final bool enableHaptics;
  final FocusNode? focusNode;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _holdTimer;
  bool _isHolding = false;
  bool _completedForCurrentPress = false;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant HoldToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (!widget.enabled && oldWidget.enabled) {
      _cancelHold(immediate: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !_isHolding ||
        _completedForCurrentPress) {
      return;
    }
    _completeHold();
  }

  void _completeHold() {
    if (!_isHolding || _completedForCurrentPress || !widget.enabled) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    _completedForCurrentPress = true;
    _isHolding = false;
    _controller.value = 1;
    _invokeConfirmation();
  }

  void _startHold() {
    if (!widget.enabled || _isHolding || _completedForCurrentPress) return;
    _controller.stop();
    _controller.value = 0;
    _isHolding = true;
    _controller.forward();
    _holdTimer?.cancel();
    _holdTimer = Timer(widget.duration, _completeHold);
  }

  void _releaseHold() {
    if (!_isHolding && !_completedForCurrentPress) return;
    _isHolding = false;
    _completedForCurrentPress = false;
    _holdTimer?.cancel();
    _holdTimer = null;
    _resetProgress();
  }

  void _cancelHold({bool immediate = false}) {
    _isHolding = false;
    _completedForCurrentPress = false;
    _holdTimer?.cancel();
    _holdTimer = null;
    _controller.stop();
    if (immediate) {
      _controller.value = 0;
    } else {
      _resetProgress();
    }
  }

  void _resetProgress() {
    _controller.animateBack(
      0,
      duration: _disableAnimations ? Duration.zero : AgonezDurations.holdReset,
      curve: Curves.linear,
    );
  }

  void _invokeConfirmation() {
    if (!widget.enabled) return;
    if (widget.enableHaptics) HapticFeedback.heavyImpact();
    widget.onConfirmed();
  }

  void _confirmFromAccessibility() {
    if (!widget.enabled || _completedForCurrentPress) return;
    _controller.stop();
    _controller.value = 1;
    _isHolding = false;
    _completedForCurrentPress = true;
    _invokeConfirmation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _completedForCurrentPress = false;
      _resetProgress();
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isActivationKey =
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (!isActivationKey || !widget.enabled) return KeyEventResult.ignored;

    if (event is KeyDownEvent && event is! KeyRepeatEvent) {
      _startHold();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _releaseHold();
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final isNeutral = widget.tone == HoldToConfirmTone.neutral;
    final borderColor = isNeutral ? colors.controlStrong : colors.caution;
    final foregroundColor = isNeutral ? colors.textPrimary : colors.caution;
    final fillColor = isNeutral
        ? colors.textPrimary.withValues(alpha: 0.14)
        : colors.caution.withValues(alpha: 0.28);
    final durationLabel =
        widget.durationLabel ??
        '${(widget.duration.inMilliseconds / 1000).toStringAsFixed(1)} s';
    final accessibilityAction = CustomSemanticsAction(
      label: widget.accessibilityActionLabel ?? widget.label,
    );

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Semantics(
        container: true,
        button: true,
        enabled: widget.enabled,
        label: widget.semanticLabel ?? widget.label,
        hint: widget.semanticHint,
        onLongPress: widget.enabled ? _confirmFromAccessibility : null,
        customSemanticsActions: widget.enabled
            ? <CustomSemanticsAction, VoidCallback>{
                accessibilityAction: _confirmFromAccessibility,
              }
            : const <CustomSemanticsAction, VoidCallback>{},
        excludeSemantics: true,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.42,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.enabled ? (_) => _startHold() : null,
            onPointerUp: widget.enabled ? (_) => _releaseHold() : null,
            onPointerCancel: widget.enabled ? (_) => _releaseHold() : null,
            child: SizedBox(
              width: double.infinity,
              height: AgonezSizes.primaryButtonHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: AgonezRadii.cardBorder,
                ),
                child: ClipRRect(
                  borderRadius: AgonezRadii.cardBorder,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _controller.value,
                              heightFactor: 1,
                              child: ColoredBox(color: fillColor),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AgonezSpacing.xl,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AgonezTypography.button.copyWith(
                                  color: foregroundColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AgonezSpacing.sm),
                            Text(
                              durationLabel,
                              maxLines: 1,
                              style: AgonezTypography.monoSmall.copyWith(
                                color: foregroundColor.withValues(alpha: 0.76),
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
          ),
        ),
      ),
    );
  }
}
