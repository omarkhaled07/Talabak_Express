import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPharmaciesScreen extends StatefulWidget {
  const AdminPharmaciesScreen({super.key});

  @override
  State<AdminPharmaciesScreen> createState() => _AdminPharmaciesScreenState();
}

class _AdminPharmaciesScreenState extends State<AdminPharmaciesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  bool _isFeatured = false;

  void _showAddPharmacyDialog({DocumentSnapshot? pharmacy}) {
    if (pharmacy != null) {
      _nameController.text = pharmacy['name'] ?? '';
      _addressController.text = pharmacy['address'] ?? '';
      _phoneController.text = pharmacy['phone'] ?? '';
      _deliveryTimeController.text = pharmacy['deliveryTime'] ?? '';
      _imageUrlController.text = pharmacy['imageUrl'] ?? '';
      _openingHoursController.text = pharmacy['openingHours'] ?? '';
      _isFeatured = pharmacy['isFeatured'] ?? false;
    } else {
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
      _deliveryTimeController.clear();
      _imageUrlController.clear();
      _openingHoursController.clear();
      _isFeatured = false;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            pharmacy == null ? 'إضافة صيدلية' : 'تعديل صيدلية',
            textDirection: TextDirection.rtl,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الصيدلية',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _deliveryTimeController,
                  decoration: const InputDecoration(
                    labelText: 'وقت التوصيل',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _openingHoursController,
                  decoration: const InputDecoration(
                    labelText: 'ساعات العمل',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                CheckboxListTile(
                  title: const Text('مميز', textDirection: TextDirection.rtl),
                  value: _isFeatured,
                  onChanged: (value) {
                    setState(() {
                      _isFeatured = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': _nameController.text,
                  'address': _addressController.text,
                  'phone': _phoneController.text,
                  'deliveryTime': _deliveryTimeController.text,
                  'imageUrl': _imageUrlController.text,
                  'openingHours': _openingHoursController.text,
                  'isFeatured': _isFeatured,
                };

                if (pharmacy == null) {
                  await FirebaseFirestore.instance
                      .collection('entities')
                      .doc('pharmacies')
                      .collection('items')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('entities')
                      .doc('pharmacies')
                      .collection('items')
                      .doc(pharmacy.id)
                      .update(data);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الصيدليات', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xff112b16),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddPharmacyDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entities')
            .doc('pharmacies')
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد صيدليات', textDirection: TextDirection.rtl));
          }

          final pharmacies = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = pharmacies[index];
              final data = pharmacy.data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_pharmacy),
                ),
                title: Text(data['name'] ?? 'غير معروف', textDirection: TextDirection.rtl),
                subtitle: Text(data['address'] ?? 'غير متوفر', textDirection: TextDirection.rtl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddPharmacyDialog(pharmacy: pharmacy),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('entities')
                            .doc('pharmacies')
                            .collection('items')
                            .doc(pharmacy.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _deliveryTimeController.dispose();
    _imageUrlController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }
}