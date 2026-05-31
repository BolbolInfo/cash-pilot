import 'dart:convert';
import 'category.dart';

class Budget {
  final String categoryId;
  double limit;

  Budget({required this.categoryId, required this.limit});

  Map<String, dynamic> toJson() => {'categoryId': categoryId, 'limit': limit};

  factory Budget.fromJson(Map<String, dynamic> json) {
    String catId;
    if (json.containsKey('categoryId')) {
      catId = json['categoryId'] as String;
    } else {
      const legacyIds = [
        'food', 'transport', 'shopping', 'entertainment',
        'health', 'bills', 'travel', 'other'
      ];
      final idx = (json['category'] as int? ?? 7).clamp(0, legacyIds.length - 1);
      catId = legacyIds[idx];
    }
    return Budget(categoryId: catId, limit: (json['limit'] as num).toDouble());
  }

  static String encodeList(List<Budget> list) =>
      jsonEncode(list.map((b) => b.toJson()).toList());

  static List<Budget> decodeList(String str) =>
      (jsonDecode(str) as List).map((b) => Budget.fromJson(b as Map<String, dynamic>)).toList();

  static List<Budget> fromCategories(List<AppCategory> cats) =>
      cats.map((c) => Budget(categoryId: c.id, limit: 500.0)).toList();
}
