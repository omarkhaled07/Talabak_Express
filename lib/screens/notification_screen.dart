import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../Service/notification_service.dart';
import 'order_details_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {});
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToOrderDetails(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _navigateToOrderDetails(message.data);
      }
    });
  }

  void _navigateToOrderDetails(Map<String, dynamic> data) {
    if (data['orderId'] != null && data['orderType'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(
            orderId: data['orderId'],
            orderType: data['orderType'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        title: const Text('الإشعارات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xff112b16),
        elevation: 4,
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leadingWidth: 80,
        leading: TextButton(
          onPressed: currentUser != null
              ? () async {
            await NotificationService.markAllAsRead(currentUser!.uid);
            setState(() {});
          }
              : null,
          child: const Text(
            'قراءة الكل',
            style: TextStyle(color: Colors.amber, fontSize: 14),
          ),
        ),
      ),
      body: currentUser != null
          ? NotificationList(userId: currentUser!.uid)
          : const Center(child: Text('يجب تسجيل الدخول لعرض الإشعارات')),
    );
  }
}

class NotificationList extends StatelessWidget {
  final String userId;

  const NotificationList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد إشعارات متاحة',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final data = notification.data() as Map<String, dynamic>;
            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                notification.reference.delete();
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: data['isRead'] == false ? Colors.green[100] : Colors.grey[200],
                    child: Icon(
                      Icons.notifications,
                      color: data['isRead'] == false ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'بدون عنوان',
                    style: TextStyle(
                      fontWeight: data['isRead'] == false ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['message'] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(data['timestamp']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: data['isRead'] == false
                      ? const Icon(Icons.circle, color: Colors.red, size: 12)
                      : null,
                  onTap: () {
                    NotificationService.markAsRead(notification.id);
                    if (data['orderId'] != null && data['orderType'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(
                            orderId: data['orderId'],
                            orderType: data['orderType'],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'غير محدد';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    }
  }
}