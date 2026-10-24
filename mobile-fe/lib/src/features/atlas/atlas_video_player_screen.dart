import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import 'atlas_videos.dart';

/// Streams an exercise's YouTube videos through the official IFrame player.
///
/// The player stays pinned above the video list because it claims vertical
/// drags (swipe up for fullscreen), which would fight a surrounding scroll
/// view. Rotating to landscape keeps the same widget tree, so playback is not
/// restarted; the player package also switches to fullscreen while playing.
class AtlasVideoPlayerScreen extends StatefulWidget {
  const AtlasVideoPlayerScreen({
    required this.title,
    required this.videos,
    this.initialIndex = 0,
    super.key,
  });

  final String title;
  final List<AtlasVideo> videos;
  final int initialIndex;

  @override
  State<AtlasVideoPlayerScreen> createState() => _AtlasVideoPlayerScreenState();
}

class _AtlasVideoPlayerScreenState extends State<AtlasVideoPlayerScreen> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _valueSubscription;
  bool _fullscreen = false;
  late int _index = widget.initialIndex;

  /// Null while the connection check is running.
  bool? _online;

  AtlasVideo get _current => widget.videos[_index];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() => _online = null);
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    final online = results.any((result) => result != ConnectivityResult.none);
    setState(() {
      _online = online;
      if (online && _controller == null) {
        final language = Localizations.localeOf(context).languageCode;
        _controller = YoutubePlayerController(
          // The player shows this video's thumbnail while the WebView loads.
          key: _current.id,
          params: YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true,
            // Auto-generated captions are noisy; the CC button still works.
            enableCaption: false,
            interfaceLanguage: language,
            captionLanguage: language,
          ),
        )..loadVideoById(videoId: _current.id);
        _valueSubscription = _controller!.listen(_onPlayerValue);
      }
    });
  }

  /// The player package keeps fullscreen inside Flutter and leaves device
  /// orientation alone, so fullscreen would stay portrait whenever auto-rotate
  /// is off. Like the YouTube app, turn the screen while fullscreen.
  void _onPlayerValue(YoutubePlayerValue value) {
    final fullscreen = value.fullScreenOption.enabled;
    if (fullscreen == _fullscreen) return;
    _fullscreen = fullscreen;
    _applyFullscreen(fullscreen);
  }

  static void _applyFullscreen(bool fullscreen) {
    SystemChrome.setPreferredOrientations(
      fullscreen
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [],
    );
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _controller?.loadVideoById(videoId: _current.id);
  }

  Future<void> _openInYoutube() async {
    await _controller?.pauseVideo();
    await launchUrl(_current.watchUri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    if (_fullscreen) _applyFullscreen(false);
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      backgroundColor: landscape ? Colors.black : null,
      appBar: landscape
          ? null
          : AppBar(
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: l10n.atlasVideoOpenInYoutube,
                  onPressed: _openInYoutube,
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
      body: SafeArea(
        top: landscape,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: landscape
                        ? MediaQuery.sizeOf(context).height
                        : double.infinity,
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildPlayer(l10n),
                  ),
                ),
              ),
            ),
            Expanded(
              child: landscape
                  ? const SizedBox.shrink()
                  : _VideoList(
                      videos: widget.videos,
                      selected: _index,
                      onSelected: _select,
                      onOpenInYoutube: _openInYoutube,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(AppLocalizations l10n) {
    if (_online == false) {
      return _PlayerMessage(
        icon: Icons.cloud_off_outlined,
        message: l10n.atlasVideoOffline,
        actionLabel: l10n.commonRetry,
        onAction: _connect,
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        YoutubePlayer(controller: controller, backgroundColor: Colors.black),
        YoutubeValueBuilder(
          controller: controller,
          buildWhen: (previous, next) => previous.hasError != next.hasError,
          builder: (context, value) => value.hasError
              ? _PlayerMessage(
                  icon: Icons.videocam_off_outlined,
                  message: l10n.atlasVideoUnavailable,
                  actionLabel: l10n.atlasVideoOpenInYoutube,
                  onAction: _openInYoutube,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _VideoList extends StatelessWidget {
  const _VideoList({
    required this.videos,
    required this.selected,
    required this.onSelected,
    required this.onOpenInYoutube,
  });

  final List<AtlasVideo> videos;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onOpenInYoutube;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        if (videos.length > 1) ...[
          AgonezEyebrow(l10n.atlasVideos, color: colors.goldText),
          const SizedBox(height: AgonezSpacing.md),
          for (var index = 0; index < videos.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: AgonezSpacing.md),
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: AgonezRadii.cardBorder,
                child: Row(
                  children: [
                    SizedBox(
                      width: 136,
                      child: AtlasVideoCard(
                        video: videos[index],
                        index: index,
                        count: videos.length,
                        selected: index == selected,
                        onTap: () => onSelected(index),
                      ),
                    ),
                    const SizedBox(width: AgonezSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.atlasVideoLabel(index + 1),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (index == selected) ...[
                            const SizedBox(height: 6),
                            AgonezTag(
                              label: l10n.atlasVideoNowPlaying,
                              color: colors.goldText,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AgonezSpacing.sm),
        ],
        OutlinedButton.icon(
          onPressed: onOpenInYoutube,
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.atlasVideoOpenInYoutube),
        ),
      ],
    );
  }
}

class _PlayerMessage extends StatelessWidget {
  const _PlayerMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AgonezSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 30),
              const SizedBox(height: AgonezSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: AgonezSpacing.md),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
