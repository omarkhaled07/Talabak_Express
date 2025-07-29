import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:talabak_express/screens/pharmacy_details_screen.dart';
import 'package:talabak_express/screens/profile_screen.dart';
import 'package:talabak_express/screens/restaurant_details_screen.dart';
import 'package:talabak_express/screens/support_options_screen.dart';
import 'package:talabak_express/screens/support_screen.dart';
import 'package:talabak_express/widgets/CategoryCard.dart';
import 'package:talabak_express/widgets/SectionItem.dart';
import 'package:talabak_express/screens/notification_screen.dart';
import 'package:talabak_express/screens/search_screen.dart';
import 'package:talabak_express/screens/resturant_screen.dart';
import 'package:talabak_express/screens/store_screen.dart';
import 'package:talabak_express/screens/delivery_screen.dart';
import 'package:talabak_express/screens/grocery_screen.dart';
import 'package:talabak_express/widgets/section_restaurants_screen.dart';

import 'My_Orders.dart';
import 'about_app_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          title: _buildSearchBar(context),
          backgroundColor: const Color(0xff112b16),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_sharp,
                  color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          elevation: 5,
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin button only visible for admins (you can add visibility control)
               // Replace with your admin check logic
              if (false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin');
                      },
                      child: const Text('لوحة الأدمن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

              _buildTopBanner(context),

              _buildSectionTitle('الفئات الرئيسية', Icons.category),
              _buildMainCategories(),

              // _buildSectionTitle('الأقسام الرئيسية', Icons.dashboard),
              // _buildMainSections(context),

              _buildSectionTitle('مطاعم و بقالات مميزة', Icons.star),
              _buildHorizontalList('restaurants'),

              _buildSectionTitle('صيدليات مميزة', Icons.local_pharmacy),
              _buildHorizontalList('pharmacies'),

              const SizedBox(height: 30),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                textDirection: TextDirection.rtl,
                'ابحث عن مطعم، صيدلية، أو منتج ......',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('banners')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _buildBannerPlaceholder();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildBannerPlaceholder();
          }

          final banners = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          if (banners.isEmpty) return _buildBannerPlaceholder();

          return _BannerCarousel(banners: banners);
        },
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff112b16),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: const Color(0xff112b16)),
        ],
      ),
    );
  }

  Widget _buildMainCategories() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mainCategories')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingIndicator();
        final docs = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  switch (data['title']) {
                    case 'مطاعم':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ResturantScreen()),
                      );
                      break;
                    case 'متاجر':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StoreScreen()),
                      );
                      break;
                    case 'توصيل':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeliveryScreen()),
                      );
                      break;
                    case 'بقالات':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GroceryScreen()),
                      );
                      break;
                    default:
                      break;
                  }
                },
                child: StaggeredGridTile.count(
                  crossAxisCellCount: data['cross'] ?? 2,
                  mainAxisCellCount: data['main'] ?? 1,
                  child: CategoryCard(
                    size: data['size'],
                    title: data['title'],
                    imageUrl: data['imageUrl'] ?? 'https://example.com/placeholder.png',
                    color: Color(int.parse(data['color'])),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMainSections(BuildContext context) {
    return SizedBox(
      height: 130,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mainSections')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _buildLoadingIndicator();
          final docs = snapshot.data!.docs;

          return ListView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SectionRestaurantsScreen(
                          sectionTitle: data['title'],
                        ),
                      ),
                    );
                  },
                  child: SectionItem(
                    title: data['title'],
                    imageUrl: data['imageUrl'],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList(String entityType) {
    return SizedBox(
      height: 180,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entities')
            .doc(entityType)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _buildLoadingIndicator();
          final docs = snapshot.data!.docs;

          return ListView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Container(
                width: 150,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (entityType == 'pharmacies') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyDetailsScreen(
                            pharmacyId: doc.id,
                            pharmacyName: data['name'] ?? 'غير معروف',
                            imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/60',
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantDetailsScreen(
                            entityId: doc.id,
                            entityType: entityType,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              data['imageUrl'] ?? 'https://via.placeholder.com/150',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            data['name'] ?? 'غير معروف',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data['deliveryTime'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              data['deliveryTime']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xff112b16),
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.amber[400],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt, size: 28),
              label: 'طلباتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart, size: 28),
              label: 'عربة التسوق',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz, size: 28),
              label: 'المزيد',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 1: // طلباتي
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyOrders()),
                );
                break;
              case 2: // عربة التسوق
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                );
                break;
              case 3: // المزيد
                _showMoreOptions(context); // استدعاء الـ Bottom Sheet هنا
                break;
            // يمكنك إضافة حالات أخرى للعناصر الأخرى إذا لزم الأمر
            }
          },
        ),
      ),
    );
  }}

void _showMoreOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle for dragging
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Options
            _buildOptionTile(
              context,
              icon: Icons.person,
              title: "الملف الشخصي",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),

            _buildOptionTile(
              context,
              icon: Icons.support_agent,
              title: "الدعم الفنى",
              onTap: () {
                Navigator.pop(context); // إغلاق الـ Bottom Sheet أولاً
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportOptionsScreen()),
                );
              },
            ),

            _buildOptionTile(
              context,
              icon: Icons.info,
              title: "عن التطبيق",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                );
              },
            ),

            _buildOptionTile(
              context,
              icon: Icons.logout,
              title: "تسجيل الخروج",
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                );
              },
            ),

            const SizedBox(height: 15),
          ],
        ),
      );
    },
  );
}

Widget _buildOptionTile(
    BuildContext context, {
      required IconData icon,
      required String title,
      Color? color,
      required VoidCallback onTap,
    }) {
  return ListTile(
    leading: Icon(icon, color: color ?? const Color(0xff112b16)),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color ?? Colors.black,
      ),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
  );
}

class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _autoScrollDuration = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.95);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: _autoScrollDuration));
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          reverse: true,
          itemCount: widget.banners.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            final banner = widget.banners[index];
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                }
                return Center(
                  child: SizedBox(
                    height: Curves.easeOut.transform(value) * 160,
                    width: Curves.easeOut.transform(value) * MediaQuery.of(context).size.width * 0.9,
                    child: child,
                  ),
                );
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (banner['targetEntityId'] != null) {
                    if (banner['targetEntityType'] == 'pharmacies') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyDetailsScreen(
                            pharmacyId: banner['targetEntityId'],
                            pharmacyName: banner['title'] ?? '',
                            imageUrl: banner['imageUrl'],
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantDetailsScreen(
                            entityId: banner['targetEntityId'],
                            entityType: banner['targetEntityType'] ?? 'restaurants',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(banner['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index ? Colors.amber : Colors.white.withOpacity(0.7),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}