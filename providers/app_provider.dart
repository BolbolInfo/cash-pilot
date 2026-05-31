import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/currency.dart';

const _expensesKey   = 'expenses_v2';
const _budgetsKey    = 'budgets_v2';
const _categoriesKey = 'categories_v1';
const _currencyKey   = 'currency_v1';

class AppProvider extends ChangeNotifier {
  List<Expense>     _expenses   = [];
  List<Budget>      _budgets    = [];
  List<AppCategory> _categories = AppCategory.defaults();
  AppCurrency       _currency   = AppCurrency.all.first;
  bool              _loaded     = false;

  List<Expense>     get expenses   => List.unmodifiable(_expenses);
  List<Budget>      get budgets    => List.unmodifiable(_budgets);
  List<AppCategory> get categories => List.unmodifiable(_categories);
  AppCurrency       get currency   => _currency;
  bool              get loaded     => _loaded;

  // ── Helpers ────────────────────────────────────────────────────

  AppCategory? categoryById(String id) {
    try { return _categories.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  Map<String, String> get categoryLabels =>
      { for (final c in _categories) c.id: c.label };

  Map<String, String> get labelToId =>
      { for (final c in _categories) c.label: c.id };

  // ── Derived stats ──────────────────────────────────────────────

  double get totalSpent   => _expenses.fold(0, (s, e) => s + e.amount);
  double get totalBudget  => _budgets.fold(0, (s, b) => s + b.limit);

  double spentFor(String catId) =>
      _expenses.where((e) => e.categoryId == catId).fold(0, (s, e) => s + e.amount);

  double budgetFor(String catId) {
    try { return _budgets.firstWhere((b) => b.categoryId == catId).limit; }
    catch (_) { return 0; }
  }

  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final e in _expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> get monthlyTrend {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      final total = _expenses
          .where((e) => e.date.year == month.year && e.date.month == month.month)
          .fold(0.0, (s, e) => s + e.amount);
      return {'month': month, 'total': total};
    });
  }

  List<BudgetAlert> get alerts {
    final result = <BudgetAlert>[];
    for (final b in _budgets) {
      final spent = spentFor(b.categoryId);
      final pct   = b.limit > 0 ? spent / b.limit : 0.0;
      if (pct >= 1.0) {
        result.add(BudgetAlert(categoryId: b.categoryId, type: AlertType.exceeded,  spent: spent, limit: b.limit));
      } else if (pct >= 0.8) {
        result.add(BudgetAlert(categoryId: b.categoryId, type: AlertType.nearLimit, spent: spent, limit: b.limit));
      }
    }
    return result;
  }

  // ── Expense CRUD ───────────────────────────────────────────────

  Future<void> addExpense({
    required double   amount,
    required String   categoryId,
    required String   note,
    required DateTime date,
  }) async {
    _expenses.add(Expense(
      id: const Uuid().v4(),
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: date,
    ));
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveExpenses();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveExpenses();
  }

  // ── Budget CRUD ────────────────────────────────────────────────

  Future<void> updateBudget(String categoryId, double limit) async {
    final idx = _budgets.indexWhere((b) => b.categoryId == categoryId);
    if (idx != -1) {
      _budgets[idx].limit = limit;
    } else {
      _budgets.add(Budget(categoryId: categoryId, limit: limit));
    }
    notifyListeners();
    await _saveBudgets();
  }

  // ── Category CRUD ──────────────────────────────────────────────

  Future<void> addCategory({
    required String label,
    required String emoji,
    required int    colorValue,
  }) async {
    final id = const Uuid().v4();
    _categories.add(AppCategory(id: id, label: label, emoji: emoji, colorValue: colorValue));
    _budgets.add(Budget(categoryId: id, limit: 500.0));
    notifyListeners();
    await Future.wait([_saveCategories(), _saveBudgets()]);
  }

  Future<void> updateCategory(String id, {String? label, String? emoji, int? colorValue}) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _categories[idx] = _categories[idx].copyWith(label: label, emoji: emoji, colorValue: colorValue);
    notifyListeners();
    await _saveCategories();
  }

  Future<void> deleteCategory(String id) async {
    final cat = _categories.firstWhere((c) => c.id == id, orElse: () => AppCategory(id: '', label: '', emoji: '', colorValue: 0));
    if (cat.isDefault || cat.id.isEmpty) return;
    _categories.removeWhere((c) => c.id == id);
    _budgets.removeWhere((b) => b.categoryId == id);
    // Move orphaned expenses to 'other'
    _expenses = _expenses.map((e) => e.categoryId == id
        ? Expense(id: e.id, amount: e.amount, categoryId: 'other', note: e.note, date: e.date)
        : e).toList();
    notifyListeners();
    await Future.wait([_saveCategories(), _saveBudgets(), _saveExpenses()]);
  }

  // ── Currency ───────────────────────────────────────────────────

  Future<void> setCurrency(AppCurrency currency) async {
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }

  // ── CSV Import / Export ────────────────────────────────────────

  String exportCsv() => Expense.toCsv(_expenses, categoryLabels);

  /// Returns number of imported rows, or throws on fatal error.
  Future<int> importCsv(String csvContent) async {
    final imported = Expense.fromCsv(csvContent, labelToId);
    if (imported.isEmpty) return 0;
    // Merge: skip duplicate IDs
    final existingIds = { for (final e in _expenses) e.id };
    final newOnes = imported.where((e) => !existingIds.contains(e.id)).toList();
    _expenses.addAll(newOnes);
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveExpenses();
    return newOnes.length;
  }

  Future<void> clearAllExpenses() async {
    _expenses.clear();
    notifyListeners();
    await _saveExpenses();
  }

  // ── Persistence ────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Categories
    final cStr = prefs.getString(_categoriesKey);
    if (cStr != null) _categories = AppCategory.decodeList(cStr);

    // Budgets
    final bStr = prefs.getString(_budgetsKey);
    if (bStr != null) {
      _budgets = Budget.decodeList(bStr);
    } else {
      _budgets = Budget.fromCategories(_categories);
    }

    // Expenses
    final eStr = prefs.getString(_expensesKey);
    if (eStr != null) {
      _expenses = Expense.decodeList(eStr);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    } else {
      _expenses = _sampleExpenses();
    }

    // Currency
    final code = prefs.getString(_currencyKey);
    if (code != null) _currency = AppCurrency.fromCode(code);

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveExpenses()   async { final p = await SharedPreferences.getInstance(); await p.setString(_expensesKey,   Expense.encodeList(_expenses)); }
  Future<void> _saveBudgets()    async { final p = await SharedPreferences.getInstance(); await p.setString(_budgetsKey,    Budget.encodeList(_budgets)); }
  Future<void> _saveCategories() async { final p = await SharedPreferences.getInstance(); await p.setString(_categoriesKey, AppCategory.encodeList(_categories)); }

  List<Expense> _sampleExpenses() {
    final now = DateTime.now();
    return [
      Expense(id: 's1', amount: 45.50,  categoryId: 'food',          note: 'Dinner downtown',       date: now.subtract(const Duration(days: 1))),
      Expense(id: 's2', amount: 120.00, categoryId: 'transport',     note: 'Monthly transit pass',   date: now.subtract(const Duration(days: 2))),
      Expense(id: 's3', amount: 89.99,  categoryId: 'shopping',      note: 'New sneakers',           date: now.subtract(const Duration(days: 3))),
      Expense(id: 's4', amount: 15.00,  categoryId: 'entertainment', note: 'Streaming subscription', date: now.subtract(const Duration(days: 4))),
      Expense(id: 's5', amount: 200.00, categoryId: 'bills',         note: 'Electricity bill',       date: now.subtract(const Duration(days: 5))),
      Expense(id: 's6', amount: 60.00,  categoryId: 'health',        note: 'Gym membership',         date: now.subtract(const Duration(days: 6))),
      Expense(id: 's7', amount: 320.00, categoryId: 'travel',        note: 'Hotel booking',          date: now.subtract(const Duration(days: 35))),
      Expense(id: 's8', amount: 32.00,  categoryId: 'food',          note: 'Weekend brunch',         date: now.subtract(const Duration(days: 36))),
    ];
  }
}

// ── Alert model ─────────────────────────────────────────────────

enum AlertType { nearLimit, exceeded }

class BudgetAlert {
  final String    categoryId;
  final AlertType type;
  final double    spent;
  final double    limit;

  BudgetAlert({required this.categoryId, required this.type, required this.spent, required this.limit});

  double get percentage => limit > 0 ? spent / limit : 0;
}
