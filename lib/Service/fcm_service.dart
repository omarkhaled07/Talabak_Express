import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static const _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/talabak-express/messages:send';

  static Future<void> sendNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    final accountCredentials = ServiceAccountCredentials.fromJson(
      await rootBundle.loadString('assets/service_account.json'),
    );

    final authClient = await clientViaServiceAccount(accountCredentials, _scopes);

    final message = {
      "message": {
        "token": targetToken,
        "notification": {
          "title": title,
          "body": body,
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "type": "order",
        }
      }
    };

    final response = await authClient.post(
      Uri.parse(_fcmEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent!');
    } else {
      print('❌ Failed to send notification: ${response.body}');
    }
  }
}
