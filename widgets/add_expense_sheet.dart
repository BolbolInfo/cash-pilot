import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  String?   _selectedCategoryId;
  DateTime  _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    final catId = _selectedCategoryId ?? context.read<AppProvider>().categories.first.id;
    await context.read<AppProvider>().addExpense(
      amount: amount,
      categoryId: catId,
      note: _noteCtrl.text.trim(),
      date: _selectedDate,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<AppProvider>();
    final categories = provider.categories;
    _selectedCategoryId ??= categories.first.id;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Add Expense', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '${provider.currency.symbol} ',
              prefixStyle: const TextStyle(color: AppTheme.accent, fontSize: 28, fontWeight: FontWeight.w700),
              hintText: '0.00',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
            autofocus: true,
          ),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 20),

          // Category picker
          const Text('Category', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat      = categories[i];
                final selected = cat.id == _selectedCategoryId;
                final color    = Color(cat.colorValue);
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? color : AppTheme.border, width: selected ? 1.5 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(cat.label.split(' ').first,
                            style: TextStyle(color: selected ? color : AppTheme.textMuted,
                                fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Note
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Date
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(data: AppTheme.theme, child: child!),
              );
              if (d != null) setState(() => _selectedDate = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 18),
                  const SizedBox(width: 12),
                  Text(formatDate(_selectedDate), style: const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _submit,
                child: const Text('Add Expense', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }
}
