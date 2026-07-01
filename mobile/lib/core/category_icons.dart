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
