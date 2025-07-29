import 'package:flutter/material.dart';
import 'package:talabak_express/screens/generic_list_screen.dart';

class ResturantScreen extends StatelessWidget {
  const ResturantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericListScreen(
      title: 'مطاعم',
      entityType: 'restaurants',
    );
  }
}