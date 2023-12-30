import 'package:caption_forge/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await dotenv.load(fileName: ".env");
  await fetchAdsData();
  debugPrint("Ads Data Fetched");
  runApp(const MyApp());
}

Future<void> fetchAdsData() async {
  try {
    final response = await http.get(
        Uri.parse('https://kind-lime-lion-fez.cyclic.app/api/ad_settings'));
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('ad_settings', response.body);
    } else {
      throw Exception('Failed to load album');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
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
