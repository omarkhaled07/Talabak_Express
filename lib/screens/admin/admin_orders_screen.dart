import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  void _updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('deliveryRequests')
        .doc(orderId)
        .update({'status': newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث حالة الطلب إلى $newStatus', textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xff112b16),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('deliveryRequests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات', textDirection: TextDirection.rtl));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('طلب رقم: ${order.id}', textDirection: TextDirection.rtl),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('مكان الاستلام: ${data['pickupAddress'] ?? 'غير متوفر'}', textDirection: TextDirection.rtl),
                      Text('مكان التسليم: ${data['dropoffAddress'] ?? 'غير متوفر'}', textDirection: TextDirection.rtl),
                      Text('ملاحظات: ${data['notes'] ?? 'لا توجد'}', textDirection: TextDirection.rtl),
                      Text('القيمة: ${data['value'] ?? 'غير محدد'}', textDirection: TextDirection.rtl),
                      Text('الحالة: ${data['status'] ?? 'غير محدد'}', textDirection: TextDirection.rtl),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: data['status'] ?? 'pending',
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                      DropdownMenuItem(value: 'in_progress', child: Text('قيد التوصيل')),
                      DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                      DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateOrderStatus(context, order.id, value);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}