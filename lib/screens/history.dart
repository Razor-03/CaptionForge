import 'dart:convert';
import 'dart:io';
import 'package:caption_forge/Ads/banner_ad.dart';
import 'package:caption_forge/Ads/interstitial_ad.dart';
import 'package:caption_forge/screens/play_video.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
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

  Future<List<Map<String, dynamic>>> loadHistory() async {
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

    List<Map<String, dynamic>> history = [];
    for (var subtitle in subtitles) {
      var video = videos.firstWhere((element) {
        var videoName = path.basenameWithoutExtension(element.path);
        var subtitleName = path.basenameWithoutExtension(subtitle.path);
        return subtitleName.startsWith(videoName);
      });
      var name = path.basename(video.path);
      history.add(
        {
          'name': name,
          'video': video,
          'subtitle': subtitle,
          'size': (video.statSync().size / 1000000).toStringAsFixed(2),
          'created_at': subtitle.statSync().changed,
          'language':
              path.basenameWithoutExtension(subtitle.path).split('.').last,
        },
      );
    }
    history.sort((a, b) => b['created_at'].compareTo(a['created_at']));
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: FutureBuilder(
        future: loadHistory(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('No History'));
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var history = snapshot.data![index];
                DateTime createdAt = history['created_at'];
                return ListTile(
                  onTap: () {
                    File subtitleFile = File(history['subtitle'].path);
                    String subtitleData = subtitleFile.readAsStringSync();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                          videoPath: history['video'].path,
                          subtitle: subtitleData),
                    ));
                  },
                  title: Text(
                    history['name'],
                    textAlign: TextAlign.center,
                  ),
                  subtitle:
                      Text(history['language'], textAlign: TextAlign.center),
                  trailing: Text('${history['size']} MB'),
                  leading: Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}\n${createdAt.hour}:${createdAt.minute}:${createdAt.second}',
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: const BannerAdWidget(adSize: AdSize.banner),
    );
  }
}
