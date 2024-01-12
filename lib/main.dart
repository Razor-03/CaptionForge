import 'dart:convert';
import 'package:caption_forge/firebase_options.dart';
import 'package:caption_forge/screens/home_page.dart';
import 'package:caption_forge/utils/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await dotenv.load(fileName: ".env");
    await fetchAndStoreAdsData();
    debugPrint("Ads Data Fetched");
    await fetchAndStoreUserData();
    debugPrint("User Data Fetched");
  } on Exception catch (e) {
    debugPrint('Error: $e');
  }
  runApp(const MyApp());
  await [
    Permission.notification,
    Permission.storage,
    Permission.photos,
  ].request();
  NotificationService notificationService = NotificationService();
  await notificationService.initNotifications();
}

Future<void> fetchAndStoreUserData() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  debugPrint('Running on ${androidInfo.fingerprint}');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final fCMToken = await FirebaseMessaging.instance.getToken();

  try {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('User Info');

    DocumentSnapshot document = await usersCollection
        .doc(androidInfo.fingerprint.replaceAll('/', '|'))
        .get();
    if (document.exists) {
      debugPrint('User Exists');
      await usersCollection
          .doc(androidInfo.fingerprint.replaceAll('/', '|'))
          .update({
        'fcm_token': fCMToken,
      });
      prefs.setString(
          'user',
          jsonEncode({
            'id': androidInfo.fingerprint.replaceAll('/', '|'),
            'remaining_time': document['remaining_time'],
          }));
    } else {
      debugPrint('User Does Not Exist');
      prefs.setString(
          'user',
          jsonEncode({
            'id': androidInfo.fingerprint.replaceAll('/', '|'),
            'remaining_time': 30,
          }));

      await usersCollection
          .doc(androidInfo.fingerprint.replaceAll('/', '|'))
          .set({
        'remaining_time': 30,
        'fcm_token': fCMToken,
      });
    }
  } catch (e) {
    debugPrint('Error: $e');
  } finally {
    prefs.setString(
      'user',
      jsonEncode(
        {
          'id': androidInfo.fingerprint.replaceAll('/', '|'),
          'remaining_time': 30,
        },
      ),
    );
  }
}

Future<void> fetchAndStoreAdsData() async {
  try {
    final response = await http.get(
        Uri.parse('https://kind-lime-lion-fez.cyclic.app/api/ad_settings'));
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var data = jsonDecode(response.body);
      // data['ad_active'] = false;
      prefs.setString('ad_settings', jsonEncode(data));
    } else {
      throw Exception('Failed to load ads');
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
      theme: ThemeData(
        useMaterial3: true,
      ).copyWith(
        platform: Theme.of(context).platform == TargetPlatform.android
            ? TargetPlatform.iOS
            : Theme.of(context).platform,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 176, 196, 189),
          brightness: Brightness.light,
          primaryContainer: const Color.fromARGB(255, 176, 196, 179),
          shadow: const Color(0xffb0c4b1).withOpacity(0.5),
          secondaryContainer: const Color.fromARGB(255, 168, 227, 221),
          tertiaryContainer: const Color.fromARGB(255, 131, 171, 164),
          secondary: const Color(0xffb0c4b1),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(
            color: Color(0xffb0c4b1),
            fontSize: 16,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
            ),
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 15.0,
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
              const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.roboto(
            fontSize: 50,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w300,
            color: const Color.fromARGB(255, 0, 13, 54),
          ),
          labelMedium: GoogleFonts.jost(
            fontSize: 19,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w300,
            color: const Color(0xff4a5759),
          ),
          headlineSmall: GoogleFonts.roboto(
            fontSize: 22,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w300,
            color: const Color(0xff4a5759),
          ),
          titleLarge: GoogleFonts.roboto(
            fontSize: 30,
            fontStyle: FontStyle.normal,
            color: const Color(0xff4a5759),
          ),
          bodyMedium: GoogleFonts.merriweather(),
          displaySmall: GoogleFonts.pacifico(),
          bodySmall: GoogleFonts.roboto(
            fontSize: 16,
            fontStyle: FontStyle.normal,
            color: const Color(0xff4a5759),
          ),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 228, 234, 234),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 206, 217, 215),
          // foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.oswald(
            fontSize: 30,
            fontStyle: FontStyle.normal,
            color: const Color.fromARGB(255, 53, 37, 126),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
      ).copyWith(
        platform: Theme.of(context).platform == TargetPlatform.android
            ? TargetPlatform.iOS
            : Theme.of(context).platform,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 126, 9, 9),
          brightness: Brightness.dark,
          primaryContainer: const Color.fromARGB(255, 78, 6, 6),
          shadow: const Color.fromARGB(255, 78, 6, 6).withOpacity(0.5),
          secondaryContainer: const Color.fromARGB(244, 157, 43, 35),
          tertiaryContainer: const Color.fromARGB(255, 90, 10, 4),
          secondary: const Color.fromARGB(255, 230, 102, 92),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(
            color: Color(0xffb0c4b1),
            fontSize: 16,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
            ),
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 15.0,
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
              const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.roboto(
            fontSize: 50,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w300,
            color: const Color.fromARGB(255, 184, 125, 125),
          ),
          labelMedium: GoogleFonts.jost(
            fontSize: 19,
            letterSpacing: 3,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w300,
            color: const Color.fromARGB(255, 184, 125, 125),
          ),
          headlineSmall: GoogleFonts.roboto(
            fontSize: 19,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w300,
            color: const Color.fromARGB(255, 184, 125, 125),
          ),
          titleLarge: GoogleFonts.roboto(
            fontSize: 30,
            fontStyle: FontStyle.normal,
            color: const Color(0xff4a5759),
          ),
          bodyMedium: GoogleFonts.merriweather(),
          displaySmall: GoogleFonts.pacifico(),
          bodySmall: GoogleFonts.roboto(
            fontSize: 16,
            fontStyle: FontStyle.normal,
            color: const Color.fromARGB(255, 230, 192, 192),
          ),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 29, 0, 0),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 52, 11, 11),
          // foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.oswald(
            fontSize: 30,
            fontStyle: FontStyle.normal,
            color: const Color.fromARGB(255, 53, 37, 126),
          ),
        ),
      ),
    );
  }
}
