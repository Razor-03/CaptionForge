import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // print("Tile: ${message.notification!.title}");
  // print("Body: ${message.notification!.body}");
  // print("Data: ${message.data}");
}

void handleMessage(RemoteMessage message) {
  if (message.notification == null) return;
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final _andriodChannel = const AndroidNotificationChannel(
    "high_importance_channel",
    "High Importance Notification",
    description: "This channel is used for important notifications.",
    importance: Importance.high,
  );

  final _localNotification = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await initPushNotification();
    await initLocalNotification();
  }

  Future initPushNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message);
    });
    // FirebaseMessaging.instance
    //     .getInitialMessage()
    //     .then((message) => handleMessage(message!));

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    FirebaseMessaging.onMessage.listen((event) {
      final notification = event.notification;
      if (notification == null) return;
      showLocalNotification(
        notification.title!,
        notification.body!,
        event.data['screen'],
      );
    });
  }

  Future initLocalNotification() async {
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/launcher_icon"));
    await _localNotification.initialize(
      initializationSettings,
    );
  }

  void showLocalNotification(String title, String? body, String? payload) {
    _localNotification.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _andriodChannel.id,
          _andriodChannel.name,
          channelDescription: _andriodChannel.description,
          importance: _andriodChannel.importance,
          color: Colors.blue,
          playSound: true,
          icon: "@mipmap/launcher_icon",
        ),
      ),
      payload: payload,
    );
  }

  Future<void> displayDownloadProgressNotification(double progress) async {
    final int progressPercentage = (progress * 100).toInt();
    final String notificationMessage = (progressPercentage < 100)
        ? 'Download Progress: $progressPercentage%'
        : 'Download Finished';
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _andriodChannel.id,
      'Download Progress  ${progress.toInt() * 100}',
      channelDescription: 'Shows download progress',
      importance: Importance.high,
      priority: Priority.high,
      channelShowBadge: true,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercentage,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotification.show(
      0,
      notificationMessage,
      'Downloading Video',
      platformChannelSpecifics,
      payload: 'download_progress',
    );
  }
}
