import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isAdmin = false;

  void _showEditUserDialog(DocumentSnapshot user) {
    _nameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _isAdmin = user['isAdmin'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل المستخدم', textDirection: TextDirection.rtl),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    hintTextDirection: TextDirection.rtl,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
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
                CheckboxListTile(
                  title: const Text('أدمن', textDirection: TextDirection.rtl),
                  value: _isAdmin,
                  onChanged: (value) {
                    setState(() {
                      _isAdmin = value ?? false;
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .update({
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'phone': _phoneController.text,
                  'isAdmin': _isAdmin,
                });
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
        title: const Text('إدارة المستخدمين', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xff112b16),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد مستخدمين', textDirection: TextDirection.rtl));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'غير معروف', textDirection: TextDirection.rtl),
                subtitle: Text(
                  '${data['email'] ?? 'غير متوفر'} - ${data['isAdmin'] == true ? 'أدمن' : 'مستخدم عادي'}',
                  textDirection: TextDirection.rtl,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditUserDialog(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.id)
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
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}