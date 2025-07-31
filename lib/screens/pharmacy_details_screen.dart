import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Service/notification_service.dart';
import 'map_bounds.dart';
import 'map_constants.dart';
import 'map_utils.dart';
final FirebaseAuth _auth = FirebaseAuth.instance;


class PharmacyDetailsScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;
  final String imageUrl;

  const PharmacyDetailsScreen({
    Key? key,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _PharmacyDetailsScreenState createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  File? _prescriptionImage;
  bool _isUploading = false;
  bool _isSubmittingOrder = false;
  LatLng? _selectedLocation;
  String? _locationAddress;
  bool _isGettingLocation = false;
  bool _showMap = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _showDeliveryInfoDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'معلومات التوصيل',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالكامل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'العنوان التفصيلي',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              _buildLocationSection(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty ||
                  _phoneController.text.isEmpty ||
                  _addressController.text.isEmpty) {
                Fluttertoast.showToast(
                  msg: 'الرجاء إدخال جميع الحقول المطلوبة',
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff112b16),
            ),
            child: const Text('تأكيد الطلب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ??
        false;
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
                    });
                    await _getAddressFromLatLng(
                      selectedLocation.latitude,
                      selectedLocation.longitude,
                    );
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('تحديد على الخريطة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _locationAddress = "${place.street}, ${place.locality}, ${place.country}";
          _addressController.text = _locationAddress!;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'حدث خطأ أثناء الحصول على العنوان: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _prescriptionImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImageToImgBB() async {
    if (_prescriptionImage == null) {
      throw Exception('الرجاء اختيار صورة الروشتة');
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = '2152c491ff31e06c6614b5e849328e39'
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            _prescriptionImage!.path,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = String.fromCharCodes(responseData);
      final jsonResponse = http.Response(result, response.statusCode);

      if (jsonResponse.statusCode == 200) {
        final imageUrl = json.decode(jsonResponse.body)['data']['url'];
        return imageUrl;
      } else {
        throw Exception('فشل في رفع الصورة');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'فشل في رفع الصورة: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      rethrow;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_isSubmittingOrder || _prescriptionImage == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Fluttertoast.showToast(msg: 'يجب تسجيل الدخول أولاً');
      return;
    }

    final shouldProceed = await _showDeliveryInfoDialog(context);
    if (!shouldProceed) return;

    setState(() {
      _isSubmittingOrder = true;
    });

    try {
      final imageUrl = await _uploadImageToImgBB();

      final orderData = {
        'userId': currentUser.uid,
        'userName': _nameController.text,
        'deliveryPhone': _phoneController.text,
        'userEmail': currentUser.email,
        'pharmacyId': widget.pharmacyId,
        'pharmacyName': widget.pharmacyName,
        'pharmacyImageUrl': widget.imageUrl,
        'notes': _notesController.text,
        'prescriptionImageUrl': imageUrl,
        'status': 'pending',
        'orderType': 'pharmacy',
        'orderTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'total': 0,
        'deliveryAddress': _addressController.text,
        'deliveryInfo': {
          'address': _addressController.text,
          'status': 'pending',
          'assignedTo': null,
          'assignedAt': null,
        },
        'coordinates': _selectedLocation != null
            ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude)
            : null,
      };

      final batch = FirebaseFirestore.instance.batch();

      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      batch.set(orderRef, orderData);

      final pharmacyOrderRef = FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacyId)
          .collection('orders')
          .doc(orderRef.id);
      batch.set(pharmacyOrderRef, orderData);

      final userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('orders')
          .doc(orderRef.id);
      batch.set(userOrderRef, orderData);

      await batch.commit();

      await NotificationService.sendAdminNotification(
        'طلب جديد',
        'تم استلام طلب جديد رقم #${orderRef.id}',
        orderRef.id,
        'restaurant', // أو 'delivery' أو 'pharmacy' حسب نوع الطلب
      );

      await NotificationService.sendUserNotification(
        _auth.currentUser!.uid,
        'تم استلام طلبك',
        'شكراً لك! تم استلام طلبك رقم #${orderRef.id}',
        orderRef.id,
        'restaurant', // أو 'delivery' أو 'pharmacy' حسب نوع الطلب
      );

      Fluttertoast.showToast(
        msg: 'تم إرسال الطلب بنجاح!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );

      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _notesController.clear();
      setState(() {
        _prescriptionImage = null;
        _selectedLocation = null;
        _locationAddress = null;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'فشل في إرسال الطلب: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      setState(() {
        _isSubmittingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'pharmacy-${widget.pharmacyId}',
                child: Image.network(
                  widget.imageUrl ?? 'assets/talabak.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.blue[800],
                    child: const Center(
                      child: Icon(
                        Icons.local_pharmacy,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('entities')
                  .doc('pharmacies')
                  .collection('items')
                  .doc(widget.pharmacyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('الصيدلية غير موجودة'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                return Column(
                  children: [
                    _buildInfoSection(data, context),
                    if (data['categories'] != null)
                      _buildCategoriesSection(context, data['categories']),
                    _buildOrderSection(context),
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

  Widget _buildOrderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'إرسال طلب',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),

              // Prescription Image Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'صورة الروشتة *',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'مطلوب رفع صورة الروشتة',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text('رفع صورة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_prescriptionImage != null) ...[
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _prescriptionImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _prescriptionImage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ] else if (_isUploading) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _prescriptionImage == null
                      ? null
                      : () async {
                    if (_prescriptionImage != null) {
                      await _submitOrder();
                    }
                  },
                  child: _isSubmittingOrder
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'إرسال الطلب',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _prescriptionImage == null
                        ? Colors.grey
                        : const Color(0xff112b16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    data['name'] ?? widget.pharmacyName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.local_pharmacy, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
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
              if (data['is24Hours'] == true) ...[
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'خدمة 24 ساعة',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.warning, color: Colors.red[800]),
                    ],
                  ),
                ),
              ],
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
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Icon(icon, color: Colors.blue, size: 20),
      ],
    );
  }

  Widget _buildCategoriesSection(
      BuildContext context,
      List<dynamic> categories,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'الفئات المتوفرة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('categories')
                      .doc(categories[index])
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildCategoryPlaceholder();
                    }
                    final category =
                    snapshot.data!.data() as Map<String, dynamic>;
                    return _buildCategoryItem(category, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      Map<String, dynamic> category,
      BuildContext context,
      ) {
    return GestureDetector(
      onTap: () {
        // Navigate to category products
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  category['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.blue[300],
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] ?? '',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 8),
          Container(width: 50, height: 10, color: Colors.grey[200]),
        ],
      ),
    );
  }
}