import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _setupFCM();
    await _setupLocalNotifications();
    _firebaseMessaging.onTokenRefresh.listen(_updateFCMToken);
  }

  static Future<void> _setupFCM() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permissions granted: \${settings.authorizationStatus}');

    final token = await _firebaseMessaging.getToken();
    if (token != null) await _updateFCMToken(token);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.instance.getInitialMessage().then(_handleBackgroundMessage);
  }

  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important app notifications.',
        importance: Importance.max,
        playSound: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> _updateFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
      print('FCM Token updated for user \${user.uid}');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: \${message.messageId}');
    await _saveNotification(message);
    await _showLocalNotification(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage? message) async {
    if (message == null) return;
    print('Background message opened: \${message.messageId}');
    await _saveNotification(message);
    _handleNotificationTap(message.data as String?);
  }

  static Future<void> _saveNotification(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notificationData = {
      'userId': user.uid,
      'title': message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
      'message': message.notification?.body ?? message.data['body'] ?? '',
      'orderId': message.data['orderId'] ?? '',
      'orderType': message.data['orderType'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'data': message.data,
    };

    await FirebaseFirestore.instance.collection('notifications').add(notificationData);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      android?.channelId ?? 'high_importance_channel',
      android?.channelId ?? 'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      showWhen: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: notification?.apple?.subtitle,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification?.title ?? 'إشعار جديد',
      notification?.body ?? '',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final orderId = data['orderId'];
      final orderType = data['orderType'];
      if (orderId != null && orderType != null) {
        print('Navigate to order \$orderId of type \$orderType');
      }
    } catch (e) {
      print('Error handling notification tap: \$e');
    }
  }

  static Future<String> _getProjectId() async {
    final file = File('assets/service_account.json');
    final jsonMap = jsonDecode(await file.readAsString());
    return jsonMap['project_id'];
  }

  static Future<AuthClient> _getAuthClient() async {
    final serviceAccount = File('assets/service_account.json');
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount.readAsStringSync());
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    return await clientViaServiceAccount(credentials, scopes);
  }

  static Future<void> _sendFCMV1(String token, String title, String body, String orderId, String orderType) async {
    final client = await _getAuthClient();
    final projectId = await _getProjectId();
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/\$projectId/messages:send');

    final message = {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'orderId': orderId,
          'orderType': orderType,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      }
    };

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    print('FCM V1 response: \${response.statusCode} - \${response.body}');
    client.close();
  }

  static Future<void> sendAdminNotification(String title, String body, String orderId, String orderType) async {
    try {
      final adminDoc = await FirebaseFirestore.instance.collection('users').doc('admin').get();
      if (adminDoc.exists && adminDoc.data()?['fcmToken'] != null) {
        final token = adminDoc.data()!['fcmToken'] as String;
        await _sendFCMV1(token, title, body, orderId, orderType);
      }
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': 'admin',
        'title': title,
        'message': body,
        'orderId': orderId,
        'orderType': orderType,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending admin notification: \$e');
    }
  }

  static Future<void> sendUserNotification(String userId, String title, String body, String orderId, String orderType) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()?['fcmToken'] != null) {
        final token = userDoc.data()!['fcmToken'] as String;
        await _sendFCMV1(token, title, body, orderId, orderType);
      }
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': body,
        'orderId': orderId,
        'orderType': orderType,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending user notification: \$e');
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
