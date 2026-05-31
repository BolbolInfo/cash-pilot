import 'dart:convert';

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'categoryId': categoryId,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
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
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: catId,
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
    );
  }

  static String encodeList(List<Expense> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Expense> decodeList(String str) =>
      (jsonDecode(str) as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();

  static String toCsv(List<Expense> expenses, Map<String, String> categoryLabels) {
    final buf = StringBuffer();
    buf.writeln('ID,Amount,Category,Note,Date');
    for (final e in expenses) {
      final cat = categoryLabels[e.categoryId] ?? e.categoryId;
      final note = e.note.replaceAll('"', '""');
      buf.writeln('${e.id},${e.amount},"$cat","$note",${e.date.toIso8601String()}');
    }
    return buf.toString();
  }

  static List<Expense> fromCsv(String csv, Map<String, String> labelToId) {
    final lines = csv.trim().split('\n');
    if (lines.length < 2) return [];
    final result = <Expense>[];
    for (final line in lines.skip(1)) {
      try {
        final cols = _parseCsvLine(line);
        if (cols.length < 5) continue;
        final catLabel = cols[2].trim();
        final catId = labelToId[catLabel] ?? 'other';
        result.add(Expense(
          id: cols[0].trim().isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString()
              : cols[0].trim(),
          amount: double.parse(cols[1].trim()),
          categoryId: catId,
          note: cols[3].trim(),
          date: DateTime.parse(cols[4].trim()),
        ));
      } catch (_) {}
    }
    return result;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }
}
