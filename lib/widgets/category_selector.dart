import 'package:flutter/material.dart';

class CategorySelector extends StatefulWidget {
  final List<String> categories;
  final Function(int) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // For RTL support
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChoiceChip(
              label: Text(
                widget.categories[index],
                textDirection: TextDirection.rtl,
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => selectedIndex = index);
                widget.onCategorySelected(index);
              },
              selectedColor: Colors.green,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}