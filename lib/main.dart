import 'dart:convert';
import 'dart:io';
import 'package:caption_forge/firebase_options.dart';
import 'package:caption_forge/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  await fetchAndStoreAdsData();
  debugPrint("Ads Data Fetched");
  await fetchAndStoreUserData();
  debugPrint("User Data Fetched");
  var dir = await getTemporaryDirectory();
  debugPrint("Temporary Directory: ${dir.path}");
<<<<<<< HEAD
  if (dir.existsSync()) {
    debugPrint("Directory Exists");
=======
  for (var file in dir.listSync()) {
    debugPrint("File: ${file.path}");
  }
  // var eng = Directory('${dir.path}/transcribe');
  // for (var file in eng.listSync()) {
  //   debugPrint("transcribe: ${file.path}");
  // }
  // var sub = Directory('${dir.path}/subtitle');
  // for (var file in sub.listSync()) {
  //   debugPrint("subtitle: ${file.path}");
  // }
  // var file = Directory('${dir.path}/file_picker');
  // for (var file in file.listSync()) {
  //   debugPrint("video: ${file.path}");
  // }
>>>>>>> a8a428b3c5db443638ddcd13aa220786d0ce233b

    // List files in the 'transcribe' directory
    var eng = Directory('${dir.path}/transcribe');
    if (eng.existsSync()) {
      debugPrint("Files in transcribe:");
      for (var file in eng.listSync()) {
        debugPrint("transcribe: ${file.path}");
      }
    } else {
      debugPrint("Transcribe Directory Does Not Exist");
    }

    // List files in the 'subtitle' directory
    var sub = Directory('${dir.path}/subtitle');
    if (sub.existsSync()) {
      debugPrint("Files in subtitle:");
      for (var file in sub.listSync()) {
        debugPrint("subtitle: ${file.path}");
      }
    } else {
      debugPrint("Subtitle Directory Does Not Exist");
    }

    // List files in the 'file_picker' directory
    var filePicker = Directory('${dir.path}/file_picker');
    print(
        "******************************************${filePicker.path}**************************************************");
    if (filePicker.existsSync()) {
      debugPrint("Files in file_picker:");
      for (var file in filePicker.listSync()) {
        debugPrint("video: ${file.path}");
      }
    } else {
      debugPrint("File Picker Directory Does Not Exist");
    }
  } else {
    debugPrint("Main Directory Does Not Exist");
  }
  runApp(const MyApp());

  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.storage,
    Permission.camera,
  ].request();
}

Future<void> fetchAndStoreUserData() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  debugPrint('Running on ${androidInfo.fingerprint}');
  SharedPreferences prefs = await SharedPreferences.getInstance();

  try {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('User Info');

    DocumentSnapshot document = await usersCollection
        .doc(androidInfo.fingerprint.replaceAll('/', '|'))
        .get();
    if (document.exists) {
      debugPrint('User Exists');
      prefs.setString(
          'user',
          jsonEncode({
            'id': androidInfo.fingerprint.replaceAll('/', '|'),
            'remaining_time': document['remaining_time'],
          }));
    } else {
      final fCMToken = await FirebaseMessaging.instance.getToken();
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
          seedColor: const Color(0xffb0c4b1),
          brightness: Brightness.light,
          primaryContainer: const Color(0xffb0c4b1),
          shadow: const Color(0xffb0c4b1).withOpacity(0.5),
          secondaryContainer: Colors.white,
          tertiaryContainer: Colors.white,
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
        scaffoldBackgroundColor: const Color(0xffdedbd2),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xffdedbd2),
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
          secondaryContainer: const Color.fromARGB(244, 214, 52, 41),
          tertiaryContainer: const Color.fromARGB(255, 109, 10, 3),
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
          backgroundColor: const Color.fromARGB(255, 29, 0, 0),
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
