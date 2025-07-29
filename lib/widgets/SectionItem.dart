import 'package:flutter/material.dart';

class SectionItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String? subtitle;
  final VoidCallback? onTap; // جعلها اختيارية

  const SectionItem({
    Key? key,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.onTap, // جعلها اختيارية
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textDirection: TextDirection.rtl,
              ),
          ],
        ),
      ),
    );
  }
}