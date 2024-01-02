import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/screens/process_video.dart';
import 'package:caption_forge/utils/lang.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SubtitleSettings extends StatefulWidget {
  const SubtitleSettings({super.key, required this.videoFile});
  final PlatformFile videoFile;

  @override
  State<SubtitleSettings> createState() => _SubtitleSettingsState();
}

class _SubtitleSettingsState extends State<SubtitleSettings> {
  String language = "Original";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VideoPlayerView(
          key: Key(widget.videoFile.path!),
          url: widget.videoFile.path!,
          dataSourceType: DataSourceType.file,
        ),
        const SizedBox(height: 16.0),
        CustomDropdown.search(
          closedFillColor: const Color(0xff4a5759),
          expandedFillColor: const Color(0xff4a5759),
          expandedSuffixIcon:
              const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          closedSuffixIcon:
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onChanged: (value) {
            setState(() {
              language = value;
            });
          },
          hintText: 'Select your language',
          items: ['Original', ...lang.map((e) => e['language']!).toList()],
        ),
        const SizedBox(height: 16.0),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessVideo(
                    videoPath: widget.videoFile.path!, language: language),
              ),
            );
          },
          child: const Text('Generate Subtitles'),
        ),
      ],
    );
  }
}
