import 'dart:convert';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Widget/subtitle_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceVideo extends StatefulWidget {
  const DeviceVideo({super.key});
  @override
  State<DeviceVideo> createState() => _DeviceVideoState();
}

class _DeviceVideoState extends State<DeviceVideo> {
  PlatformFile? videoFile;

  @override
  void initState() {
    loadAd();
    super.initState();
  }

  @override
  dispose() {
    interstitialAd?.dispose();
    super.dispose();
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
          'Upload from Device',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
            child: videoFile == null
                ? Column(
                    children: [
                      Image.asset(
                        'assets/images/upload_video.png',
                        height: 200.0,
                      ),
                      OutlinedButton(
                        onPressed: _pickVideo,
                        child: const Text(
                          'Upload Video',
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'You can upload any type of file and transcribe it into the desired language.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 50.0),
                    ],
                  )
                : SubtitleSettings(videoFile: videoFile!)),
      ),
      bottomNavigationBar: const BannerAdWidget(adSize: AdSize.banner),
    );
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    PlatformFile file = result.files.first;
    debugPrint(
        'File: ${file.path}, ${file.name}, ${file.size}, ${file.extension}, ${file.bytes}');

    for (var element in result.files) {
      debugPrint('File: ${element.path}');
    }
    setState(() {
      videoFile = result.files.first;
    });
  }
}
