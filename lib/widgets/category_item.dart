import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const CategoryItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.green,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12),
              textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}