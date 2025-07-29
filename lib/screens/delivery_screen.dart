import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Service/notification_service.dart';
import 'map_picker_screen.dart';
import 'map_utils.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final TextEditingController notesController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController _pickupAddressController = TextEditingController();
  final TextEditingController _dropoffAddressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  String? pickupAddress;
  String? dropoffAddress;
  double orderValue = 0.0;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  Future<void> _showAddressInputSheet(String type) async {
    final controller = type == 'pickup' ? _pickupAddressController : _dropoffAddressController;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                type == 'pickup' ? 'مكان الاستلام' : 'مكان التسليم',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'أدخل العنوان هنا',
                  hintTextDirection: TextDirection.rtl,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_pin),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (type == 'pickup') {
                      pickupAddress = controller.text.isEmpty ? null : controller.text;
                      _pickupLocation = null;
                    } else {
                      dropoffAddress = controller.text.isEmpty ? null : controller.text;
                      _dropoffLocation = null;
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff112b16),
                ),
                child: const Text(
                  'تأكيد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectLocationOnMap(String type) async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapPicker(
          initialLocation: type == 'pickup' ? _pickupLocation : _dropoffLocation,
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        if (type == 'pickup') {
          _pickupLocation = selectedLocation;
          pickupAddress = 'موقع على الخريطة';
          _pickupAddressController.clear();
        } else {
          _dropoffLocation = selectedLocation;
          dropoffAddress = 'موقع على الخريطة';
          _dropoffAddressController.clear();
        }
      });
    }
  }

  Future<void> _submitDeliveryRequest() async {
    if ((pickupAddress == null && _pickupLocation == null) ||
        (dropoffAddress == null && _dropoffLocation == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد مكان الاستلام ومكان التسليم', textDirection: TextDirection.rtl)),
      );
      return;
    }

    final phoneNumber = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'رقم الهاتف',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'أدخل رقم الهاتف',
                  hintTextDirection: TextDirection.rtl,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_phoneController.text.isEmpty) {
                    Navigator.pop(context, null);
                  } else {
                    Navigator.pop(context, _phoneController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff112b16),
                ),
                child: const Text(
                  'تأكيد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الهاتف', textDirection: TextDirection.rtl)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً', textDirection: TextDirection.rtl)),
        );
        return;
      }

      orderValue = double.tryParse(valueController.text) ?? 0.0;

      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'deliveryPhone': phoneNumber,
        'pickupAddress': pickupAddress,
        'deliveryAddress': dropoffAddress,
        'pickupLocation': _pickupLocation != null
            ? GeoPoint(_pickupLocation!.latitude, _pickupLocation!.longitude)
            : null,
        'dropoffLocation': _dropoffLocation != null
            ? GeoPoint(_dropoffLocation!.latitude, _dropoffLocation!.longitude)
            : null,
        'notes': notesController.text,
        'orderValue': orderValue,
        'total': orderValue,
        'status': 'pending',
        'type': 'delivery',
        'orderType': 'delivery',
        'orderTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await orderRef.update({'orderId': orderRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب التوصيل بنجاح', textDirection: TextDirection.rtl)),
      );

      await NotificationService.sendAdminNotification(
        'طلب توصيل جديد',
        'تم استلام طلب توصيل جديد رقم #${orderRef.id}',
        orderRef.id,
        'delivery',
      );

      await NotificationService.sendUserNotification(
        user.uid,
        'تم استلام طلبك',
        'شكراً لك! تم استلام طلب التوصيل رقم #${orderRef.id}',
        orderRef.id,
        'delivery',
      );

      notesController.clear();
      valueController.clear();
      _pickupAddressController.clear();
      _dropoffAddressController.clear();
      _phoneController.clear();
      setState(() {
        pickupAddress = null;
        dropoffAddress = null;
        _pickupLocation = null;
        _dropoffLocation = null;
        orderValue = 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e', textDirection: TextDirection.rtl)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    valueController.dispose();
    _pickupAddressController.dispose();
    _dropoffAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        centerTitle: true,
        title: const Text(
          "اطلب دليفرى",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff112b16),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/talabak.png',
                height: 200,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              textDirection: TextDirection.rtl,
              'ملاحظات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'اكتب ملاحظاتك هنا او تفاصيل معينة عن طلبك ...',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'قيمة الطلب ان وجد',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddressInputSheet('pickup'),
                    icon: const Icon(Icons.location_pin),
                    label: Text(
                      pickupAddress == null && _pickupLocation == null
                          ? 'تحديد مكان الاستلام'
                          : pickupAddress ?? 'موقع على الخريطة',
                      style: const TextStyle(color: Colors.white),
                      textDirection: TextDirection.rtl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () => _selectLocationOnMap('pickup'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddressInputSheet('dropoff'),
                    icon: const Icon(Icons.location_pin),
                    label: Text(
                      dropoffAddress == null && _dropoffLocation == null
                          ? 'تحديد مكان التسليم'
                          : dropoffAddress ?? 'موقع على الخريطة',
                      style: const TextStyle(color: Colors.white),
                      textDirection: TextDirection.rtl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () => _selectLocationOnMap('dropoff'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitDeliveryRequest,
              icon: const Icon(Icons.rocket_launch),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'تنفيذ الطلب',
                style: TextStyle(color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}