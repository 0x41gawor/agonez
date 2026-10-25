import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../design/design.dart';

/// Bundled preview for an Atlas exercise slug.
///
/// The files are copied from `media/exercises/shrunk`, whose filename stems
/// are the exercise slugs, so the lookup works offline and needs no API field.
String exerciseImageAsset(String slug) => 'assets/exercises/$slug.webp';

/// Square, cover-cropped exercise photo for list rows, framed like the Atlas
/// design's thumbnail. Exercises without a bundled photo keep the frame and
/// show the generic exercise icon.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({required this.slug, this.size = 48, super.key});

  final String slug;
  final double size;

  static const _radius = BorderRadius.all(Radius.circular(9));

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    // Decoded into a box twice the frame, so after cover-cropping the photo's
    // shorter side still has full resolution for crops up to 2:1, which spans
    // every bundled photo. Full-size decodes would hold ~3 MB per row.
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context) * 2)
        .round();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.raised, borderRadius: _radius),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: _radius,
      ),
      child: Image(
        image: ResizeImage(
          AssetImage(exerciseImageAsset(slug)),
          width: decodeSize,
          height: decodeSize,
          policy: ResizeImagePolicy.fit,
        ),
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: wasSynchronouslyLoaded
                  ? Duration.zero
                  : AgonezDurations.standard,
              child: child,
            ),
        errorBuilder: (_, _, _) =>
            Icon(Icons.fitness_center, size: 20, color: colors.textMuted),
      ),
    );
  }
}

/// Offline exercise photo in a fixed-height frame.
///
/// Source photos mix portrait and landscape crops. The photo is contained so
/// no part of the movement is cut off, and a blurred, theme-tinted copy of the
/// same photo fills the rest of the frame. When no asset is bundled for
/// [slug], the widget collapses together with its [margin].
class ExerciseImage extends StatelessWidget {
  const ExerciseImage({
    required this.slug,
    required this.semanticLabel,
    this.height = 220,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final String slug;
  final String semanticLabel;
  final double height;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final image = AssetImage(exerciseImageAsset(slug));
    return Image(
      image: image,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return Padding(
          padding: margin,
          child: Container(
            height: height,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.sunk,
              borderRadius: AgonezRadii.cardBorder,
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: colors.line),
              borderRadius: AgonezRadii.cardBorder,
            ),
            child: AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: wasSynchronouslyLoaded
                  ? Duration.zero
                  : AgonezDurations.standard,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 40,
                      sigmaY: 40,
                      tileMode: TileMode.mirror,
                    ),
                    child: Image(
                      image: image,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  // Washes out blurred equipment near the frame edges.
                  ColoredBox(color: colors.sunk.withValues(alpha: .55)),
                  Center(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
