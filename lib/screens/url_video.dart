import 'dart:async';
import 'dart:io';
import 'package:caption_forge/Ads/app_open_ad.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Ads/native_ad.dart';
import 'package:caption_forge/Ads/reward_ad.dart';
import 'package:caption_forge/lang.dart';
import 'package:circular_seek_bar/circular_seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:caption_forge/screens/device_video.dart';

class UrlVideo extends StatefulWidget {
  const UrlVideo({super.key});

  @override
  State<UrlVideo> createState() => _UrlVideoState();
}

class _UrlVideoState extends State<UrlVideo> {
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  var client = http.Client();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Video'),
      ),
      body: Center(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: "Enter Video URL",
                labelStyle:
                    TextStyle(color: Color.fromARGB(255, 227, 227, 227)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16,
            ),
            child: ElevatedButton(
              onPressed: () async {
                await _downloadVideoFromUrl(urlController.text);
              },
              child: const Text('Upload From URL'),
            ),
          ),
        ],
      )),
    );
  }

  Future<void> _downloadVideoFromUrl(String videoUrl) async {
    try {
      // var response = await http.get(Uri.parse(videoUrl));
      var response = await client.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final videoFileName = path.basename(videoUrl);
        final videoFilePath = path.join(directory.path, videoFileName);
        debugPrint('Video file path: $videoFilePath');

        File tempVideoFile = File(videoFilePath);
        await tempVideoFile.writeAsBytes(response.bodyBytes);

        setState(() {
          tempVideoFile = tempVideoFile;
          videoFile = PlatformFile(
            name: videoFileName,
            path: videoFilePath,
            size: tempVideoFile.lengthSync(),
          );
        });

        debugPrint('Video downloaded and saved: $videoFilePath');
      } else {
        debugPrint(
            'Failed to download video. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error downloading video: $error');
    }
  }
}
