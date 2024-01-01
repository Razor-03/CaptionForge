import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final FlutterFFprobe flutterFFprobe = FlutterFFprobe();

  Future<List<Map<String, dynamic>>> loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var tempDirectory = await getTemporaryDirectory();
    var videoDir = Directory('${tempDirectory.path}/file_picker');
    var subtitleDir = Directory('${tempDirectory.path}/subtitle');
    List<FileSystemEntity> videos = [];
    List<FileSystemEntity> subtitles = [];

    if (videoDir.existsSync()) {
      videos = videoDir.listSync();
    }
    if (subtitleDir.existsSync()) {
      subtitles = subtitleDir.listSync();
    }
    print(videos);
    print(subtitles);
    videos.removeWhere((element) {
      var videoName = path.basenameWithoutExtension(element.path);
      return !subtitles.any((element) {
        var subtitleName = path.basenameWithoutExtension(element.path);
        return subtitleName.startsWith(videoName);
      });
    });

    subtitles.removeWhere((element) {
      var subtitleName = path.basenameWithoutExtension(element.path);
      return !videos.any((element) {
        var videoName = path.basenameWithoutExtension(element.path);
        return subtitleName.startsWith(videoName);
      });
    });

    print(videos);
    print(subtitles);

    List<Map<String, dynamic>> history = [];
    subtitles.forEach((subtitle) {
      print('Stared');
      var video = videos.firstWhere((element) {
        var videoName = path.basenameWithoutExtension(element.path);
        var subtitleName = path.basenameWithoutExtension(subtitle.path);
        return subtitleName.startsWith(videoName);
      });
      var name = path.basename(video.path);
      // flutterFFprobe.getMediaInformation(video.path).then((mediaInformation) {
      //   Map<dynamic, dynamic> mp = mediaInformation.getMediaProperties();
      var data = jsonDecode(prefs.getString(name)?? '');
      print(data);
      history.add({
        'name': name,
        'video': video,
        'subtitle': subtitle,
        'duration': data['video_duration'] ?? 0,
        'size': video.statSync().size,
        'created_at': subtitle.statSync().changed,
        'language':
            path.basenameWithoutExtension(subtitle.path).split('.').last,
      });
      // });
    });
    print(history);
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder(
        future: loadHistory(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var history = snapshot.data![index];
                return ListTile(
                  title: Text(history['name']),
                  subtitle: Text(history['language']),
                  trailing: Text(history['duration'].toString()),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
