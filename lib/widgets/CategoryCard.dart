import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color color;
  final int size; // 1 = small, 2 = medium, 3 = large
  final VoidCallback? onTap; // جعلها اختيارية

  const CategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.color,
    required this.size,
    this.onTap, // جعلها اختيارية
  });

  @override
  Widget build(BuildContext context) {
    // التحكم في الحجم بناءً على قيمة size
    double imageSize = size == 3 ? 80 : size == 2 ? 40 : 25;
    double fontSize = size == 3 ? 18 : size == 2 ? 16 : 12;
    double spacing = size == 3 ? 12 : size == 2 ? 10 : 8;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.category,
                    size: imageSize,
                    color: Colors.white,
                  );
                },
              ),
              SizedBox(height: spacing),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}