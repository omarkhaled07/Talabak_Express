import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // لازم تهيئ Firebase قبل أي استدعاء لـ Firestore
  await Firebase.initializeApp();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // بيانات mainCategories
  final List<Map<String, dynamic>> mainCategories = [
    {
      "title": "صيدليات",
      "icon": 58341,
      "color": "0xFF4CAF50",
      "cross": 2,
      "main": 1,
    },
    {
      "title": "متاجر",
      "icon": 58826,
      "color": "0xFFFF5722",
      "cross": 2,
      "main": 1,
    },
    // أضف باقي البيانات هنا بنفس التنسيق
  ];

  // بيانات featuredStores
  final List<Map<String, dynamic>> featuredStores = [
    {
      "name": "متجر التجميل",
      "time": "10 صباحاً - 10 مساءً",
    },
    {
      "name": "متجر الإلكترونيات",
      "time": "9 صباحاً - 9 مساءً",
    },
    // أضف باقي البيانات هنا
  ];

  // بيانات featuredPharmacies
  final List<Map<String, dynamic>> featuredPharmacies = [
    {
      "name": "صيدلية الصحة",
      "time": "24 ساعة",
    },
    {
      "name": "صيدلية المدينة",
      "time": "8 صباحاً - 11 مساءً",
    },
    // أضف باقي البيانات هنا
  ];

  // بيانات mainSections
  final List<Map<String, dynamic>> mainSections = [
    {
      "title": "الأدوية",
      "icon": 58822,
    },
    {
      "title": "العناية الشخصية",
      "icon": 59540,
    },
    // أضف باقي البيانات هنا
  ];

  // بيانات البانر
  final Map<String, dynamic> banner = {
    "imageUrl": "https://yourdomain.com/path_to_banner_image.jpg",
  };

  // رفع mainCategories
  for (var cat in mainCategories) {
    await firestore.collection('mainCategories').add(cat);
  }
  print('تم رفع mainCategories');

  // رفع featuredStores
  for (var store in featuredStores) {
    await firestore.collection('featuredStores').add(store);
  }
  print('تم رفع featuredStores');

  // رفع featuredPharmacies
  for (var pharmacy in featuredPharmacies) {
    await firestore.collection('featuredPharmacies').add(pharmacy);
  }
  print('تم رفع featuredPharmacies');

  // رفع mainSections
  for (var section in mainSections) {
    await firestore.collection('mainSections').add(section);
  }
  print('تم رفع mainSections');

  // رفع البانر (مستند واحد فقط باسم 'main')
  await firestore.collection('banners').doc('main').set(banner);
  print('تم رفع banner');
}
