import 'dart:async';
import 'dart:io';
import 'package:caption_forge/Ads/app_open_ad.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Ads/native_ad.dart';
import 'package:caption_forge/Ads/reward_ad.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:caption_forge/screens/device_video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: const MyHomePage(),
        theme: ThemeData.dark().copyWith(
            platform: Theme.of(context).platform == TargetPlatform.android
                ? TargetPlatform.iOS
                : Theme.of(context).platform));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  var client = http.Client();
  @override
  void initState() {
    super.initState();
    loadOpenAppAd();
    // loadInterstitialAd();
    // loadRewardAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaptionForge'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            LoadingAnimationWidget.fourRotatingDots(
              size: 50,
              color: Colors.white,
            ),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
                shape: BoxShape.rectangle,
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeviceVideo(),
                    ),
                  );
                },
                child: const ListTile(
                  minVerticalPadding: 10,
                  leading: Icon(Icons.ondemand_video),
                  title: Text('Upload Video From Device'),
                  subtitle: Text(
                    'Transcription by uploading video file fom your mobile storage',
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
                shape: BoxShape.rectangle,
              ),
              child: const InkWell(
                child: ListTile(
                  minVerticalPadding: 10,
                  leading: Icon(Icons.link),
                  title: Text('Upload Video From URL'),
                  subtitle: Text(
                    'Transcription by uploading video file from URL',
                  ),
                ),
              ),
            ),
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
            ElevatedButton(
                onPressed: () {
                  client.close();
                },
                child: const Text('Cancel Download')),
            ElevatedButton(
              onPressed: () {
                interstitialAd!.show();
              },
              child: const Text('Show interstitialAd Ad'),
            ),
            // NativeAdWidget(),
            ElevatedButton(
              onPressed: () {
                rewardedAd!.show(
                  onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                    debugPrint(
                        '$RewardedAd with reward $RewardItem(${reward.amount}, ${reward.type})');
                  },
                );
              },
              child: const Text('Show Rewarded Ad'),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
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
