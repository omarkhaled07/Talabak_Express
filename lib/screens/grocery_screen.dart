import 'package:flutter/material.dart';
import 'package:talabak_express/screens/generic_list_screen.dart';

class GroceryScreen extends StatelessWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericListScreen(
      title: 'بقالات',
      entityType: 'groceryStores',
    );
  }
}