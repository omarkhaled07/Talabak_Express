import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final String orderType;

  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
    required this.orderType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل الطلب #$orderId',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff112b16),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('الطلب غير موجود'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildOrderHeader(orderData),
                const SizedBox(height: 16),
                _buildOrderDetails(orderData),
                if (orderType == 'delivery' || orderType == 'pharmacy') ...[
                  const SizedBox(height: 16),
                  _buildMapSection(orderData),
                ],
                if (orderType == 'pharmacy' && orderData['prescriptionImageUrl'] != null) ...[
                  const SizedBox(height: 16),
                  _buildPrescriptionImage(orderData['prescriptionImageUrl']),
                ],
                if (orderType == 'restaurant') ...[
                  const SizedBox(height: 16),
                  _buildCartItems(orderData['items']),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader(Map<String, dynamic> orderData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'طلب #$orderId',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'الحالة: ${orderData['status'] ?? 'غير معروف'}',
              style: TextStyle(
                fontSize: 16,
                color: orderData['status'] == 'pending' ? Colors.orange : Colors.green,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'التاريخ: ${_formatTimestamp(orderData['orderTime'])}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> orderData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'تفاصيل الطلب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const Divider(),
            if (orderData['userName'] != null)
              _buildInfoRow('الاسم', orderData['userName']),
            if (orderData['deliveryPhone'] != null)
              _buildInfoRow('رقم الهاتف', orderData['deliveryPhone']),
            if (orderData['deliveryAddress'] != null)
              _buildInfoRow('عنوان التوصيل', orderData['deliveryAddress']),
            if (orderData['notes'] != null && orderData['notes'].isNotEmpty)
              _buildInfoRow('ملاحظات', orderData['notes']),
            if (orderData['total'] != null)
              _buildInfoRow('الإجمالي', '${orderData['total'].toStringAsFixed(2)} ج.م'),
            if (orderType == 'restaurant' && orderData['restaurantInfo'] != null)
              _buildInfoRow('المطعم', orderData['restaurantInfo']['restaurantName'] ?? 'غير معروف'),
            if (orderType == 'pharmacy' && orderData['pharmacyName'] != null)
              _buildInfoRow('الصيدلية', orderData['pharmacyName']),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(Map<String, dynamic> orderData) {
    final GeoPoint? pickupLocation = orderData['pickupLocation'];
    final GeoPoint? dropoffLocation = orderData['dropoffLocation'] ?? orderData['coordinates'];

    if (pickupLocation == null && dropoffLocation == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'موقع التوصيل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: dropoffLocation != null
                      ? LatLng(dropoffLocation.latitude, dropoffLocation.longitude)
                      : LatLng(pickupLocation!.latitude, pickupLocation.longitude),
                  zoom: 15,
                ),
                markers: {
                  if (pickupLocation != null)
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: LatLng(pickupLocation.latitude, pickupLocation.longitude),
                      infoWindow: const InfoWindow(title: 'مكان الاستلام'),
                    ),
                  if (dropoffLocation != null)
                    Marker(
                      markerId: const MarkerId('dropoff'),
                      position: LatLng(dropoffLocation.latitude, dropoffLocation.longitude),
                      infoWindow: const InfoWindow(title: 'مكان التسليم'),
                    ),
                },
                onMapCreated: (controller) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionImage(String imageUrl) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'صورة الروشتة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems(List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'عناصر الطلب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const Divider(),
            ...items.map((item) => ListTile(
              title: Text(
                item['name'] ?? 'عنصر غير معروف',
                textDirection: TextDirection.rtl,
              ),
              subtitle: Text(
                'الكمية: ${item['quantity']} - السعر: ${item['price']?.toStringAsFixed(2)} ج.م',
                textDirection: TextDirection.rtl,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'غير محدد';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}