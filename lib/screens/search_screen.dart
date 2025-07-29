import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talabak_express/screens/pharmacy_details_screen.dart';
import 'package:talabak_express/screens/restaurant_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> results = [];

    // Search in restaurants
    QuerySnapshot restaurantsSnapshot = await FirebaseFirestore.instance
        .collection('entities')
        .doc('restaurants')
        .collection('items')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    results.addAll(restaurantsSnapshot.docs.map((doc) => {
      'type': 'restaurant',
      'id': doc.id,
      'name': doc['name'],
      'deliveryTime': doc['deliveryTime'],
      'imageUrl': doc['imageUrl'],
    }));

    // Search in pharmacies
    QuerySnapshot pharmaciesSnapshot = await FirebaseFirestore.instance
        .collection('entities')
        .doc('pharmacies')
        .collection('items')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    results.addAll(pharmaciesSnapshot.docs.map((doc) => {
      'type': 'pharmacy',
      'id': doc.id,
      'name': doc['name'],
      'deliveryTime': doc['deliveryTime'],
      'imageUrl': doc['imageUrl'],
    }));

    // Search in stores
    QuerySnapshot storesSnapshot = await FirebaseFirestore.instance
        .collection('entities')
        .doc('stores')
        .collection('items')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    results.addAll(storesSnapshot.docs.map((doc) => {
      'type': 'store',
      'id': doc.id,
      'name': doc['name'],
      'deliveryTime': doc['deliveryTime'],
      'imageUrl': doc['imageUrl'],
    }));

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _navigateToDetails(Map<String, dynamic> result) {
    if (result['type'] == 'pharmacy') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PharmacyDetailsScreen(
            pharmacyId: result['id'],
            pharmacyName: result['name'],
            imageUrl: result['imageUrl'],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailsScreen(
            entityId: result['id'],
            entityType: result['type'] == 'restaurant' ? 'restaurants' : 'stores',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xff112b16),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث عن مطعم، صيدلية، أو منتج...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: Icon(Icons.clear, color: Colors.grey),
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            onChanged: _performSearch,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? const Center(
          child: Text('لا توجد نتائج مطابقة',
              textDirection: TextDirection.rtl))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              onTap: () => _navigateToDetails(result),
              leading: Image.network(
                result['imageUrl'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  result['type'] == 'pharmacy'
                      ? Icons.local_pharmacy
                      : Icons.restaurant,
                  size: 30,
                ),
              ),
              title: Text(
                result['name'],
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.right,
              ),
              subtitle: Text(
                result['deliveryTime'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ),
          );
        },
      ),
    );
  }
}