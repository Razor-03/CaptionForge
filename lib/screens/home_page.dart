import 'dart:async';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Ads/reward_ad.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:caption_forge/screens/device_video.dart';
import 'package:caption_forge/screens/url_video.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/app_open_ad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  var client = http.Client();

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
      if (ads['appOpenAdmob'] && ads['ad_active']) {
        loadOpenAppAd(adUnitId: ads['appOpen_adUnit']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Icon(
            //   Icons.subtitles,
            //   size: 20,
            // ),
            Text(
              'CAPTION FORGE',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text('Generate',
                        style: Theme.of(context).textTheme.displayLarge),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Text('multilingual captions for your videos',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
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
                  'Transcription by uploading video file from your mobile storage',
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.secondaryContainer,
                Theme.of(context).colorScheme.tertiaryContainer,
              ]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                    builder: (context) => const UrlVideo(),
                  ),
                );
              },
              child: const ListTile(
                minVerticalPadding: 10,
                leading: Icon(Icons.link),
                title: Text('Upload Video From URL'),
                subtitle: Text(
                  'Transcription by uploading video file from URL',
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              client.close();
            },
            child: const Text('Cancel Download'),
          ),
          ElevatedButton(
            onPressed: () {
              interstitialAd!.show();
            },
            child: const Text('Show Interstitial Ad'),
          ),
          ElevatedButton(
            onPressed: () {
              rewardedAd!.show(
                onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                  debugPrint(
                    '$RewardedAd with reward $RewardItem(${reward.amount}, ${reward.type})',
                  );
                },
              );
            },
            child: const Text('Show Rewarded Ad'),
          ),
          // const Expanded(
          //   child: Align(
          //     alignment: Alignment.bottomCenter,
          //     child: BannerAdWidget(adSize: AdSize.banner),
          //   ),
          // ),
        ],
      ),
    );
  }
}
