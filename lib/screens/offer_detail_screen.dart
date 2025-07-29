import 'package:flutter/material.dart';

class OfferDetailScreen extends StatelessWidget {
  final String offerName;
  final String offerDescription;
  final String price;
  final String imageUrl;
  final String rating;

  OfferDetailScreen({
    required this.offerName,
    required this.offerDescription,
    required this.price,
    required this.imageUrl,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(offerName),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to Cart or handle cart functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offer Image
            Image.asset(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),

            // Offer Name & Rating
            SizedBox(height: 16.0),
            Text(
              offerName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 20),
                SizedBox(width: 4.0),
                Text(rating, style: TextStyle(fontSize: 16)),
              ],
            ),

            // Offer Price
            SizedBox(height: 16.0),
            Text(
              '$price ج.م',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),

            // Offer Description
            SizedBox(height: 16.0),
            Text(
              'الوصف: $offerDescription',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            // Quantity Selector
            SizedBox(height: 16.0),
            Row(
              children: [
                Text(
                  'الكمية:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8.0),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 24),
                      onPressed: () {
                        // Decrease quantity logic
                      },
                    ),
                    Text('1', style: TextStyle(fontSize: 18)),
                    IconButton(
                      icon: Icon(Icons.add, size: 24),
                      onPressed: () {
                        // Increase quantity logic
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Add to Cart Button
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  // Handle adding to cart
                },
                child: Text(
                  'اضف الى عربة التسوق',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}