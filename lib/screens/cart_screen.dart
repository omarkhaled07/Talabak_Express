import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../Service/notification_service.dart';
import 'map_bounds.dart';
import 'map_constants.dart';
import 'map_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  LatLng? _selectedLocation;
  String _locationAddress = '';
  bool _useCurrentLocation = false;
  bool _isLocationLoading = false;
  bool _isGettingLocation = false;
  bool _showMap = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'الرجاء تفعيل خدمة الموقع');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'تم رفض إذن الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: 'الإذن مرفوض بشكل دائم، يرجى تغييره من الإعدادات');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      if (!MapBounds.isWithinBounds(location)) {
        Fluttertoast.showToast(
          msg: 'موقعك الحالي خارج نطاق التوصيل',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      setState(() {
        _selectedLocation = location;
        _showMap = true;
      });

      await _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      Fluttertoast.showToast(msg: 'حدث خطأ أثناء الحصول على الموقع: ${e.toString()}');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عربة التسوق', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff112b16),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _clearCart,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyCart();
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var cartItems = userData['cart'] as List<dynamic>? ?? [];

          if (cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Image.asset(
                          item['assets/talabak.png'] ?? 'assets/talabak.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item['name'] ?? 'عنصر غير معروف'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['price']?.toStringAsFixed(2)} ج.م'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(index, -1),
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(index, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildCheckoutSection(userData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'عربة التسوق فارغة',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff112b16),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'تصفح المنتجات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(Map<String, dynamic> userData) {
    double total = _calculateTotal(userData['cart'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي:', style: TextStyle(fontSize: 18)),
              Text(
                '${total.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCheckoutDialog(total, userData['cart']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff112b16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إتمام الشراء', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal(List<dynamic> cartItems) {
    return cartItems.fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  Future<void> _updateQuantity(int index, int change) async {
    try {
      var userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid);

      var userData = await userDoc.get();
      var cartItems = List.from(userData.data()?['cart'] ?? []);

      if (index >= 0 && index < cartItems.length) {
        int newQuantity = cartItems[index]['quantity'] + change;

        if (newQuantity <= 0) {
          cartItems.removeAt(index);
        } else {
          cartItems[index]['quantity'] = newQuantity;
        }

        await userDoc.set({
          'cart': cartItems,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeItem(int index) async {
    try {
      var userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid);

      var userData = await userDoc.get();
      var cartItems = List.from(userData['cart'] ?? []);

      if (index >= 0 && index < cartItems.length) {
        cartItems.removeAt(index);
        await userDoc.update({'cart': cartItems});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  Future<void> _clearCart() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'cart': []});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  void _showCheckoutDialog(double total, List<dynamic> cartItems) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إتمام الطلب'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الإجمالي: ${total.toStringAsFixed(2)} ج.م'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationSection(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => _placeOrder(total, cartItems),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff112b16),
                ),
                child: const Text('تأكيد الطلب'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeOrder(double total, List<dynamic> cartItems) async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال جميع المعلومات المطلوبة')),
      );
      return;
    }

    try {
      var firstItem = cartItems.first;
      var restaurantInfo = {
        'restaurantId': firstItem['restaurantId'],
        'restaurantName': firstItem['restaurantName'],
        'restaurantImageUrl': firstItem['restaurantImageUrl'],
        'restaurantAddress': firstItem['restaurantAddress'],
        'restaurantPhone': firstItem['restaurantPhone'],
      };

      var orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': _auth.currentUser?.uid,
        'userName': _nameController.text,
        'items': cartItems,
        'total': total,
        'status': 'pending',
        'orderType': 'restaurant',
        'orderTime': Timestamp.now(),
        'deliveryName': _nameController.text,
        'deliveryPhone': _phoneController.text,
        'deliveryAddress': _addressController.text,
        'location': _selectedLocation != null
            ? GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        )
            : null,
        'locationAddress': _locationAddress.isNotEmpty ? _locationAddress : null,
        'restaurantInfo': restaurantInfo,
      });

      await orderRef.update({'orderId': orderRef.id});

      await NotificationService.sendAdminNotification(
        'طلب مطعم جديد',
        'تم استلام طلب مطعم جديد رقم #${orderRef.id}',
        orderRef.id,
        'restaurant',
      );

      String? userToken;
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        userToken = userDoc.data()!['fcmToken'];
      }

      if (userToken != null && userToken.isNotEmpty) {
        await NotificationService.sendUserNotification(
          _auth.currentUser!.uid,
          'تم استلام طلبك',
          'شكراً لك! تم استلام طلب المطعم رقم #${orderRef.id}',
          orderRef.id,
          'restaurant',
        );
      }

      await _clearCart();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تقديم طلبك بنجاح!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'تحديد الموقع',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        if (_selectedLocation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _locationAddress ?? 'جارٍ تحميل العنوان...',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.location_on),
                label: const Text('تحديد الموقع الحالي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final selectedLocation = await MapUtils.showMapPicker(
                    context: context,
                    initialLocation: _selectedLocation,
                  );
                  if (selectedLocation != null) {
                    setState(() {
                      _selectedLocation = selectedLocation;
                      _showMap = !_showMap;
                    });
                    await _getAddressFromLatLng(
                      selectedLocation.latitude,
                      selectedLocation.longitude,
                    );
                  }
                },
                icon: Icon(_showMap ? Icons.map_rounded : Icons.map_outlined),
                label: Text(_showMap ? 'إخفاء الخريطة' : 'تحديد على الخريطة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
        if (_showMap && _selectedLocation != null)
          SizedBox(
            height: 150,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              onMapCreated: (controller) {},
              myLocationEnabled: false,
            ),
          ),
      ],
    );
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _locationAddress = "${place.street}, ${place.locality}, ${place.country}";
          _addressController.text = _locationAddress;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'حدث خطأ أثناء الحصول على العنوان: ${e.toString()}');
    }
  }
}