import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talabak_express/screens/offer_detail_screen.dart';

class RestaurantOffersScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantArabicName;
  final String estimatedTime;

  const RestaurantOffersScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantArabicName,
    required this.estimatedTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantArabicName),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Handle cart button press
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .where('restaurantId', isEqualTo: restaurantId)
            .where('entityType', isEqualTo: 'restaurants')
            .where('restaurantId', isEqualTo: restaurantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد عروض متاحة'));
          }

          final offers = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$restaurantName - $estimatedTime',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'العروض المتاحة:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index].data() as Map<String, dynamic>;
                      return _buildOfferItem(context, offer);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferItem(BuildContext context, Map<String, dynamic> offer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferDetailScreen(
              offerName: offer['name'] ?? 'عرض',
              offerDescription: offer['description'] ?? 'لا يوجد وصف',
              price: offer['price']?.toString() ?? '0',
              imageUrl: offer['imageUrl'] ?? '',
              rating: offer['rating']?.toString() ?? '0',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          children: [
            Image.network(
              offer['imageUrl'] ?? '',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.fastfood, size: 50),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    offer['name'] ?? 'عرض',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    '${offer['price']?.toString() ?? '0'} ج.م',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                // Add to cart functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}