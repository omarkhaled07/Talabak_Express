import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن التطبيق'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // شعار التطبيق
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.white54,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/talabak.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // اسم التطبيق
            const Text(
              'طلبك اكسبريس',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 10),

            // وصف التطبيق
            const Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'تطبيق طلبك اكسبريس هو الحل الأمثل لطلب الطعام من مطاعمك المفضلة بكل سهولة وسرعة. '
                          'نقدم لك تجربة فريدة وسهلة لطلب ما تشتهيه من أطباق لذيذة من أفضل المطاعم في مدينتك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'نسعى دائماً لتقديم أفضل خدمة لعملائنا الكرام مع ضمان جودة الطعام وسرعة التوصيل.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // معلومات الاتصال
            // _buildInfoCard(
            //   title: 'معلومات التواصل',
            //   children: [
            //     _buildContactItem(
            //       icon: Icons.email,
            //       text: 'info@talabak.com',
            //       onTap: () => _launchEmail('info@talabak.com'),
            //     ),
            //     _buildContactItem(
            //       icon: Icons.phone,
            //       text: '0123456789',
            //       onTap: () => _launchPhoneCall('0123456789'),
            //     ),
            //     _buildContactItem(
            //       icon: Icons.language,
            //       text: 'www.talabak.com',
            //       onTap: () => _launchWebsite('https://www.talabak.com'),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 20),

            // إصدار التطبيق
            const Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),

            // حقوق النشر
            const Text(
              '© 2025 طلبك اكسبريس. جميع الحقوق محفوظة.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}