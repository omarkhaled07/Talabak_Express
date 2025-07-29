import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talabak_express/widgets/restaurant_card.dart';
import 'package:talabak_express/screens/restaurant_details_screen.dart';

class SectionRestaurantsScreen extends StatelessWidget {
  final String sectionTitle;

  const SectionRestaurantsScreen({
    Key? key,
    required this.sectionTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        centerTitle: true,
        title: Text(
          sectionTitle,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff112b16),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entities')
            .doc('restaurants')
            .collection('items')
            .where('tags', arrayContains: sectionTitle.toLowerCase())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا توجد مطاعم متاحة',
                  textDirection: TextDirection.rtl),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return RestaurantCard(
                name: data['name'] ?? 'غير معروف',
                arabicName: data['arabicName'] ?? '',
                deliveryTime: data['deliveryTime'] ?? 'غير محدد',
                imageUrl: data['imageUrl'] ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailsScreen(
                        entityId: docs[index].id,
                        entityType: 'restaurants',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}