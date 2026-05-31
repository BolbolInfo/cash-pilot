import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';

// ── Glass card ─────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const GlassCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? AppTheme.border),
    ),
    child: child,
  );
}

// ── Stat tile ──────────────────────────────────────────────────

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  const StatTile({super.key, required this.label, required this.value, this.valueColor, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    ],
  );
}

// ── Budget progress bar ────────────────────────────────────────

class BudgetBar extends StatelessWidget {
  final double spent;
  final double limit;
  final Color color;

  const BudgetBar({super.key, required this.spent, required this.limit, required this.color});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().currency;
    final pct      = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final barColor = spent > limit ? AppTheme.danger : (pct > 0.8 ? AppTheme.warning : color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatCurrency(spent, currency), style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('/ ${formatCurrency(limit, currency)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// ── Expense list tile ──────────────────────────────────────────

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;

  const ExpenseTile({super.key, required this.expense, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cat      = provider.categoryById(expense.categoryId);
    final currency = provider.currency;
    final color    = Color(cat?.colorValue ?? 0xFF94A3B8);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: AppTheme.danger),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(cat?.emoji ?? '📦', style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.note.isEmpty ? (cat?.label ?? 'Expense') : expense.note,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(relativeDate(expense.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(formatCurrency(expense.amount, currency),
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ── Alert banner ───────────────────────────────────────────────

class AlertBanner extends StatelessWidget {
  final BudgetAlert alert;

  const AlertBanner({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cat      = provider.categoryById(alert.categoryId);
    final currency = provider.currency;
    final isOver   = alert.type == AlertType.exceeded;
    final color    = isOver ? AppTheme.danger : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isOver ? Icons.warning_rounded : Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver
                      ? '${cat?.emoji ?? ''} ${cat?.label ?? alert.categoryId} over budget!'
                      : '${cat?.emoji ?? ''} ${cat?.label ?? alert.categoryId} nearing limit',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCurrency(alert.spent, currency)} of ${formatCurrency(alert.limit, currency)} (${(alert.percentage * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
