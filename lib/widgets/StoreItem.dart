import 'package:flutter/material.dart';

class StoreItem extends StatelessWidget {
  final String title;
  final String deliveryTime;
  final String imageUrl;
  final VoidCallback? onTap; // جعلها اختيارية

  const StoreItem({
    Key? key,
    required this.title,
    required this.deliveryTime,
    required this.imageUrl,
    this.onTap, // جعلها اختيارية
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.store,
                          size: 40,
                          color: Colors.deepPurple);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  deliveryTime,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}