import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talabak_express/screens/restaurant_details_screen.dart';
import 'package:talabak_express/screens/pharmacy_details_screen.dart';
import '../widgets/SectionItem.dart';

class GenericListScreen extends StatelessWidget {
  final String title;
  final String entityType;
  final bool isFeatured;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.entityType,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white ,fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff112b16),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              isFeatured
                  ? FirebaseFirestore.instance
                      .collection('entities')
                      .doc(entityType)
                      .collection('items')
                      .where('isFeatured', isEqualTo: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('entities')
                      .doc(entityType)
                      .collection('items')
                      .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final docs = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildListItem(context, docs[index].id, data);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (entityType == 'pharmacies') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PharmacyDetailsScreen(
                      pharmacyId: id,
                      pharmacyName: data['name'] ?? 'غير معروف',
                      imageUrl:
                          data['imageUrl'] ?? 'https://via.placeholder.com/60',
                    ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => RestaurantDetailsScreen(
                      entityId: id,
                      entityType: entityType,
                    ),
              ),
            );
          }
        },
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(
                      data['imageUrl'] ?? 'https://via.placeholder.com/60',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'غير معروف',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff112b16),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (data['description'] != null)
                      Text(
                        data['description']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (data['deliveryTime'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['deliveryTime']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Rating/Favorite
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (data['rating'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            data['rating'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.star, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.grey[400]),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff112b16)),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد عناصر متاحة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك المحاولة مرة أخرى لاحقاً',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
