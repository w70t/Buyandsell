import 'package:flutter/material.dart';

/// Maps the backend category `icon` key to a Material icon.
IconData categoryIcon(String key) {
  switch (key) {
    case 'grid':
      return Icons.grid_view_rounded;
    case 'home':
      return Icons.home_work_outlined;
    case 'car':
      return Icons.directions_car_filled_outlined;
    case 'phone':
      return Icons.smartphone_outlined;
    case 'bolt':
      return Icons.bolt_outlined;
    case 'chair':
      return Icons.chair_outlined;
    case 'shirt':
      return Icons.checkroom_outlined;
    case 'work':
      return Icons.work_outline;
    case 'stroller':
      return Icons.child_friendly_outlined;
    case 'pets':
      return Icons.pets_outlined;
    case 'tools':
      return Icons.handyman_outlined;
    case 'sports':
      return Icons.sports_soccer_outlined;
    case 'book':
      return Icons.menu_book_outlined;
    case 'gift':
      return Icons.card_giftcard_outlined;
    default:
      return Icons.widgets_outlined;
  }
}

/// لون مميّز لكل قسم — يجعل صف الأقسام حيوياً بدل لون واحد مكرر.
Color categoryColor(String key) {
  switch (key) {
    case 'home':
      return const Color(0xFF0EA5E9); // sky
    case 'car':
      return const Color(0xFFEF4444); // red
    case 'phone':
      return const Color(0xFF8B5CF6); // violet
    case 'bolt':
      return const Color(0xFFF59E0B); // amber
    case 'chair':
      return const Color(0xFFD97706); // wood
    case 'shirt':
      return const Color(0xFFDB2777); // pink
    case 'work':
      return const Color(0xFF64748B); // slate
    case 'stroller':
      return const Color(0xFF06B6D4); // cyan
    case 'pets':
      return const Color(0xFF16A34A); // green
    case 'tools':
      return const Color(0xFF78716C); // stone
    case 'sports':
      return const Color(0xFF22C55E); // green
    case 'book':
      return const Color(0xFF6366F1); // indigo
    case 'gift':
      return const Color(0xFFE11D48); // rose
    default:
      return const Color(0xFF14B8A6); // brand teal
  }
}
