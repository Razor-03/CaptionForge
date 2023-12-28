import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/lang.dart';
import 'package:caption_forge/screens/play_video.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DeviceVideo extends StatefulWidget {
  const DeviceVideo({super.key});
  @override
  State<DeviceVideo> createState() => _DeviceVideoState();
}

class _DeviceVideoState extends State<DeviceVideo> {
  PlatformFile? videoFile;
  String language = '';

  @override
  void initState() {
    loadInterstitialAd();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Video'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            videoFile == null
                ? ElevatedButton(
                    onPressed: () {
                      _pickVideo();
                    },
                    child: const Text("Upload From Device"),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        VideoPlayerView(
                          key: Key(videoFile!.path!),
                          url: videoFile!.path!,
                          dataSourceType: DataSourceType.file,
                        ),
                        CustomDropdown.search(
                          closedFillColor: Colors.grey[800],
                          expandedFillColor: Colors.grey[800],
                          expandedSuffixIcon: const Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white),
                          closedSuffixIcon: const Icon(
                              Icons.keyboard_arrow_down,
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
                    ),
                  ),
            const SizedBox(
              width: double.infinity,
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      videoFile = result.files.first;
    });
  }
}
