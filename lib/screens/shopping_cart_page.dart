import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingCartPage extends StatelessWidget {
  const ShoppingCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عربة التسوق', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body:
          userId == null
              ? const Center(child: Text('يجب تسجيل الدخول لعرض عربة التسوق'))
              : StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('cart')
                        .doc('items')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, size: 50),
                          SizedBox(height: 16),
                          Text('عربة التسوق فارغة'),
                        ],
                      ),
                    );
                  }

                  final cartData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final items = cartData['items'] as List<dynamic>? ?? [];

                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, size: 50),
                          SizedBox(height: 16),
                          Text('عربة التسوق فارغة'),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index] as Map<String, dynamic>;
                            return ListTile(
                              leading: Image.network(
                                item['imageUrl'] ?? '',
                                width: 50,
                                height: 50,
                              ),
                              title: Text(item['name'] ?? ''),
                              subtitle: Text(
                                '${item['price']} ج.م × ${item['quantity']}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Remove item from cart
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الإجمالي:'),
                            Text('${cartData['total'] ?? 0} ج.م'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () {
                            // Checkout
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('إتمام الطلب'),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
