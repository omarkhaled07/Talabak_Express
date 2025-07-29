import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _imageUrl = data['profileImage'] ?? '';
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImageToImgBB();
    }
  }

  Future<void> _uploadImageToImgBB() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    const apiKey = 'YOUR_IMGBB_API_KEY'; // استبدل بمفتاح API الخاص بك
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        _imageFile!.path,
      ),
    );

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = String.fromCharCodes(responseData);
      final jsonResult = jsonDecode(result);

      if (jsonResult['success'] == true) {
        setState(() {
          _imageUrl = jsonResult['data']['url'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الصورة: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          if (_imageUrl != null) 'profileImage': _imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );

        setState(() => _isEditing = false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // صورة الملف الشخصي
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(_imageUrl!)
                          : _imageFile != null
                          ? FileImage(_imageFile!)
                          : null,
                      child: _imageUrl == null && _imageFile == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    if (_isEditing)
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.deepOrange,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // معلومات المستخدم
              _buildEditableField(
                label: 'الاسم',
                controller: _nameController,
                icon: Icons.person,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الاسم';
                  }
                  return null;
                },
              ),

              _buildEditableField(
                label: 'البريد الإلكتروني',
                controller: _emailController,
                icon: Icons.email,
                enabled: false, // لا يمكن تعديل البريد الإلكتروني
              ),

              _buildEditableField(
                label: 'رقم الهاتف',
                controller: _phoneController,
                icon: Icons.phone,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // قسم العناوين
              _buildSectionTitle('العناوين المسجلة'),
              _buildAddressesSection(),

              // قسم الطلبات الأخيرة
              _buildSectionTitle('طلباتي الأخيرة'),
              _buildOrdersSection(),

              // قسم المفضلة
              _buildSectionTitle('المفضلة'),
              _buildFavoritesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: !enabled,
          fillColor: Colors.grey[100],
        ),
        enabled: enabled,
        validator: validator,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_isEditing && title == 'العناوين المسجلة')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.deepOrange),
              onPressed: () {
                // إضافة عنوان جديد
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAddressesSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final addresses = snapshot.data?['addresses'] as List? ?? [];

        if (addresses.isEmpty) {
          return const Text('لا توجد عناوين مسجلة');
        }

        return Column(
          children: addresses.map<Widget>((address) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(address['title'] ?? 'عنوان غير معروف'),
                subtitle: Text(address['fullAddress'] ?? ''),
                trailing: _isEditing
                    ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // حذف العنوان
                  },
                )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOrdersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Text('لا توجد طلبات سابقة');
        }

        return Column(
          children: orders.map<Widget>((doc) {
            final order = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('طلب #${doc.id.substring(0, 6)}'),
                subtitle: Text('${order['total']} ج.م - ${order['status']}'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  // عرض تفاصيل الطلب
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFavoritesSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final favorites = snapshot.data?['favorites'] as List? ?? [];

        if (favorites.isEmpty) {
          return const Text('لا توجد عناصر في المفضلة');
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Card(
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          item['name'] ?? 'غير معروف',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}