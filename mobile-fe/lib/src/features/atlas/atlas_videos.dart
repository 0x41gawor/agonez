import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import 'atlas_video_player_screen.dart';

/// A YouTube demonstration video referenced by an Atlas exercise.
@immutable
class AtlasVideo {
  const AtlasVideo(this.id);

  /// The 11-character YouTube video id.
  final String id;

  String get thumbnailUrl => YoutubePlayerController.getThumbnail(
    videoId: id,
    quality: ThumbnailQuality.high,
  );

  Uri get watchUri => Uri.https('www.youtube.com', '/watch', {'v': id});

  /// Parses the API's `video_links`, skipping non-YouTube URLs and repeats.
  ///
  /// The backend canonicalizes links when they are added, but the article
  /// stays usable if an older or hand-edited record holds something else.
  static List<AtlasVideo> fromLinks(Iterable<String> links) {
    final ids = <String>{};
    for (final link in links) {
      final id = YoutubePlayerController.convertUrlToId(link);
      if (id != null) ids.add(id);
    }
    return ids.map(AtlasVideo.new).toList(growable: false);
  }

  @override
  bool operator ==(Object other) => other is AtlasVideo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Opens the full-screen player above every navigation shell, so the same
/// route works from the Atlas article and from the active workout.
Future<void> openAtlasVideoPlayer(
  BuildContext context, {
  required String title,
  required List<AtlasVideo> videos,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => AtlasVideoPlayerScreen(
        title: title,
        videos: videos,
        initialIndex: initialIndex,
      ),
    ),
  );
}

/// The article's video section: the first video as a large card and the
/// rest in a two-column grid underneath.
class AtlasVideoGallery extends StatelessWidget {
  const AtlasVideoGallery({
    required this.videos,
    required this.onOpen,
    super.key,
  });

  final List<AtlasVideo> videos;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (videos.isEmpty) {
      return Text(
        l10n.commonNotAvailableYet,
        style: TextStyle(color: context.agonezColors.textMuted),
      );
    }
    Widget card(int index) => AtlasVideoCard(
      video: videos[index],
      index: index,
      count: videos.length,
      large: index == 0,
      onTap: () => onOpen(index),
    );

    return Column(
      children: [
        card(0),
        for (var start = 1; start < videos.length; start += 2)
          Padding(
            padding: const EdgeInsets.only(top: AgonezSpacing.md),
            child: Row(
              children: [
                Expanded(child: card(start)),
                const SizedBox(width: AgonezSpacing.md),
                Expanded(
                  child: start + 1 < videos.length
                      ? card(start + 1)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A 16:9 YouTube thumbnail with a play affordance.
class AtlasVideoCard extends StatelessWidget {
  const AtlasVideoCard({
    required this.video,
    required this.index,
    required this.count,
    required this.onTap,
    this.large = false,
    this.selected = false,
    super.key,
  });

  final AtlasVideo video;
  final int index;
  final int count;
  final VoidCallback onTap;
  final bool large;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.atlasVideoPlayA11y(index + 1, count),
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: colors.sunk,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: AgonezRadii.cardBorder,
            side: BorderSide(
              color: selected ? colors.gold : colors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // hqdefault is 4:3 with letterbox bars; cover crops them.
                // Thumbnails usually carry their own title text, so the card
                // adds only a play button and leaves numbering to semantics.
                Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                Center(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xB3000000),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(large ? 12 : 7),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: large ? 34 : 22,
                      ),
                    ),
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
