import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      theme: ThemeData.dark().copyWith(platform: TargetPlatform.iOS),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  PlatformFile? videoFile;
  TextEditingController urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video to Audio Converter'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              controller: urlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste video URL here',
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16,
            ),
            child: ElevatedButton(
              onPressed: () async {
                await _downloadVideoFromUrl(urlController.text);
              },
              child: Text('Upload From URL'),
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
        ],
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
        '${directory.path}/${videoFile!.name + Random().nextInt(500).toString()}.m4a';

    await _convertVideoToAudio(videoFile!.path!, tempAudioPath);

    print('Audio file converted: $tempAudioPath');

    var srtData = await _sendAudioToOpenAI(tempAudioPath);
    print(srtData);
    return srtData;
  }

  Future<void> _convertVideoToAudio(String inputPath, String outputPath) async {
    String command =
        '-i $inputPath -vn -ar 44100 -ac 2 -c:a aac -b:a 192k $outputPath';

    int result = await _flutterFFmpeg.execute(command);

    if (result == 0) {
      print('Conversion successful');
    } else {
      print('Conversion failed');
    }
  }

  Future<dynamic> _sendAudioToOpenAI(String audioPath) async {
    final openaiApiKey = dotenv.env['OPENAI_API_KEY'];

    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      print('OpenAI API key is missing');
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
        print('Audio file sent successfully to OpenAI API');
        var responseData = await http.Response.fromStream(response);
        print(responseData.body);
        return responseData.body;
      } else {
        print('Failed to send audio file. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending audio file: $error');
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

        print('Video downloaded and saved: $videoFilePath');
      } else {
        print('Failed to download video. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error downloading video: $error');
    }
  }
}
