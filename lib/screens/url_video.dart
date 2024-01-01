import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/utils/lang.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:caption_forge/screens/play_video.dart';

class UrlVideo extends StatefulWidget {
  const UrlVideo({Key? key}) : super(key: key);

  @override
  State<UrlVideo> createState() => _UrlVideoState();
}

class _UrlVideoState extends State<UrlVideo> {
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  var client = http.Client();
  String language = '';
  bool isDownloading = false;
  double downloadProgress = 0.0;

  @override
  void initState() {
    // loadAd();
    super.initState();
  }

  Future<void> loadAd() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String adSettings = prefs.getString('ad_settings') ?? '';
    debugPrint('Ad Settings: $adSettings');
    if (adSettings.isNotEmpty) {
      var ads = jsonDecode(adSettings);
      if (ads['interstritalAdmob'] && ads['ad_active']) {
        // loadInterstitialAd(adUnitId: ads['interstitial_adUnit']);
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
      body: Center(
        child: isDownloading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: downloadProgress),
                  SizedBox(height: 16.0),
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
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0))),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 12),
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
                : Column(
                    children: [
                      VideoPlayerView(
                        key: Key(videoFile!.path!),
                        url: videoFile!.path!,
                        dataSourceType: DataSourceType.file,
                      ),
                      CustomDropdown.search(
                        closedFillColor: const Color(0xff4a5759),
                        expandedFillColor: const Color(0xff4a5759),
                        expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up,
                            color: Colors.white),
                        closedSuffixIcon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            language = value;
                          });
                        },
                        hintText: 'Select your language',
                        items: [
                          'Original',
                          ...lang.map((e) => e['language']!).toList()
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayVideo(
                                  videoPath: videoFile!.path!,
                                  language: language),
                            ),
                          );
                        },
                        child: const Text('Generate'),
                      ),
                    ],
                  )),
      ),
      // bottomNavigationBar: const SizedBox(
      //   width: double.infinity,
      //   child: BannerAdWidget(adSize: AdSize.banner),
      // ),
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

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}
