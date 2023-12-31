// //firebase notification

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:noti/main.dart';
// import 'package:noti/notification.dart';

// Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//   print("Tile: ${message.notification!.title}");
//   print("Body: ${message.notification!.body}");
//   print("Data: ${message.data}");
// }

// void handleMessage(RemoteMessage message) {
//   if (message.notification == null) return;
//   navigatorKey.currentState!.push(MaterialPageRoute(
//     builder: (context) => const MyNotification(),
//   ));
// }

// class FirebaseApi {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

//   final _andriodChannel = const AndroidNotificationChannel(
//     "high_importance_channel",
//     "High Importance Notification",
//     description: "This channel is used for important notifications.",
//     importance: Importance.high,
//   );

//   final _localNotification = FlutterLocalNotificationsPlugin();

//   Future<void> initNotifications() async {
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//     final fCMToken = await FirebaseMessaging.instance.getToken();
//     print("FCM Token: $fCMToken");
//     await initPushNotification();
//     await initLocalNotification();
//   }

//   Future initPushNotification() async {
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       handleMessage(message);
//     });
//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((message) => handleMessage(message!));
//     FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

//     FirebaseMessaging.onMessage.listen((event) {
//       final notification = event.notification;
//       if (notification == null) return;
//       _localNotification.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             _andriodChannel.id,
//             _andriodChannel.name,
//             channelDescription: _andriodChannel.description,
//             importance: _andriodChannel.importance,
//             color: Colors.blue,
//             playSound: true,
//             icon: "@drawable/ic_launcher",
//           ),
//         ),
//         payload: event.data.toString(),
//       );
//     });
//   }

//   Future initLocalNotification() async {
//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//             android: AndroidInitializationSettings("@drawable/ic_launcher"));
//     await _localNotification.initialize(initializationSettings);
//   }
// }
