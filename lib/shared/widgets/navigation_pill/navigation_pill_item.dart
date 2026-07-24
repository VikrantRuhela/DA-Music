import 'package:flutter/material.dart';

class NavigationPillItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const NavigationPillItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
