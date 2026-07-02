import 'package:flutter/material.dart';

/// Maps the backend category `icon` key to a Material icon.
///
/// أيقونات ممتلئة (rounded/filled) — تعطي حضوراً أقوى وأقرب للتطبيقات
/// التجارية الحديثة من الأيقونات المفرّغة.
IconData categoryIcon(String key) {
  switch (key) {
    case 'grid':
      return Icons.grid_view_rounded;
    case 'home':
      return Icons.apartment_rounded;
    case 'car':
      return Icons.directions_car_filled_rounded;
    case 'phone':
      return Icons.smartphone_rounded;
    case 'bolt':
      return Icons.electrical_services_rounded;
    case 'chair':
      return Icons.chair_rounded;
    case 'shirt':
      return Icons.checkroom_rounded;
    case 'work':
      return Icons.business_center_rounded;
    case 'stroller':
      return Icons.child_friendly_rounded;
    case 'pets':
      return Icons.pets_rounded;
    case 'tools':
      return Icons.handyman_rounded;
    case 'sports':
      return Icons.sports_soccer_rounded;
    case 'book':
      return Icons.auto_stories_rounded;
    case 'gift':
      return Icons.redeem_rounded;
    default:
      return Icons.widgets_rounded;
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

/// تدرّج لوني للقسم: من نسخة أفتح إلى أغمق من لون القسم —
/// يعطي عمقاً واقعياً لبلاطات الأقسام بدل اللون المسطح.
LinearGradient categoryGradient(String key) {
  final base = categoryColor(key);
  final hsl = HSLColor.fromColor(base);
  final light = hsl
      .withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
      .toColor();
  final deep = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  return LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [light, base, deep],
  );
}
