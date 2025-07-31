import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'Service/notification_service.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/search_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
  playSound: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Google Maps (Android specific)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await AndroidGoogleMapsFlutter.useAndroidViewSurface;
    }

    // Initialize Notification Service
    await NotificationService.initialize();

    runApp(const MyApp());
  } catch (e) {
    print('Initialization Error: $e');
    runApp(const ErrorApp());
  }
}


Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings =
  InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification click
    },
  );

  // Create notification channel for Android 8.0+
  if (defaultTargetPlatform == TargetPlatform.android) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('حدث خطأ في تهيئة التطبيق', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeFirebaseMessaging() async {
  try {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // Save token to user document
    _saveFCMToken(token);

    // Handle token refresh
    messaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground Message: ${message.messageId}');
      await _showLocalNotification(message);
      await _saveNotificationToFirestore(message);
    });

    // Handle when app is opened from terminated state
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.messageId}');
      await _saveNotificationToFirestore(initialMessage);
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('FCM Error: $e');
  }
}

Future<void> _saveFCMToken(String? token) async {
  if (token == null) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  // Create notification details for Android
  AndroidNotificationDetails androidPlatformChannelSpecifics =
  const AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    showWhen: true,
    enableVibration: true,
  );

  // Create notification details for iOS
  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
  DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // Combine platform specific details
  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'إشعار جديد',
    message.notification?.body ?? '',
    platformChannelSpecifics,
    payload: message.data.toString(),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showLocalNotification(message);
  await _saveNotificationToFirestore(message);
}

Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final notificationData = {
      'title': message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
      'message': message.notification?.body ?? message.data['body'] ?? '',
      'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': message.data['type'] ?? 'general',
      'orderId': message.data['orderId'] ?? '',
      'data': message.data,
    };

    await firestore.collection('notifications').add(notificationData);
    print('Notification saved: ${notificationData['title']}');
  } catch (e) {
    print('Notification Save Error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talabak Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Tajawal',
      ),
      home: const RootScreen(),
      routes: {
        '/notifications': (context) => const NotificationScreen(),
        '/search': (context) => const SearchScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('حدث خطأ: ${snapshot.error}'),
            ),
          );
        }

        return snapshot.hasData ? const HomeScreen() : const WelcomeScreen();
      },
    );
  }
}