import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talabak_express/screens/offer_detail_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String entityId;
  final String entityType;

  const RestaurantDetailsScreen({
    Key? key,
    required this.entityId,
    required this.entityType,
  }) : super(key: key);

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  Future<void> _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) async {
    int quantity = 1;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item['name'] ?? 'إضافة إلى السلة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${item['price']?.toString() ?? '0'} ج.م',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => quantity++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  onPressed: () async {
                    await _addToCart(context, {
                      ...item,
                      'quantity': quantity,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('إضافة إلى السلة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addToCart(BuildContext context, Map<String, dynamic> item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
          );
        }
        return;
      }

      // الحصول على بيانات المطعم أولاً
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('entities')
          .doc(widget.entityType)
          .collection('items')
          .doc(widget.entityId)
          .get();

      if (!restaurantDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('المطعم غير موجود')),
          );
        }
        return;
      }

      final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userData = await transaction.get(userDoc);
        List<dynamic> cart = userData['cart'] ?? [];

        bool exists = false;
        for (var i = 0; i < cart.length; i++) {
          if (cart[i]['id'] == item['id']) {
            cart[i]['quantity'] = (cart[i]['quantity'] ?? 0) + (item['quantity'] ?? 1);
            exists = true;
            break;
          }
        }

        if (!exists) {
          cart.add({
            'id': item['id'],
            'name': item['name'] ?? 'عنصر غير معروف',
            'price': item['price'] ?? 0,
            'imageUrl': item['imageUrl'] ?? 'https://via.placeholder.com/60',
            'quantity': item['quantity'] ?? 1,
            'restaurantId': widget.entityId,
            // استخدام arabicName إذا كان متوفراً، وإلا استخدام name
            'restaurantName': restaurantData['arabicName'] ?? restaurantData['name'] ?? widget.entityType,
            'restaurantImageUrl': restaurantData['imageUrl'] ?? '',
            'restaurantAddress': restaurantData['address'] ?? '',
            'restaurantPhone': restaurantData['phone'] ?? '',
          });
        }

        transaction.update(userDoc, {'cart': cart});
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة ${item['name']} إلى السلة'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('entities')
                      .doc(widget.entityType)
                      .collection('items')
                      .doc(widget.entityId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('المطعم غير موجود'));
                }

                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

                return Column(
                  children: [
                    _buildHeroSection(data, context),
                    _buildInfoSection(data),
                    _buildMenuSection(context),
                    _buildOffersSection(context),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textDirection: TextDirection.rtl,
        ),
        background: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('entities')
              .doc(widget.entityType)
              .collection('items')
              .doc(widget.entityId)
              .snapshots(),
          builder: (context, snapshot) {
            final imageUrl = snapshot.hasData
                ? (snapshot.data!.data() as Map<String, dynamic>)['imageUrl']
                : null;

            return Hero(
              tag: 'restaurant-${widget.entityId}',
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAppBarImage(),
              )
                  : _buildDefaultAppBarImage(),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildDefaultAppBarImage() {
    return Image.asset(
      'assets/talabak.png',
      fit: BoxFit.cover,
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> data, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                child: Text(
                  data['name'] ?? 'غير معروف',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Icon(Icons.star, color: Colors.amber[600], size: 20),
                  const SizedBox(width: 4),
                  // Text(
                  //   '4.8', // You might want to get this from your data
                  //   style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildInfoRow(
                Icons.location_on,
                'العنوان',
                data['address'] ?? 'غير متوفر',
              ),
              const Divider(height: 20),
              _buildInfoRow(Icons.phone, 'هاتف', data['phone'] ?? 'غير متوفر'),
              const Divider(height: 20),
              _buildInfoRow(
                Icons.access_time,
                'ساعات العمل',
                data['openingHours'] ?? 'غير متوفر',
              ),
              const Divider(height: 20),
              _buildInfoRow(
                Icons.delivery_dining,
                'وقت التوصيل',
                data['deliveryTime'] ?? 'غير متوفر',
              ),
              // const Divider(height: 20),
              // _buildInfoRow(
              //   Icons.money,
              //   'الحد الأدنى للطلب',
              //   '${data['minOrder'] ?? 'غير محدد'} ج.م',
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Icon(icon, color: Colors.deepOrange, size: 20),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'قائمة الطعام',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('entities')
                    .doc(widget.entityType)
                    .collection('items')
                    .doc(widget.entityId)
                    .collection('categories')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final categories = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category =
                      categories[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        category['name'] ?? 'غير معروف',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.deepOrange,
                      ),
                      children: [_buildMenuItems(categories[index].id)],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(String categoryId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('entities')
          .doc(widget.entityType)
          .collection('items')
          .doc(widget.entityId)
          .collection('categories')
          .doc(categoryId)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'لا توجد عناصر في هذه الفئة',
              textDirection: TextDirection.rtl,
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final item = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return InkWell(
              onTap: () {
                _showAddToCartDialog(context, {
                  ...item,
                  'id': snapshot.data!.docs[index].id,
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item['imageUrl'] ?? 'https://via.placeholder.com/60',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'] ?? 'غير معروف',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item['description'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    '${item['price']?.toString() ?? '0'} ج.م',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('offers')
              .where('restaurantId', isEqualTo: widget.entityId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final offers = snapshot.data!.docs;
        if (offers.isEmpty) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'العروض الخاصة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index].data() as Map<String, dynamic>;
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OfferDetailScreen(
                                    offerName: offer['name'],
                                    offerDescription: offer['description'],
                                    price: offer['price'].toString(),
                                    imageUrl: offer['imageUrl'],
                                    rating: offer['rating'].toString(),
                                  ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        offer['imageUrl'] ??
                                            'https://via.placeholder.com/60',
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.local_offer,
                                                      size: 40,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'خصم ${offer['discount'] ?? '0'}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      offer['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${offer['price']} ج.م',
                                          style: const TextStyle(
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (offer['originalPrice'] != null)
                                          Text(
                                            '${offer['originalPrice']} ج.م',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
