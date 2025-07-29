import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  bool _isFeatured = false;

  void _showAddStoreDialog({DocumentSnapshot? store}) {
    if (store != null) {
      _nameController.text = store['name'] ?? '';
      _addressController.text = store['address'] ?? '';
      _phoneController.text = store['phone'] ?? '';
      _deliveryTimeController.text = store['deliveryTime'] ?? '';
      _imageUrlController.text = store['imageUrl'] ?? '';
      _openingHoursController.text = store['openingHours'] ?? '';
      _isFeatured = store['isFeatured'] ?? false;
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
            store == null ? 'إضافة متجر' : 'تعديل متجر',
            textDirection: TextDirection.rtl,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المتجر',
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

                if (store == null) {
                  await FirebaseFirestore.instance
                      .collection('entities')
                      .doc('stores')
                      .collection('items')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('entities')
                      .doc('stores')
                      .collection('items')
                      .doc(store.id)
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
        title: const Text('إدارة المتاجر', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xff112b16),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddStoreDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entities')
            .doc('stores')
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد متاجر', textDirection: TextDirection.rtl));
          }

          final stores = snapshot.data!.docs;

          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              final data = store.data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
                ),
                title: Text(data['name'] ?? 'غير معروف', textDirection: TextDirection.rtl),
                subtitle: Text(data['address'] ?? 'غير متوفر', textDirection: TextDirection.rtl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddStoreDialog(store: store),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('entities')
                            .doc('stores')
                            .collection('items')
                            .doc(store.id)
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