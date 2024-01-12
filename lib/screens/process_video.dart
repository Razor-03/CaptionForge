import 'dart:io';

import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/reward_ad.dart';
import 'package:caption_forge/screens/play_video.dart';
import 'package:caption_forge/utils/notification_service.dart';
import 'package:caption_forge/utils/lang.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

class ProcessVideo extends StatefulWidget {
  const ProcessVideo(
      {super.key, required this.videoPath, required this.language});

  final String videoPath;
  final String language;

  @override
  State<ProcessVideo> createState() => _ProcessVideoState();
}

class _ProcessVideoState extends State<ProcessVideo> {
  final _flutterFFmpeg = FlutterFFmpeg();
  final client = http.Client();
  String progressString = '';
  var notificationService = NotificationService();
  // late Future<void> niver;

  @override
  void initState() {
    updateProgress('Loading ad.....');
    loadAd().then(
      (value) {
        updateProgress('Generating subtitle');
        // return;
        _convertVideoToSrt().then(
          (subtitle) {
            if (subtitle == null) {
              updateProgress('Failed to generate subtitle');
              Future.delayed(const Duration(seconds: 2), () {
                cancelProcess();
                Navigator.of(context).pop();
              });
              return;
            }
            notificationService.showLocalNotification(
              'Subtitle generated successfully',
              null,
              null,
            );
            // niver.then((value) =>
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoPath: widget.videoPath,
                  subtitle: subtitle,
                ),
              ),
              // )
            );
          },
        ).catchError(
          (error) {
            debugPrint('Error: $error');
          },
        );
      },
    );

    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    cancelProcess();
  }

  Future<void> loadAd() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String adSettings = prefs.getString('ad_settings') ?? '';
    debugPrint('Ad Settings: $adSettings');
    if (adSettings.isNotEmpty) {
      var ads = jsonDecode(adSettings);
      if (ads['rewardAdmob'] && ads['ad_active']) {
        await loadRewardAd(adUnitId: ads['reward_adUnit']);
        await rewardedAd?.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('User earned reward: $reward');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play Video',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.fourRotatingDots(
                color: Theme.of(context).colorScheme.secondary, size: 50),
            Text(
              progressString,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16.0),
            OutlinedButton(
              onPressed: () {
                cancelProcess();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel Process'),
            ),
          ],
        )),
      ),
      bottomNavigationBar: const BannerAdWidget(adSize: AdSize.banner),
    );
  }

  Future<String?> _convertVideoToSrt() async {
    saveVideoDetails(widget.videoPath, widget.language);

    updateProgress('Searching for subtitle file...');
    final directory = await getTemporaryDirectory();
    final subtitleDirectory = Directory("${directory.path}/subtitle");
    final transcribeDirectory = Directory("${directory.path}/transcribe");
    if (!subtitleDirectory.existsSync()) {
      subtitleDirectory.createSync();
    }
    if (!transcribeDirectory.existsSync()) {
      transcribeDirectory.createSync();
    }

    File srtFile = File(
        "${subtitleDirectory.path}/${path.basenameWithoutExtension(widget.videoPath)}.${widget.language}.srt");
    if (srtFile.existsSync()) {
      return srtFile.readAsStringSync();
    }

    File transcribeFile = File(
        "${transcribeDirectory.path}/${path.basenameWithoutExtension(widget.videoPath)}.English.srt");
    if (transcribeFile.existsSync() && widget.language != 'Original') {
      var srtData = await translateSrt(
          transcribeFile.readAsStringSync(), widget.language);
      if (srtData != null) {
        srtFile.writeAsStringSync(srtData);
        return srtData;
      } else {
        return null;
      }
    }

    debugPrint('Video file: ${widget.videoPath}');

    final tempAudioPath =
        '${directory.path}/${path.basename(widget.videoPath)}.m4a';

    await _convertVideoToAudio(widget.videoPath, tempAudioPath);
    debugPrint('Audio file converted: $tempAudioPath');

    String? srtData = await _sendAudioToOpenAI(tempAudioPath);
    if (srtData == null) {
      return null;
    }
    File(tempAudioPath).deleteSync();
   
    debugPrint(srtData);

    if (widget.language != 'Original') {
      await transcribeFile.writeAsString(srtData);
    }

    if (widget.language != "Original" && widget.language != "English") {
      srtData = await translateSrt(srtData, widget.language);
      if (srtData == null) {
        return null;
      }
    }

    await srtFile.writeAsString(srtData);
    return srtData;
  }

  Future<void> saveVideoDetails(String videoPath, String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String user = prefs.getString('user') ?? '';
      debugPrint('User: $user');
      var userData = jsonDecode(user);
      debugPrint('User Data: $userData');
      final CollectionReference videoCollection = FirebaseFirestore.instance
          .collection('User Info')
          .doc(userData['id'])
          .collection('Video Details');

      final FlutterFFprobe flutterFFprobe = FlutterFFprobe();
      MediaInformation mediaInformation =
          await flutterFFprobe.getMediaInformation(videoPath);
      Map<dynamic, dynamic> mp = mediaInformation.getMediaProperties()!;
      var data = {
        'video_name': path.basename(videoPath),
        'video_size': mp['size'],
        'video_duration': mp['duration'],
        'video_language': language,
        'video_date': DateTime.now(),
      };
      await videoCollection
          .doc("${path.basename(videoPath)}.${DateTime.now()}")
          .set(data);
    } on Exception catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<String?> translateSrt(String srtData, String language) async {
    updateProgress("Translating subtitle...");
    try {
      var url = "https://kind-lime-lion-fez.cyclic.app/api/translate";
      var response = await client.post(Uri.parse(url),
          body: jsonEncode({
            'text': srtData,
            'lang': lang
                .where((element) => element['language'] == language)
                .first['code']
          }),
          headers: {'Content-Type': 'application/json'});
      var text = jsonDecode(response.body);
      return text;
    } on Exception catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  Future<void> _convertVideoToAudio(String inputPath, String outputPath) async {
    updateProgress("Converting video to audio...");
    debugPrint('Converting video to audio...');
    int result = await _flutterFFmpeg.executeWithArguments([
      '-i',
      inputPath,
      '-vn',
      '-ar',
      '44100',
      '-ac',
      '2',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      outputPath
    ]);
    if (result == 0) {
      debugPrint('Conversion successful');
    } else {
      debugPrint('Conversion failed');
    }
  }

  Future<dynamic> _sendAudioToOpenAI(String audioPath) async {
    updateProgress("Generating subtitle...");
    final openaiApiKey = dotenv.env['OPENAI_API_KEY'];

    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      debugPrint('OpenAI API key is missing');
      return null;
    }

    final url = Uri.parse(
        'https://api.openai.com/v1/audio/${widget.language == "Original" ? "transcriptions" : "translations"}');

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({'Authorization': 'Bearer $openaiApiKey'});
    request.fields['model'] = 'whisper-1';
    request.fields['response_format'] = 'srt';
    request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    try {
      final response = await client.send(request);
      if (response.statusCode == 200) {
        debugPrint('Audio file sent successfully to OpenAI API');
        var responseData = await http.Response.fromStream(response);
        debugPrint(responseData.body);
        return responseData.body;
      } else {
        debugPrint(
            'Failed to send audio file. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error sending audio file: $error');
      return null;
    }
  }

  void cancelProcess() {
    updateProgress("Cancelling process...");
    _flutterFFmpeg.cancel();
    client.close();
  }

  void updateProgress(String message) {
    setState(() {
      progressString = message;
    });
  }
}
