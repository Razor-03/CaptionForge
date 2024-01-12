import 'dart:io';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play Video',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showDownloadSheet,
        child: const Icon(Icons.download),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: VideoPlayerView(
            key: UniqueKey(),
            url: widget.videoPath,
            dataSourceType: DataSourceType.file,
            subtitleData: widget.subtitle,
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(adSize: AdSize.banner),
    );
  }

  void saveFile(String fileName, String data) async {
    final directory = Directory("/storage/emulated/0/CaptionForge");
    if (!directory.existsSync()) {
      directory.createSync();
    }
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(data);
    notificationService.showLocalNotification(
      'Subtitle Saved Successfully',
      'CaptionForge/$fileName',
      null,
    );
  }

  void saveVideo(String videoPath, String data) async {
    final tempDir = await getTemporaryDirectory();
    final directory = Directory("/storage/emulated/0/CaptionForge");
    if (!directory.existsSync()) {
      directory.createSync();
    }
    final outputVideo = File('${directory.path}/${path.basename(videoPath)}');
    if (outputVideo.existsSync()) {
      outputVideo.deleteSync();
    }
    final subtitleFile = File('${tempDir.path}/subtitle.srt');
    await subtitleFile.writeAsString(data);
    final flutterFFmpeg = FlutterFFmpeg();
    await flutterFFmpeg.execute(
        '-i $videoPath -i ${subtitleFile.path} -c copy -c:s mov_text -metadata:s:s:0 language=uk ${outputVideo.path}');
    subtitleFile.deleteSync();
    notificationService.showLocalNotification(
      'Video Saved Successfully',
      'CaptionForge/${path.basename(videoPath)}',
      null,
    );
  }

  void showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        width: double.infinity,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ListTile(
              leading: const Icon(Icons.subtitles),
              title: const Text('Export Subtitle'),
              onTap: () {
                saveFile(
                    '${path.basenameWithoutExtension(widget.videoPath)}.srt',
                    widget.subtitle);
                Navigator.pop(context);
              },
            ),
            Divider(thickness: 4, color: Theme.of(context).colorScheme.secondaryContainer),
            ListTile(
              leading: const Icon(Icons.video_collection),
              title: const Text('Export Video with Subtitle'),
              onTap: () {
                saveVideo(widget.videoPath, widget.subtitle);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
