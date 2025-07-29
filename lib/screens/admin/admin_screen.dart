import 'package:flutter/material.dart';
import 'admin_restaurants_screen.dart';
import 'admin_pharmacies_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_grocery_stores_screen.dart';
import 'admin_sections_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_users_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_reports_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأدمن', textDirection: TextDirection.rtl),
        centerTitle: true,
        backgroundColor: const Color(0xff112b16),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            context: context,
            title: 'إدارة المطاعم',
            icon: Icons.restaurant,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminRestaurantsScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة الصيدليات',
            icon: Icons.local_pharmacy,
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPharmaciesScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة المتاجر',
            icon: Icons.store,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminStoresScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة البقالات',
            icon: Icons.local_grocery_store,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminGroceryStoresScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة الأقسام',
            icon: Icons.view_list,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminSectionsScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة البنرات',
            icon: Icons.image,
            color: Colors.cyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBannersScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة المستخدمين',
            icon: Icons.people,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة الطلبات',
            icon: Icons.shopping_cart,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة الإشعارات',
            icon: Icons.notifications,
            color: Colors.pink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'إدارة العروض',
            icon: Icons.local_offer,
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPromotionsScreen()),
            ),
          ),
          _buildCard(
            context: context,
            title: 'التقارير',
            icon: Icons.analytics,
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}