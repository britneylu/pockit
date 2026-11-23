import 'package:material_ui/material_ui.dart';

// share the same earthy category colors across charts and expense cards
abstract final class CategoryStyle {
  static IconData icon(String category) => switch (category) {
    'Housing' => Icons.home_outlined,
    'Groceries' => Icons.local_grocery_store_outlined,
    'Dining' => Icons.restaurant_outlined,
    'Transportation' => Icons.directions_bus_outlined,
    'Bills' => Icons.receipt_long_outlined,
    'Subscriptions' => Icons.subscriptions_outlined,
    'Shopping' => Icons.shopping_bag_outlined,
    'Entertainment' => Icons.movie_outlined,
    'Travel' => Icons.flight_outlined,
    'Health' => Icons.medical_services_outlined,
    'Education' => Icons.school_outlined,
    'Other' => Icons.payments_outlined,
    _ => Icons.label_outline,
  };

  // keep custom category colors within the app palette
  static const _customColors = [
    Color(0xFF5A786F),
    Color(0xFF6A6F98),
    Color(0xFFA36B55),
    Color(0xFF7D6B8D),
    Color(0xFF71824E),
    Color(0xFF4F7485),
  ];

  static Color color(String category) => switch (category) {
    'Housing' => const Color(0xFF5F7166),
    'Groceries' => const Color(0xFF397059),
    'Dining' => const Color(0xFFB36A4D),
    'Transportation' => const Color(0xFF50758B),
    'Bills' => const Color(0xFF9B762D),
    'Subscriptions' => const Color(0xFF6673A1),
    'Shopping' => const Color(0xFFC15F52),
    'Entertainment' => const Color(0xFF86648C),
    'Travel' => const Color(0xFF74813C),
    'Health' => const Color(0xFFB45F76),
    'Education' => const Color(0xFF3F7B78),
    'Other' => const Color(0xFF727F79),
    // give each custom name a stable color
    _ =>
      _customColors[category.codeUnits.fold(0, (sum, value) => sum + value) %
          _customColors.length],
  };

  static Color tint(String category, {double strength = 0.08}) =>
      Color.lerp(Colors.white, color(category), strength)!;
}
