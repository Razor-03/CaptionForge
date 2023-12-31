import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/utils/lang.dart';
import 'package:caption_forge/screens/play_video.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class DeviceVideo extends StatefulWidget {
  const DeviceVideo({super.key});
  @override
  State<DeviceVideo> createState() => _DeviceVideoState();
}

class _DeviceVideoState extends State<DeviceVideo> {
  PlatformFile? videoFile;
  String language = 'Original';

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
        title: const Text('Device Video'),
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
                  ],
                )
              : Column(
                  children: [
                    VideoPlayerView(
                      key: Key(videoFile!.path!),
                      url: videoFile!.path!,
                      dataSourceType: DataSourceType.file,
                    ),
                    const SizedBox(height: 16.0),
                    CustomDropdown.search(
                      closedFillColor: Colors.grey[800],
                      expandedFillColor: Colors.grey[800],
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
                    const SizedBox(height: 16.0),
                    OutlinedButton(
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
                      child: const Text('Generate Subtitles'),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: const SizedBox(
        width: double.infinity,
        child: BannerAdWidget(adSize: AdSize.banner),
      ),
    );
  }

  Future<void> _pickVideo() async {
    // var imagePicker = ImagePicker();
    // var video = await imagePicker.pickVideo(source: ImageSource.gallery);
    // debugPrint('Vhwhideo: ${video!.path}, ${video.name}, ${video.length()}, ${video.lastModified()}');
    // return;


    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    
    if (result == null || result.files.isEmpty) return;

    PlatformFile file = result.files.first;
    debugPrint('File: ${file.path}, ${file.name}, ${file.size}, ${file.extension}, ${file.bytes}');

    for (var element in result.files) {
      debugPrint('File: ${element.path}');
    }
    setState(() {
      videoFile = result.files.first;
    });
  }
}
