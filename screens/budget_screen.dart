import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final currency    = provider.currency;
    final totalBudget = provider.totalBudget;
    final totalSpent  = provider.totalSpent;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Budget Goals', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                const Text('Set monthly limits per category', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                borderColor: AppTheme.accent.withOpacity(0.3),
                child: Row(children: [
                  Expanded(child: StatTile(label: 'TOTAL BUDGET', value: formatCurrency(totalBudget, currency), valueColor: AppTheme.accent)),
                  Container(width: 1, height: 48, color: AppTheme.border),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: StatTile(
                      label: 'TOTAL SPENT',
                      value: formatCurrency(totalSpent, currency),
                      valueColor: totalSpent > totalBudget ? AppTheme.danger : AppTheme.textPrimary,
                    ),
                  )),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final cat    = provider.categories[i];
                  final spent  = provider.spentFor(cat.id);
                  final budget = provider.budgetFor(cat.id);
                  final hasAlert = provider.alerts.any((a) => a.categoryId == cat.id);
                  final alert    = hasAlert ? provider.alerts.firstWhere((a) => a.categoryId == cat.id) : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasAlert
                            ? (alert!.type == AlertType.exceeded ? AppTheme.danger : AppTheme.warning).withOpacity(0.4)
                            : AppTheme.border,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Color(cat.colorValue).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(cat.label,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                          if (hasAlert) ...[
                            Icon(
                              alert!.type == AlertType.exceeded ? Icons.warning_rounded : Icons.info_outline_rounded,
                              color: alert.type == AlertType.exceeded ? AppTheme.danger : AppTheme.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: () => _showEditBudget(context, cat, budget, currency.symbol),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Text('Edit', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        BudgetBar(spent: spent, limit: budget, color: Color(cat.colorValue)),
                      ]),
                    ),
                  );
                },
                childCount: provider.categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  void _showEditBudget(BuildContext context, AppCategory cat, double current, String symbol) {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${cat.emoji} ${cat.label}',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Set monthly budget limit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '$symbol ',
              prefixStyle: const TextStyle(color: AppTheme.accent, fontSize: 24, fontWeight: FontWeight.w700),
              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) context.read<AppProvider>().updateBudget(cat.id, val);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
