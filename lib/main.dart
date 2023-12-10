import 'dart:io';
import 'package:caption_forge/Ads/app_open_ad.dart';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/Ads/native_ad.dart';
import 'package:caption_forge/Ads/reward_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  loadOpenAppAd();
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
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();
  @override
  void initState() {
    super.initState();
    loadInterstitialAd();
    loadRewardAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video to Audio Converter'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
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
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 16,
              ),
              child: Text('OR'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _pickVideo();
              },
              child: const Text('Upload From Device'),
            ),
            videoFile != null
                ? FutureBuilder(
                    key: UniqueKey(),
                    future: _convertVideoToSrt(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return VideoPlayerView(
                          key: UniqueKey(),
                          url: videoFile!.path!,
                          dataSourceType: DataSourceType.file,
                          subtitleData: snapshot.data.toString(),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  )
                : Container(),
            BannerAdWidget(),
            ElevatedButton(
              onPressed: () {
                interstitialAd!.show();
              },
              child: const Text('Show interstitialAd Ad'),
            ),
            NativeAdWidget(),
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

  Future<String> _convertVideoToSrt() async {
    final directory = await getTemporaryDirectory();
    final tempAudioPath =
        '${directory.path}/${videoFile!.name + UniqueKey().toString()}.m4a';

    debugPrint('Video file: ${videoFile!.path}');
    await _convertVideoToAudio(videoFile!.path!, tempAudioPath);

    debugPrint('Audio file converted: $tempAudioPath');

    // var srtData = await _sendAudioToOpenAI(tempAudioPath);
    // debugPrint(srtData);
    // return srtData;
    return """
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
  }

  Future<void> _convertVideoToAudio(String inputPath, String outputPath) async {
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
    final openaiApiKey = dotenv.env['OPENAI_API_KEY'];

    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      debugPrint('OpenAI API key is missing');
      return null;
    }

    final url = Uri.parse('https://api.openai.com/v1/audio/translations');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({'Authorization': 'Bearer $openaiApiKey'});
    request.fields['model'] = 'whisper-1';
    request.fields['response_format'] = 'srt';
    request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        debugPrint('Audio file sent successfully to OpenAI API');
        var responseData = await http.Response.fromStream(response);
        debugPrint(responseData.body);
        return responseData.body;
      } else {
        debugPrint('Failed to send audio file. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error sending audio file: $error');
      return null;
    }
  }

  Future<void> _downloadVideoFromUrl(String videoUrl) async {
    try {
      var response = await http.get(Uri.parse(videoUrl));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final videoFileName = path.basename(videoUrl);

        final videoFilePath = path.join(directory.path, videoFileName);

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
        debugPrint('Failed to download video. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error downloading video: $error');
    }
  }
}
