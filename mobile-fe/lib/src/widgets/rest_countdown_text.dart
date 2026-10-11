import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';

/// A wall-clock countdown. No decremented timer state is persisted or treated
/// as authoritative; rebuilding after suspend/process recovery derives the
/// same value from [endsAt].
class RestCountdownText extends StatefulWidget {
  const RestCountdownText({
    required this.endsAt,
    this.compact = false,
    super.key,
  });

  final DateTime? endsAt;
  final bool compact;

  @override
  State<RestCountdownText> createState() => _RestCountdownTextState();
}

class _RestCountdownTextState extends State<RestCountdownText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant RestCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) _arm();
  }

  void _arm() {
    _ticker?.cancel();
    if (widget.endsAt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endsAt = widget.endsAt;
    if (endsAt == null) return const SizedBox.shrink();
    final strings = AppLocalizations.of(context);
    final delta = endsAt.difference(DateTime.now());
    final over = delta.isNegative;
    final value = over ? delta.abs() : delta;
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    final label = over
        ? strings.timerRestComplete('$minutes:$seconds')
        : '${strings.timerRest} $minutes:$seconds';
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AgonezTypography.monoSmall.copyWith(
        color: over
            ? context.agonezColors.successText
            : context.agonezColors.goldText,
        fontSize: widget.compact ? 10.5 : null,
      ),
    );
  }
}
