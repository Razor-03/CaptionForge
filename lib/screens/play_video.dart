import 'dart:io';

import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/reward_ad.dart';
// import 'package:caption_forge/Ads/reward_ad.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/utils/firebase_notification.dart';
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
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

class PlayVideo extends StatefulWidget {
  const PlayVideo({super.key, required this.videoPath, required this.language});

  final String videoPath;
  final String language;

  @override
  State<PlayVideo> createState() => _PlayVideoState();
}

class _PlayVideoState extends State<PlayVideo> {
  final _flutterFFmpeg = FlutterFFmpeg();
  final client = http.Client();
  String progressString = '';
  late String subtitle;
  bool subtitleLoading = true;
  var notificationService = NotificationService();

  @override
  void initState() {
    _convertVideoToSrt().then((value) {
      notificationService.showLocalNotification(
        'Subtitle generated successfully',
        null,
        null,
      );
      setState(() {
        subtitle = value;
        subtitleLoading = false;
      });
    }).catchError((error) {
      debugPrint('Error: $error');
    });
    // loadAd();
    notificationService.initNotifications();
    super.initState();
  }

  Future<void> loadAd() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String adSettings = prefs.getString('ad_settings') ?? '';
    debugPrint('Ad Settings: $adSettings');
    if (adSettings.isNotEmpty) {
      var ads = jsonDecode(adSettings);
      if (ads['rewardAdmob'] && ads['ad_active']) {
        loadRewardAd(adUnitId: ads['reward_adUnit']);
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
          child: subtitleLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingAnimationWidget.fourRotatingDots(
                        color: Theme.of(context).colorScheme.secondary,
                        size: 50),
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
                      },
                      child: const Text('Cancel Process'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoPlayerView(
                      key: UniqueKey(),
                      url: widget.videoPath,
                      dataSourceType: DataSourceType.file,
                      subtitleData: subtitle,
                    ),
                    const SizedBox(height: 16.0),
                    OutlinedButton(
                      onPressed: () {
                        saveFile(
                            '${path.basenameWithoutExtension(widget.videoPath)}.srt',
                            subtitle);
                      },
                      child: const Text(
                        'Download Subtitle',
                      ),
                    ),
                  ],
                ),
        ),
      ),
      // bottomNavigationBar: const SizedBox(
      //   width: double.infinity,
      //   child: BannerAdWidget(adSize: AdSize.banner),
      // ),
    );
  }

  Future<String> _convertVideoToSrt() async {
    await saveVideoDetails(widget.videoPath, widget.language);

    updateProgress('Searching for subtitle file...');
    final directory = await getTemporaryDirectory();
    final tempDirectory = Directory("${directory.path}/subtitle");
    if (!tempDirectory.existsSync()) {
      tempDirectory.createSync();
    }
    File searchFile = File(
        "${tempDirectory.path}/${path.basenameWithoutExtension(widget.videoPath)}.${widget.language == 'Original' ? 'Original' : 'English'}.srt");
    if (searchFile.existsSync()) {
      debugPrint('File exists');
      if (widget.language == 'Original' || widget.language == 'English') {
        return searchFile.readAsStringSync();
      } else {
        return await translateSrt(
            searchFile.readAsStringSync(), widget.language);
      }
    }

    debugPrint('Video file: ${widget.videoPath}');

    final tempAudioPath =
        '${directory.path}/${path.basename(widget.videoPath)}.m4a';

    updateProgress("Searching for audio file...");
    if (File(tempAudioPath).existsSync()) {
      debugPrint('Audio file exists');
    } else {
      debugPrint('Audio file does not exist');
      await _convertVideoToAudio(widget.videoPath, tempAudioPath);
      debugPrint('Audio file converted: $tempAudioPath');
    }

    // var srtData = await _sendAudioToOpenAI(tempAudioPath);

    var srtData = """
1
00:00:00,000 --> 00:00:02,000
Cognac?

2
00:00:02,000 --> 00:00:04,000
No, thank you.

3
00:00:04,000 --> 00:00:06,000
Listen, I'm...

4
00:00:06,000 --> 00:00:08,000
sorry...

5
00:00:08,000 --> 00:00:10,000
for your loss.

""";
    debugPrint(srtData);
    final File srtFile = File(
        "${tempDirectory.path}/${path.basenameWithoutExtension(widget.videoPath)}.${widget.language == 'Original' ? 'Original' : 'English'}.srt");
    srtFile.writeAsString(srtData);

    if (widget.language != "Original" && widget.language != "English") {
      srtData = await translateSrt(srtData, widget.language);
    }

    return srtData;
  }

  Future<void> saveVideoDetails(String videoPath, String language) async {
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
    videoCollection
        .doc("${path.basename(videoPath)}.${DateTime.now()}")
        .set(data);
    prefs.setString(path.basename(videoPath), jsonEncode(data));
  }

  Future<String> translateSrt(String srtData, String language) async {
    updateProgress("Translating subtitle...");
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
  }

  Future<void> _convertVideoToAudio(String inputPath, String outputPath) async {
    updateProgress("Converting video to audio...");
    debugPrint('Converting video to audio...');
    String command =
        '-i $inputPath -vn -ar 44100 -ac 2 -c:a aac -b:a 192k $outputPath';

    int result = await _flutterFFmpeg.execute(command);
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
    Navigator.pop(context);
  }

  void saveFile(String fileName, String data) async {
    // final directory = Directory("/storage/emulated/0/Download");
    // final file = File('${directory.path}/$fileName');
    // await file.writeAsString(data);
    notificationService.showLocalNotification(
      'Subtitle downloaded successfully',
      'Download/$fileName',
      // file.path,
      'download',
    );
  }

  void updateProgress(String message) {
    setState(() {
      progressString = message;
    });
  }
}
