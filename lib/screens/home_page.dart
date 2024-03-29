import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:caption_forge/screens/device_video.dart';
import 'package:caption_forge/screens/url_video.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/app_open_ad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caption_forge/screens/history.dart';
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  var client = http.Client();

  @override
  void initState() {
    loadAd();
    [
      Permission.notification,
      Permission.storage,
      Permission.manageExternalStorage,      
    ].request();
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
            const SizedBox(width: 50),
            Text(
              'CAPTION FORGE',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const History(),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 110),
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
              Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.tertiaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(10),
                  // color: Theme.of(context).colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow,
                      blurRadius: 5,
                      // offset: const Offset(0, 5),
                      spreadRadius: 6,
                    ),
                  ],
                  shape: BoxShape.rectangle,
                ),
                child: InkWell(
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeviceVideo(),
                        ),
                      );
                    });
                  },
                  child: const ListTile(
                    minVerticalPadding: 15,
                    leading: Icon(Icons.ondemand_video),
                    title: Text(
                      'Upload Video From Device',
                      style: TextStyle(height: 2),
                    ),
                    subtitle: Text(
                      'Transcription by uploading video file from your mobile storage',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.secondaryContainer,
                    Theme.of(context).colorScheme.tertiaryContainer,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      // offset: const Offset(0, 5),
                      spreadRadius: 4,
                    ),
                  ],
                  shape: BoxShape.rectangle,
                ),
                child: InkWell(
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UrlVideo(),
                        ),
                      );
                    });
                  },
                  child: const ListTile(
                    minVerticalPadding: 15,
                    leading: Icon(Icons.link),
                    title: Text(
                      'Upload Video From URL',
                      style: TextStyle(
                        height: 2,
                      ),
                    ),
                    subtitle: Text(
                      'Transcription by uploading video file from URL',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(adSize: AdSize.banner),
    );
  }
}
