import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلباتى', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xff112b16),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 360;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('orderTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد طلبات سابقة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var order = snapshot.data!.docs[index];
                    var data = order.data() as Map<String, dynamic>;
                    String arabicStatus = _getArabicStatus(data['status']);
                    bool isCompleted = data['status'] == 'completed';
                    bool hasRated = data['deliveryRating'] != null;

                    return Card(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: 100,
                            maxHeight: isSmallScreen ? 250 : 300),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(data['status']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          arabicStatus,
                                          style: const TextStyle(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        'رقم الطلب: #${order.id.substring(0, 8)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'التاريخ: ${_formatDate(data['orderTime']?.toDate())}',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isSmallScreen ? 12 : 14),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'العناصر:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16),
                                  ),
                                ),
                                ..._buildOrderItems(data['items'], isSmallScreen),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (isCompleted && !hasRated)
                                          IconButton(
                                            icon: Icon(
                                              Icons.star_border,
                                              size: isSmallScreen ? 20 : 24,
                                              color: Colors.amber,
                                            ),
                                            onPressed: () => _showRatingDialog(
                                              context,
                                              order.id,
                                              data['assignedToId'] ?? '',
                                            ),
                                          ),
                                        if (isCompleted && hasRated)
                                          IconButton(
                                            icon: Icon(
                                              Icons.star,
                                              size: isSmallScreen ? 20 : 24,
                                              color: Colors.amber,
                                            ),
                                            onPressed: () => _showRatingDetails(
                                              context,
                                              data['deliveryRating'],
                                              data['deliveryFeedback'],
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                              Icons.info_outline,
                                              size: isSmallScreen ? 20 : 24),
                                          onPressed: () => _showOrderDetails(context, data),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'الإجمالي: ${data['total']?.toStringAsFixed(2) ?? "00.00"} ج.م',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 14 : 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getArabicStatus(String? status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'assigned': return 'تم التعيين';
      case 'in_progress': return 'قيد التوصيل';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      default: return status ?? 'قيد المعالجة';
    }
  }

  List<Widget> _buildOrderItems(List<dynamic>? items, bool isSmallScreen) {
    if (items == null || items.isEmpty) return [const SizedBox()];
    return items.map<Widget>((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'} ج.م',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                item['name'] ?? 'عنصر غير معروف',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item['quantity']} × ',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'in_progress': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'pending': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير معروف';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final isCompleted = order['status'] == 'completed';
    final hasRated = order['deliveryRating'] != null;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل الطلب', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'رقم الطلب: #${order['orderId']?.substring(0, 8) ?? "N/A"}',
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order['status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getArabicStatus(order['status']),
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'التاريخ: ${_formatDate(order['orderTime']?.toDate())}',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'العناصر:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                ..._buildOrderItems(order['items'], false),
                const SizedBox(height: 16),
                const Text(
                  'معلومات التوصيل:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                InfoRow(
                  icon: Icons.person,
                  label: 'الاسم',
                  value: order['userName'],
                ),
                InfoRow(
                  icon: Icons.phone,
                  label: 'الهاتف',
                  value: order['deliveryPhone'],
                ),
                InfoRow(
                  icon: Icons.location_on,
                  label: 'العنوان',
                  value: order['deliveryAddress'] ?? 'لا يوجد عنوان',
                ),
                if (isCompleted && !hasRated)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.star, color: Colors.white),
                        label: const Text('تقييم خدمة التوصيل',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                          _showRatingDialog(
                            context,
                            order['orderId'],
                            order['assignedToId'] ?? '',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإجمالي:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${order['total']?.toStringAsFixed(2) ?? "0.00"} ج.م',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إغلاق',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDetails(BuildContext context, int? rating, String? feedback) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل التقييم', textAlign: TextAlign.right),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'تقييم خدمة التوصيل:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < (rating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  );
                }),
              ),
              if (feedback?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                const Text(
                  'ملاحظات:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(feedback ?? ''),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String orderId, String deliveryPersonId) {
    int rating = 0;
    TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تقييم خدمة التوصيل', textAlign: TextAlign.right),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'كم تقيم خدمة التوصيل؟',
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (ratingValue) {
                        setState(() => rating = ratingValue.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ملاحظات إضافية (اختياري)',
                      textAlign: TextAlign.right,
                    ),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (rating > 0) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .update({
                          'deliveryRating': rating,
                          'deliveryFeedback': feedbackController.text,
                          'ratedAt': FieldValue.serverTimestamp(),
                        });

                        await _updateDeliveryPersonRating(deliveryPersonId, rating);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حفظ التقييم بنجاح')),
                          );
                          Navigator.pop(context);
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ في حفظ التقييم: $e')),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء اختيار تقييم')),
                      );
                    }
                  },
                  child: const Text(
                    'حفظ',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateDeliveryPersonRating(String deliveryPersonId, int newRating) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(deliveryPersonId);
    final doc = await userRef.get();
    final currentCount = doc.data()?['deliveryRatingCount'] ?? 0;
    final currentAverage = doc.data()?['deliveryAverageRating'] ?? 0.0;
    final newCount = currentCount + 1;
    final newAverage = ((currentAverage * currentCount) + newRating) / newCount;

    await userRef.update({
      'deliveryRatingCount': newCount,
      'deliveryAverageRating': newAverage,
      'lastRatingUpdate': FieldValue.serverTimestamp(),
    });
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value ?? 'غير متوفر', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}