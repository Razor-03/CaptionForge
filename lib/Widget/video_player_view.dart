import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({
    super.key,
    required this.url,
    required this.dataSourceType,
    this.subtitleData,
  });

  final String url;

  final DataSourceType dataSourceType;

  final String? subtitleData;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _videoPlayerController;

  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    switch (widget.dataSourceType) {
      case DataSourceType.asset:
        _videoPlayerController = VideoPlayerController.asset(widget.url);
        break;
      case DataSourceType.network:
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(widget.url));
        break;
      case DataSourceType.file:
        _videoPlayerController = VideoPlayerController.file(File(widget.url));
        break;
      case DataSourceType.contentUri:
        _videoPlayerController =
            VideoPlayerController.contentUri(Uri.parse(widget.url));
        break;
    }

    _videoPlayerController.initialize().then(
          (_) => setState(
            () => _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController,
              // aspectRatio: 16 / 9,
              zoomAndPan: true,
              subtitle: widget.subtitleData != null
                  ? Subtitles(parseSRT(widget.subtitleData!))
                  : null,
            ),
          ),
        );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
        
      ),
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? AspectRatio(
              aspectRatio:
                  _chewieController!.videoPlayerController.value.aspectRatio,
              child: Chewie(
                controller: _chewieController!,
              ),
            )
          : Container(),
    );
  }

  List<Subtitle> parseSRT(String srtData) {
    List<Subtitle> subtitles = [];
    List<String> blocks = srtData.split('\n\n');

    for (String block in blocks) {
      List<String> lines = block.split('\n');
      if (lines.length >= 3) {
        int index = int.tryParse(lines[0]) ?? 0;

        RegExp timeRegExp = RegExp(r'(\d+:\d+:\d+,\d+) --> (\d+:\d+:\d+,\d+)');
        Iterable<Match> matches = timeRegExp.allMatches(lines[1]);

        if (matches.isNotEmpty) {
          String startTime = matches.first.group(1) ?? '00:00:00,000';
          String endTime = matches.first.group(2) ?? '00:00:00,000';

          Duration start = parseDuration(startTime);
          Duration end = parseDuration(endTime);

          String text = lines.sublist(2).join('\n').trim();

          subtitles.add(
            Subtitle(
              index: index,
              start: start,
              end: end,
              text: text,
            ),
          );
        }
      }
    }
    return subtitles;
  }

  Duration parseDuration(String time) {
    List<String> parts = time.split(':');
    List<String> secondsAndMilliseconds = parts[2].split(',');

    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(secondsAndMilliseconds[0]);
    int milliseconds = int.parse(secondsAndMilliseconds[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
