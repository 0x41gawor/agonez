import 'package:flutter/material.dart';

import 'agonez_colors.dart';
import 'agonez_tokens.dart';
import 'agonez_typography.dart';

class AgonezPanel extends StatelessWidget {
  const AgonezPanel({
    required this.child,
    this.padding = AgonezInsets.card,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AgonezRadii.cardBorder,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadiusGeometry borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final panel = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.panel,
        border: Border.all(color: borderColor ?? colors.line),
        borderRadius: borderRadius,
      ),
      child: child,
    );
    if (semanticLabel == null) return panel;
    return Semantics(container: true, label: semanticLabel, child: panel);
  }
}

class AgonezEyebrow extends StatelessWidget {
  const AgonezEyebrow(
    this.text, {
    this.color,
    this.uppercase = true,
    this.maxLines,
    super.key,
  });

  final String text;
  final Color? color;
  final bool uppercase;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      uppercase ? text.toUpperCase() : text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: AgonezTypography.eyebrow.copyWith(
        color: color ?? context.agonezColors.textMuted,
      ),
    );
  }
}

class AgonezSheetHandle extends StatelessWidget {
  const AgonezSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: false,
      excludeSemantics: true,
      child: Center(
        child: Container(
          width: 38,
          height: 5,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: context.agonezColors.controlStrong,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class AgonezPrimaryButton extends StatelessWidget {
  const AgonezPrimaryButton({
    required this.label,
    required this.onPressed,
    this.supportingText,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final String? supportingText;
  final Widget? icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: AgonezSpacing.sm)],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (supportingText != null)
                Text(
                  supportingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AgonezTypography.buttonSupporting,
                ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: SizedBox(
        width: double.infinity,
        height: AgonezSizes.primaryButtonHeight,
        child: FilledButton(onPressed: onPressed, child: content),
      ),
    );
  }
}

class AgonezTag extends StatelessWidget {
  const AgonezTag({
    required this.label,
    this.color,
    this.icon,
    this.uppercase = true,
    super.key,
  });

  final String label;
  final Color? color;
  final Widget? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.agonezColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: effectiveColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: AgonezTypography.eyebrow.copyWith(
              color: effectiveColor,
              fontSize: 9.5,
              letterSpacing: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}
