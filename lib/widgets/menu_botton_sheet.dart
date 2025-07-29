import 'package:flutter/material.dart';
import 'menu_button.dart';

class MenuBottomSheet extends StatelessWidget {
  final Function(String) onMenuSelected;

  const MenuBottomSheet({
    super.key,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          MenuButton(
            icon: Icons.wb_sunny,
            label: 'الوضع النهاري',
            onTap: () => onMenuSelected('theme'),
          ),
          MenuButton(
            icon: Icons.notifications,
            label: 'الاشعارات',
            onTap: () => onMenuSelected('notifications'),
          ),
          MenuButton(
            icon: Icons.person,
            label: 'الملف الشخصي',
            onTap: () => onMenuSelected('profile'),
          ),
          MenuButton(
            icon: Icons.info,
            label: 'عن التطبيق',
            onTap: () => onMenuSelected('about'),
          ),
          MenuButton(
            icon: Icons.help_outline,
            label: 'تواصل مع الدعم',
            onTap: () => onMenuSelected('support'),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}