import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/add_expense_sheet.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _filterCatId;
  String  _search = '';

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<AppProvider>();
    final currency   = provider.currency;
    var   expenses   = provider.expenses.toList();

    if (_filterCatId != null) expenses = expenses.where((e) => e.categoryId == _filterCatId).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      expenses = expenses.where((e) {
        final cat = provider.categoryById(e.categoryId);
        return e.note.toLowerCase().contains(q) || (cat?.label.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => const AddExpenseSheet(),
        ),
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text('Expenses', style: Theme.of(context).textTheme.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _FilterChip(label: 'All', selected: _filterCatId == null, onTap: () => setState(() => _filterCatId = null)),
                ...provider.categories.map((cat) => _FilterChip(
                  label: '${cat.emoji} ${cat.label.split(' ').first}',
                  selected: _filterCatId == cat.id,
                  color: Color(cat.colorValue),
                  onTap: () => setState(() => _filterCatId = _filterCatId == cat.id ? null : cat.id),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Text('${expenses.length} transaction${expenses.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const Spacer(),
              Text(formatCurrency(expenses.fold(0.0, (s, e) => s + e.amount), currency),
                  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('💸', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text('No expenses found', style: TextStyle(color: AppTheme.textMuted)),
            ]))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: expenses.length,
              itemBuilder: (_, i) => ExpenseTile(
                expense: expenses[i],
                onDelete: () => context.read<AppProvider>().deleteExpense(expenses[i].id),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.2) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppTheme.border, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(color: selected ? c : AppTheme.textSecondary,
            fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}
