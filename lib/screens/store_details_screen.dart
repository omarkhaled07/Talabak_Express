import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreDetailsScreen extends StatelessWidget {
  final String storeId;
  final String storeName;
  final String imageUrl;

  const StoreDetailsScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName, textDirection: TextDirection.rtl),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entities')
            .doc('stores')
            .collection('items')
            .doc(storeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('المتجر غير موجود'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                Image.network(
                  data['imageUrl'] ?? imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.store, size: 100),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        data['name'] ?? storeName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'العنوان: ${data['address'] ?? 'غير متوفر'}',
                        style: const TextStyle(fontSize: 16),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'هاتف: ${data['phone'] ?? 'غير متوفر'}',
                        style: const TextStyle(fontSize: 16),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ساعات العمل: ${data['openingHours'] ?? 'غير متوفر'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'وقت التوصيل: ${data['deliveryTime'] ?? 'غير متوفر'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}