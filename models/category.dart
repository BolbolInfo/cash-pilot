import 'dart:convert';

/// A fully user-customizable expense category.
class AppCategory {
  final String id;
  final String label;
  final String emoji;
  final int colorValue;
  final bool isDefault; // default categories can't be deleted

  AppCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.colorValue,
    this.isDefault = false,
  });

  AppCategory copyWith({String? label, String? emoji, int? colorValue}) =>
      AppCategory(
        id: id,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
        isDefault: isDefault,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'emoji': emoji,
    'colorValue': colorValue,
    'isDefault': isDefault,
  };

  factory AppCategory.fromJson(Map<String, dynamic> j) => AppCategory(
    id: j['id'],
    label: j['label'],
    emoji: j['emoji'],
    colorValue: j['colorValue'],
    isDefault: j['isDefault'] ?? false,
  );

  static String encodeList(List<AppCategory> list) =>
      jsonEncode(list.map((c) => c.toJson()).toList());

  static List<AppCategory> decodeList(String str) =>
      (jsonDecode(str) as List).map((c) => AppCategory.fromJson(c)).toList();

  static List<AppCategory> defaults() => [
    AppCategory(id: 'food', label: 'Food & Dining', emoji: '🍽️', colorValue: 0xFFFF6B6B, isDefault: true),
    AppCategory(id: 'transport', label: 'Transport', emoji: '🚗', colorValue: 0xFF4ECDC4, isDefault: true),
    AppCategory(id: 'shopping', label: 'Shopping', emoji: '🛍️', colorValue: 0xFFFFD93D, isDefault: true),
    AppCategory(id: 'entertainment', label: 'Entertainment', emoji: '🎬', colorValue: 0xFFA78BFA, isDefault: true),
    AppCategory(id: 'health', label: 'Health', emoji: '💊', colorValue: 0xFF6EE7B7, isDefault: true),
    AppCategory(id: 'bills', label: 'Bills & Utilities', emoji: '⚡', colorValue: 0xFFF97316, isDefault: true),
    AppCategory(id: 'travel', label: 'Travel', emoji: '✈️', colorValue: 0xFF38BDF8, isDefault: true),
    AppCategory(id: 'other', label: 'Other', emoji: '📦', colorValue: 0xFF94A3B8, isDefault: true),
  ];
}

// ── Available palette colors for category picker ────────────────
const kCategoryColors = [
  0xFFFF6B6B, 0xFFFF8E53, 0xFFF97316, 0xFFFFB84D,
  0xFFFFD93D, 0xFF6EE7B7, 0xFF4ECDC4, 0xFF38BDF8,
  0xFF60A5FA, 0xFFA78BFA, 0xFFF472B6, 0xFF94A3B8,
];