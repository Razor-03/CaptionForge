import 'dart:io';

import 'package:caption_forge/Ads/native_ad.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen(
      {super.key, required this.videoPath, required this.subtitle});

  final String videoPath;
  final String subtitle;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  var notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play Video',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoPlayerView(
                key: UniqueKey(),
                url: widget.videoPath,
                dataSourceType: DataSourceType.file,
                subtitleData: widget.subtitle,
              ),
              const SizedBox(height: 16.0),
              OutlinedButton(
                onPressed: () {
                  saveFile(
                      '${path.basenameWithoutExtension(widget.videoPath)}.srt',
                      widget.subtitle);
                },
                child: const Text(
                  'Download Subtitle',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NativeAdWidget(),
    );
  }

  void saveFile(String fileName, String data) async {
    final directory = Directory("/storage/emulated/0/Download");
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(data);
    notificationService.showLocalNotification(
      'Subtitle downloaded successfully',
      'Download/$fileName',
      // file.path,
      'download',
    );
  }
}
