import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuItemData {
  final String name;
  final String description;
  final double price;
  final IconData icon;
  const MenuItemData(this.name, this.description, this.price, this.icon);
}

final menuItemsProvider = Provider<List<MenuItemData>>((ref) {
  return const [
    MenuItemData('Paneer Butter Masala', 'Rich tomato gravy with paneer', 220, Icons.rice_bowl_outlined),
    MenuItemData('Dal Tadka', 'Yellow dal tempered with spices', 160, Icons.local_dining_outlined),
    MenuItemData('Garlic Naan', 'Tandoor baked bread with garlic', 40, Icons.bakery_dining_outlined),
    MenuItemData('Veg Biryani', 'Fragrant basmati rice and vegetables', 190, Icons.set_meal_outlined),
    MenuItemData('Gulab Jamun', 'Milk-solid dumplings in syrup', 90, Icons.icecream_outlined),
    MenuItemData('Masala Chai', 'Spiced Indian tea', 30, Icons.coffee_outlined),
  ];
});
