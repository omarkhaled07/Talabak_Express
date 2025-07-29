import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _problemController = TextEditingController();
  final _whatsappController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _problemController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    const apiKey = '2152c491ff31e06c6614b5e849328e39'; // استبدل بمفتاح API الخاص بك
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

  Future<void> _submitSupportRequest() async {

    String rawNumber = _whatsappController.text; // e.g., 01012345678
    String internationalNumber = '+20${rawNumber.substring(1)}'; // -> +201012345678

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // رفع الصورة أولاً إذا وجدت
      if (_imageFile != null) {
        await _uploadImage();
      }

      // حفظ طلب الدعم في Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('supportTickets').add({
          'userId': user.uid,
          'userEmail': user.email,
          'problem': _problemController.text,
          'imageUrl': _imageUrl,
          'whatsapp': internationalNumber, // استخدام الرقم الذي أدخله المستخدم
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isSubmitted = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // دالة للتحقق من صحة رقم الواتساب المصري
  String? _validateWhatsappNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الواتساب';
    }

    // تحقق من أن الرقم يبدأ بـ +20 ويتبعه 10 أرقام
    final regex = RegExp(r'^0\d{10}$');
    if (!regex.hasMatch(value)) {
      return 'يجب أن يبدأ رقم الواتساب بـ 0 ويتبعه 10 أرقام';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم الفني'),
        centerTitle: true,
      ),
      body: _isSubmitted
          ? _buildSuccessMessage()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الصفحة
              const Text(
                'كيف يمكننا مساعدتك؟',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى وصف المشكلة التي تواجهها وسيقوم فريق الدعم بالرد خلال 24 ساعة عمل',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),

              // حقل وصف المشكلة
              TextFormField(
                controller: _problemController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'يرجى وصف المشكلة بالتفصيل...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال وصف للمشكلة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // حقل رقم الواتساب
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الواتساب (مصر)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '01234567890',
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: _validateWhatsappNumber,
              ),
              const SizedBox(height: 20),

              // رفع صورة
              const Text(
                'إرفاق صورة (اختياري)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'اضغط لرفع صورة',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.deepOrange,
                  ),
                  onPressed: _isLoading ? null : _submitSupportRequest,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'إرسال الطلب',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'تم استلام طلبك بنجاح',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'سيقوم فريق الدعم الفني بالرد على طلبك خلال 24 ساعة عمل.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                    _problemController.clear();
                    _whatsappController.clear();
                    _imageFile = null;
                    _imageUrl = null;
                  });
                },
                child: const Text(
                  'إرسال طلب جديد',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}