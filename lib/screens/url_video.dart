import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Widget/subtitle_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class UrlVideo extends StatefulWidget {
  const UrlVideo({Key? key}) : super(key: key);

  @override
  State<UrlVideo> createState() => _UrlVideoState();
}

class _UrlVideoState extends State<UrlVideo> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  var client = http.Client();
  bool isDownloading = false;
  double downloadProgress = 0.0;

  @override
  void initState() {
    loadAd();
    super.initState();
  }

  Future<void> loadAd() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String adSettings = prefs.getString('ad_settings') ?? '';
    debugPrint('Ad Settings: $adSettings');
    if (adSettings.isNotEmpty) {
      var ads = jsonDecode(adSettings);
      if (ads['interstritalAdmob'] && ads['ad_active']) {
        loadInterstitialAd(adUnitId: ads['interstitial_adUnit']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'URL Video',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: isDownloading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: downloadProgress),
                    const SizedBox(height: 16.0),
                    Text(
                      'Downloading... ${(downloadProgress * 100).toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : (videoFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/url_video.png',
                          height: 90.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextField(
                            style: Theme.of(context).textTheme.bodySmall,
                            controller: urlController,
                            decoration: InputDecoration(
                              labelText: "Enter Video URL",
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 16,
                          ),
                          child: OutlinedButton(
                            onPressed: () async {
                              await _downloadVideoFromUrl(urlController.text);
                            },
                            child: const Text('Upload From URL'),
                          ),
                        ),
                        const Text(
                          'You can paste any video url and transcribe it into the desired language. Only links that have a video file at the end will work.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : SubtitleSettings(videoFile: videoFile!)),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(adSize: AdSize.banner),
    );
  }

  Future<void> _downloadVideoFromUrl(String videoUrl) async {
    try {
      setState(() {
        isDownloading = true;
        downloadProgress = 0.0;
      });

      var request = http.Request('GET', Uri.parse(videoUrl));
      var response = await client.send(request);

      if (response.statusCode == 200) {
        final tempDirectory = await getTemporaryDirectory();
        final directory = Directory('${tempDirectory.path}/file_picker');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final videoFileName = path.basename(videoUrl);
        final videoFilePath = path.join(directory.path, videoFileName);
        debugPrint('Video file path: $videoFilePath');

        File tempVideoFile = File(videoFilePath);
        var contentLength = response.contentLength ?? -1;
        var receivedBytes = 0;

        await response.stream.forEach((List<int> chunk) {
          tempVideoFile.writeAsBytesSync(chunk, mode: FileMode.append);
          receivedBytes += chunk.length;
          setState(() {
            downloadProgress = receivedBytes / contentLength;
            displayDownloadProgressNotification(downloadProgress);
            if (downloadProgress >= 1.0) {
              // If the download is finished, you can perform additional actions here
              debugPrint('Download Finished');
            }
          });
        });

        setState(() {
          tempVideoFile = tempVideoFile;
          videoFile = PlatformFile(
            name: videoFileName,
            path: videoFilePath,
            size: tempVideoFile.lengthSync(),
          );
          isDownloading = false;
        });

        debugPrint('Video downloaded and saved: $videoFilePath');
      } else {
        debugPrint(
            'Failed to download video. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error downloading video: $error');
      setState(() {
        isDownloading = false;
        downloadProgress = 0.0;
      });
    }
  }

  Future<void> displayDownloadProgressNotification(double progress) async {
    final int progressPercentage = (progress * 100).toInt();
    final String notificationMessage = (progressPercentage < 100)
        ? 'Download Progress: $progressPercentage%'
        : 'Download Finished';
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel', // Use a unique channel ID
      'Download Progress  ${progress.toInt() * 100}', // Channel name
      channelDescription: 'Shows download progress', // Channel description
      importance: Importance.high,
      priority: Priority.high,
      channelShowBadge: true,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercentage,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Downloading Video', // Notification title
      notificationMessage, // Notification body
      platformChannelSpecifics,
      payload: 'download_progress',
    );
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}
