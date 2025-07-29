// أضف هذا الملف الجديد في مجلد screens
// support_options_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'support_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';


class SupportOptionsScreen extends StatelessWidget {
  const SupportOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'كيف تريد التواصل مع الدعم الفني؟',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // خيار إنشاء تذكرة دعم
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.support_agent, size: 30),
                title: const Text(
                  'إنشاء تذكرة دعم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'سيتم الرد خلال 24 ساعة',
                  style: TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportScreen(),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            // خيار التواصل عبر الواتساب
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 30,
                  color: Colors.green,
                ),
                title: const Text(
                  'التواصل عبر الواتساب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'للحصول على دعم فوري',
                  style: TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final link = WhatsAppUnilink(
                    phoneNumber: '201098757441',
                    text: 'مرحباً، أريد المساعدة بخصوص التطبيق',
                  );

                  try {
                    await launchUrl(link.asUri());
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: ${e.toString()}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
