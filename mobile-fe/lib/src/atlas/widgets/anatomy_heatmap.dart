import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design/agonez_colors.dart';

/// The two views embedded in the canonical Agonez anatomy sheet.
enum AnatomyBodyView { front, rear }

/// Offline front/rear anatomy with heat supplied by Atlas `region_id` values.
///
/// The canonical asset is a single sheet containing a very large raster
/// reference underlay and semantic SVG overlays. Only the canonical vector
/// regions are sent to flutter_svg: the underlay is intentionally discarded
/// so decoding stays fast and reliable on lower-memory Android devices.
class AnatomyHeatmap extends StatefulWidget {
  const AnatomyHeatmap({
    super.key,
    required this.regionIntensities,
    this.assetPath = 'assets/anatomy.svg',
    this.height = 280,
    this.heatColor,
    this.baseMuscleColor = const Color(0xFF2B333C),
    this.outlineColor = const Color(0xFF505B66),
    this.frontLabel = 'FRONT',
    this.rearLabel = 'REAR',
    this.semanticsLabel = 'Front and rear anatomy heat map',
    this.showLabels = true,
    this.labelStyle,
    this.gap = 4,
  });

  /// Intensities in the inclusive 0...1 range, keyed by API `region_id`.
  ///
  /// Values outside the range are clamped. The four legacy database aliases
  /// are accepted defensively, although the mobile API normally returns the
  /// canonical SVG identifiers already.
  final Map<String, double> regionIntensities;
  final String assetPath;
  final double height;
  final Color? heatColor;
  final Color baseMuscleColor;
  final Color outlineColor;
  final String frontLabel;
  final String rearLabel;
  final String semanticsLabel;
  final bool showLabels;
  final TextStyle? labelStyle;
  final double gap;

  @override
  State<AnatomyHeatmap> createState() => _AnatomyHeatmapState();
}

class _AnatomyHeatmapState extends State<AnatomyHeatmap> {
  AssetBundle? _bundle;
  String? _source;
  Object? _loadError;
  int _loadGeneration = 0;

  _PreparedAnatomy? _prepared;
  int? _preparedKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _loadAsset(bundle);
    }
  }

  @override
  void didUpdateWidget(covariant AnatomyHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath && _bundle != null) {
      _loadAsset(_bundle!);
    }
    _prepared = null;
    _preparedKey = null;
  }

  Future<void> _loadAsset(AssetBundle bundle) async {
    final generation = ++_loadGeneration;
    setState(() {
      _source = null;
      _loadError = null;
      _prepared = null;
      _preparedKey = null;
    });

    try {
      final source = await bundle.loadString(widget.assetPath);
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _source = source);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _AnatomyFallback(
        height: widget.height,
        semanticsLabel: widget.semanticsLabel,
      );
    }

    final source = _source;
    if (source == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final themeColors = context.agonezColors;
    final heatColor = widget.heatColor ?? themeColors.muscleHeat;
    final key = Object.hash(
      identityHashCode(source),
      Object.hashAllUnordered(
        widget.regionIntensities.entries.map(
          (entry) => Object.hash(entry.key, entry.value),
        ),
      ),
      heatColor,
      widget.baseMuscleColor,
      widget.outlineColor,
    );
    if (_prepared == null || _preparedKey != key) {
      _prepared = _PreparedAnatomy(
        front: AnatomySvgTransformer.transform(
          source,
          view: AnatomyBodyView.front,
          regionIntensities: widget.regionIntensities,
          heatColor: heatColor,
          baseMuscleColor: widget.baseMuscleColor,
          outlineColor: widget.outlineColor,
        ),
        rear: AnatomySvgTransformer.transform(
          source,
          view: AnatomyBodyView.rear,
          regionIntensities: widget.regionIntensities,
          heatColor: heatColor,
          baseMuscleColor: widget.baseMuscleColor,
          outlineColor: widget.outlineColor,
        ),
      );
      _preparedKey = key;
    }

    final labelStyle =
        widget.labelStyle ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
          color: themeColors.textDim,
          fontFamily: 'Geist Mono',
          fontSize: 9,
          letterSpacing: 1.8,
        );
    final prepared = _prepared!;

    return Semantics(
      container: true,
      image: true,
      label: widget.semanticsLabel,
      child: SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AnatomyView(
                svg: prepared.front,
                label: widget.frontLabel,
                showLabel: widget.showLabels,
                labelStyle: labelStyle,
              ),
            ),
            SizedBox(width: widget.gap),
            Expanded(
              child: _AnatomyView(
                svg: prepared.rear,
                label: widget.rearLabel,
                showLabel: widget.showLabels,
                labelStyle: labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnatomyView extends StatelessWidget {
  const _AnatomyView({
    required this.svg,
    required this.label,
    required this.showLabel,
    required this.labelStyle,
  });

  final String svg;
  final String label;
  final bool showLabel;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SvgPicture.string(
            svg,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            excludeFromSemantics: true,
            placeholderBuilder: (_) => const Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.accessibility_new_outlined, size: 28),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(label, style: labelStyle),
        ],
      ],
    );
  }
}

class _AnatomyFallback extends StatelessWidget {
  const _AnatomyFallback({required this.height, required this.semanticsLabel});

  final double height;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: SizedBox(
        height: height,
        child: const Center(
          child: Icon(Icons.accessibility_new_outlined, size: 32),
        ),
      ),
    );
  }
}

class _PreparedAnatomy {
  const _PreparedAnatomy({required this.front, required this.rear});

  final String front;
  final String rear;
}

/// Pure canonical-SVG transformer kept public for focused regression tests.
abstract final class AnatomySvgTransformer {
  static const _viewBoxes = <AnatomyBodyView, String>{
    AnatomyBodyView.front: '20 15 495 990',
    AnatomyBodyView.rear: '505 15 530 990',
  };

  static const dbToSvgRegion = <String, String>{
    'deltoid_anterior': 'anterior_deltoid',
    'deltoid_lateral': 'lateral_deltoid',
    'deltoid_posterior': 'posterior_deltoid',
    'rotator_cuffs': 'rotator_cuff',
  };

  static final _tokenPattern = RegExp(
    r'<g\b[^>]*>|</g\s*>|<(?:path|rect|circle|ellipse|polygon|polyline)\b[^>]*?/?>',
    caseSensitive: false,
    multiLine: true,
  );

  static String transform(
    String source, {
    required AnatomyBodyView view,
    required Map<String, double> regionIntensities,
    required Color heatColor,
    required Color baseMuscleColor,
    required Color outlineColor,
  }) {
    final cleanedSource = _stripNonRenderingMarkup(source);
    final intensities = _normalizeIntensities(regionIntensities);
    final targetView = view.name;
    final output = StringBuffer();
    final groups = <_SemanticGroup?>[];
    var cursor = 0;

    for (final match in _tokenPattern.allMatches(cleanedSource)) {
      output.write(cleanedSource.substring(cursor, match.start));
      final token = match.group(0)!;
      final normalized = token.toLowerCase();

      if (normalized.startsWith('</g')) {
        if (groups.isNotEmpty) groups.removeLast();
        output.write(token);
      } else if (normalized.startsWith('<g')) {
        final parent = groups.isEmpty ? null : groups.last;
        final type = _attribute(token, 'data-type');
        final id = _attribute(token, 'id');
        final classes = _classes(token);
        final semantic = type == null
            ? parent
            : _SemanticGroup(
                id: id ?? '',
                type: type,
                isDeep: classes.contains('deep'),
              );
        output.write(token);
        if (!normalized.trimRight().endsWith('/>')) groups.add(semantic);
      } else {
        final tokenView = _attribute(token, 'data-view');
        if (tokenView != null && tokenView != targetView) {
          cursor = match.end;
          continue;
        }

        final semantic = groups.isEmpty ? null : groups.last;
        if (semantic?.type == 'joint') {
          cursor = match.end;
          continue;
        }

        if (semantic?.type == 'muscle' && _classes(token).contains('region')) {
          final intensity = intensities[semantic!.id] ?? 0;
          output.write(
            _paintRegion(
              token,
              intensity: intensity,
              isDeep: semantic.isDeep,
              heatColor: heatColor,
              baseMuscleColor: baseMuscleColor,
              outlineColor: outlineColor,
            ),
          );
        } else {
          output.write(token);
        }
      }
      cursor = match.end;
    }
    output.write(cleanedSource.substring(cursor));

    return _setRootViewBox(output.toString(), _viewBoxes[view]!);
  }

  static Map<String, double> _normalizeIntensities(Map<String, double> source) {
    final normalized = <String, double>{};
    for (final entry in source.entries) {
      final id = dbToSvgRegion[entry.key] ?? entry.key;
      final value = entry.value.isFinite
          ? entry.value.clamp(0.0, 1.0).toDouble()
          : 0.0;
      normalized.update(
        id,
        (current) => math.max(current, value),
        ifAbsent: () => value,
      );
    }
    return normalized;
  }

  static String _stripNonRenderingMarkup(String source) {
    var cleaned = source;
    for (final element in <String>[
      'metadata',
      'style',
      'defs',
      'title',
      'desc',
      'text',
      'script',
      'foreignObject',
      'filter',
    ]) {
      cleaned = cleaned.replaceAll(
        RegExp(
          '<$element\\b[^>]*>[\\s\\S]*?</$element\\s*>',
          caseSensitive: false,
        ),
        '',
      );
    }
    cleaned = cleaned.replaceAll(
      RegExp(r'<image\b[\s\S]*?/\s*>', caseSensitive: false),
      '',
    );
    return cleaned.replaceAll(
      RegExp(
        r'<(?:sodipodi:namedview|inkscape:path-effect)\b[^>]*/\s*>',
        caseSensitive: false,
      ),
      '',
    );
  }

  static String _paintRegion(
    String token, {
    required double intensity,
    required bool isDeep,
    required Color heatColor,
    required Color baseMuscleColor,
    required Color outlineColor,
  }) {
    final visible = intensity > 0.02;
    final mix = visible
        ? (0.12 + 0.88 * math.pow(intensity, 0.75)).toDouble()
        : 0.0;
    final fill = Color.lerp(baseMuscleColor, heatColor, mix)!;
    final opacity = visible ? (isDeep ? 0.58 : 0.94) : (isDeep ? 0.20 : 0.48);

    var painted = _setAttribute(token, 'fill', _hex(fill));
    painted = _setStyleProperty(painted, 'fill', _hex(fill));
    painted = _setAttribute(painted, 'stroke', _hex(outlineColor));
    painted = _setStyleProperty(painted, 'stroke', _hex(outlineColor));
    painted = _setAttribute(painted, 'opacity', opacity.toStringAsFixed(2));
    return _setStyleProperty(painted, 'opacity', opacity.toStringAsFixed(2));
  }

  static String _setRootViewBox(String source, String viewBox) {
    final root = RegExp(r'<svg\b[^>]*>', caseSensitive: false, multiLine: true);
    return source.replaceFirstMapped(root, (match) {
      var tag = match.group(0)!;
      tag = _removeAttribute(tag, 'width');
      tag = _removeAttribute(tag, 'height');
      tag = _setAttribute(tag, 'viewBox', viewBox);
      return _setAttribute(tag, 'preserveAspectRatio', 'xMidYMid meet');
    });
  }

  static Set<String> _classes(String token) {
    final value = _attribute(token, 'class');
    if (value == null || value.isEmpty) return const <String>{};
    return value.split(RegExp(r'\s+')).toSet();
  }

  static String? _attribute(String token, String name) {
    final expression = RegExp(
      "\\b${RegExp.escape(name)}\\s*=\\s*([\"'])(.*?)\\1",
      caseSensitive: false,
      dotAll: true,
    );
    return expression.firstMatch(token)?.group(2);
  }

  static String _removeAttribute(String token, String name) {
    final expression = RegExp(
      "\\s+${RegExp.escape(name)}\\s*=\\s*([\"']).*?\\1",
      caseSensitive: false,
      dotAll: true,
    );
    return token.replaceFirst(expression, '');
  }

  static String _setAttribute(String token, String name, String value) {
    final expression = RegExp(
      "\\b${RegExp.escape(name)}\\s*=\\s*([\"']).*?\\1",
      caseSensitive: false,
      dotAll: true,
    );
    if (expression.hasMatch(token)) {
      return token.replaceFirst(expression, '$name="$value"');
    }
    return token.replaceFirst(
      RegExp(r'\s*/?>$'),
      ' $name="$value"${token.trimRight().endsWith('/>') ? ' />' : '>'}',
    );
  }

  static String _setStyleProperty(String token, String property, String value) {
    final styleExpression = RegExp(
      r'''\bstyle\s*=\s*(["'])(.*?)\1''',
      caseSensitive: false,
      dotAll: true,
    );
    final styleMatch = styleExpression.firstMatch(token);
    if (styleMatch == null) {
      return _setAttribute(token, 'style', '$property:$value');
    }

    final declarations =
        styleMatch
            .group(2)!
            .split(';')
            .where((part) => part.trim().isNotEmpty)
            .where(
              (part) => !part.trimLeft().toLowerCase().startsWith('$property:'),
            )
            .toList(growable: true)
          ..add('$property:$value');
    return token.replaceRange(
      styleMatch.start,
      styleMatch.end,
      'style="${declarations.join(';')}"',
    );
  }

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _SemanticGroup {
  const _SemanticGroup({
    required this.id,
    required this.type,
    required this.isDeep,
  });

  final String id;
  final String type;
  final bool isDeep;
}
