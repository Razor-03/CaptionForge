import 'dart:io';

import 'package:caption_forge/Widget/video_player_view.dart';
import 'package:caption_forge/lang.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:circular_seek_bar/circular_seek_bar.dart';

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
  final ValueNotifier<double> _valueNotifier = ValueNotifier(0);
  var _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Video'),
      ),
      body: Center(
        child: FutureBuilder(
          future: _convertVideoToSrt(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                children: [
                  VideoPlayerView(
                    key: UniqueKey(),
                    url: widget.videoPath,
                    dataSourceType: DataSourceType.file,
                    subtitleData: snapshot.data as String,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      saveFile(
                          '${path.basenameWithoutExtension(widget.videoPath)}.srt',
                          snapshot.data as String);
                    },
                    child: const Text('Download'),
                  ),
                ],
              );
            } else {
              return CircularSeekBar(
                width: double.infinity,
                height: 250,
                progress: _progress,
                barWidth: 8,
                startAngle: 45,
                sweepAngle: 270,
                strokeCap: StrokeCap.butt,
                progressGradientColors: const [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple
                ],
                innerThumbRadius: 5,
                innerThumbStrokeWidth: 3,
                innerThumbColor: Colors.white,
                outerThumbRadius: 5,
                outerThumbStrokeWidth: 10,
                outerThumbColor: Colors.blueAccent,
                dashWidth: 1,
                dashGap: 2,
                animation: true,
                valueNotifier: _valueNotifier,
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: _valueNotifier,
                    builder: (_, double value, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${value.round()}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 24)),
                        Text('progress',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<String> _convertVideoToSrt() async {
    await Future.delayed(const Duration(seconds: 5));
    final tempDirectory = await getTemporaryDirectory();
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
        '${tempDirectory.path}/${path.basename(widget.videoPath)}.m4a';

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

  Future<String> translateSrt(String srtData, String language) async {
    var url = "https://kind-lime-lion-fez.cyclic.app/api/translate";
    var response = await http.post(Uri.parse(url),
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

    final url = Uri.parse(
        'https://api.openai.com/v1/audio/${widget.language == "Original" ? "transcriptions" : "translations"}');
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
        debugPrint(
            'Failed to send audio file. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error sending audio file: $error');
      return null;
    }
  }

  void saveFile(String fileName, String data) async {
    final directory = Directory("/storage/emulated/0/Download");
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(data);
  }
}
