import 'package:flutter/material.dart';

class MenuAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const MenuAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });
}
