import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _targetEntityIdController = TextEditingController();
  final TextEditingController _targetEntityTypeController = TextEditingController();
  bool _isActive = true;

  void _showAddBannerDialog({DocumentSnapshot? banner}) {
    if (banner != null) {
      _titleController.text = banner['title'] ?? '';
      _imageUrlController.text = banner['imageUrl'] ?? '';
      _targetEntityIdController.text = banner['targetEntityId'] ?? '';
      _targetEntityTypeController.text = banner['targetEntityType'] ?? '';
      _isActive = banner['isActive'] ?? true;
    } else {
      _titleController.clear();
      _imageUrlController.clear();
      _targetEntityIdController.clear();
      _targetEntityTypeController.clear();
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            banner == null ? 'إضافة بانر' : 'تعديل بانر',
            textDirection: TextDirection.rtl,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان البانر',
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
                  controller: _targetEntityIdController,
                  decoration: const InputDecoration(
                    labelText: 'معرف الكيان المستهدف',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _targetEntityTypeController,
                  decoration: const InputDecoration(
                    labelText: 'نوع الكيان (restaurants/pharmacies/stores/groceryStores)',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                CheckboxListTile(
                  title: const Text('نشط', textDirection: TextDirection.rtl),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
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
                  'title': _titleController.text,
                  'imageUrl': _imageUrlController.text,
                  'targetEntityId': _targetEntityIdController.text,
                  'targetEntityType': _targetEntityTypeController.text,
                  'isActive': _isActive,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                if (banner == null) {
                  await FirebaseFirestore.instance.collection('banners').add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('banners')
                      .doc(banner.id)
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
        title: const Text('إدارة البنرات', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xff112b16),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddBannerDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('banners').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد بنرات', textDirection: TextDirection.rtl));
          }

          final banners = snapshot.data!.docs;

          return ListView.builder(
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              final data = banner.data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                ),
                title: Text(data['title'] ?? 'غير معروف', textDirection: TextDirection.rtl),
                subtitle: Text(
                  '${data['targetEntityType'] ?? 'غير متوفر'} - ${data['isActive'] == true ? 'نشط' : 'غير نشط'}',
                  textDirection: TextDirection.rtl,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddBannerDialog(banner: banner),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('banners')
                            .doc(banner.id)
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
    _titleController.dispose();
    _imageUrlController.dispose();
    _targetEntityIdController.dispose();
    _targetEntityTypeController.dispose();
    super.dispose();
  }
}