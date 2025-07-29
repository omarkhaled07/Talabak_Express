import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize FCM and request permissions
  static Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else {
      print('User denied notification permission');
    }

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification: ${message.notification?.title}');
      _saveNotificationToFirestore(
        message.notification?.title ?? 'No Title',
        message.notification?.body ?? 'No Body',
        message.data,
      );
    });

    // Handle notification opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened from background: ${message.data}');
      _handleNotificationNavigation(message.data);
    });

    // Handle notification when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.data}');
      _handleNotificationNavigation(initialMessage.data);
    }

    // Handle FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      await _updateUserFcmToken(token);
    });

    // Get and save initial FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _updateUserFcmToken(token);
    }
  }

  // Save notification to Firestore
  static Future<void> _saveNotificationToFirestore(
      String title, String body, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': user.uid,
      'title': title,
      'message': body,
      'orderId': data['orderId'] ?? '',
      'orderType': data['orderType'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Update user's FCM token in Firestore
  static Future<void> _updateUserFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  // Send admin notification
  static Future<void> sendAdminNotification(
      String title, String body, String orderId, String orderType) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': 'admin',
      'title': title,
      'message': body,
      'orderId': orderId,
      'orderType': orderType,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Send user notification
  static Future<void> sendUserNotification(
      String userId, String title, String body, String orderId, String orderType) async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      String? token = userDoc.data()!['fcmToken'];
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': title,
          'message': body,
          'orderId': orderId,
          'orderType': orderType,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Handle notification navigation
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Implement navigation logic in the app's navigator
    // This will be handled in the NotificationScreen
  }
}