import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGroceryStoresScreen extends StatefulWidget {
  const AdminGroceryStoresScreen({super.key});

  @override
  State<AdminGroceryStoresScreen> createState() => _AdminGroceryStoresScreenState();
}

class _AdminGroceryStoresScreenState extends State<AdminGroceryStoresScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  bool _isFeatured = false;

  void _showAddGroceryStoreDialog({DocumentSnapshot? groceryStore}) {
    if (groceryStore != null) {
      _nameController.text = groceryStore['name'] ?? '';
      _addressController.text = groceryStore['address'] ?? '';
      _phoneController.text = groceryStore['phone'] ?? '';
      _deliveryTimeController.text = groceryStore['deliveryTime'] ?? '';
      _imageUrlController.text = groceryStore['imageUrl'] ?? '';
      _openingHoursController.text = groceryStore['openingHours'] ?? '';
      _isFeatured = groceryStore['isFeatured'] ?? false;
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
            groceryStore == null ? 'إضافة بقالة' : 'تعديل بقالة',
            textDirection: TextDirection.rtl,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم البقالة',
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

                if (groceryStore == null) {
                  await FirebaseFirestore.instance
                      .collection('entities')
                      .doc('groceryStores')
                      .collection('items')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('entities')
                      .doc('groceryStores')
                      .collection('items')
                      .doc(groceryStore.id)
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
        title: const Text('إدارة البقالات', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xff112b16),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddGroceryStoreDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entities')
            .doc('groceryStores')
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد بقالات', textDirection: TextDirection.rtl));
          }

          final groceryStores = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groceryStores.length,
            itemBuilder: (context, index) {
              final groceryStore = groceryStores[index];
              final data = groceryStore.data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_grocery_store),
                ),
                title: Text(data['name'] ?? 'غير معروف', textDirection: TextDirection.rtl),
                subtitle: Text(data['address'] ?? 'غير متوفر', textDirection: TextDirection.rtl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddGroceryStoreDialog(groceryStore: groceryStore),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('entities')
                            .doc('groceryStores')
                            .collection('items')
                            .doc(groceryStore.id)
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