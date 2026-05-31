import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/add_expense_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final remaining = provider.totalBudget - provider.totalSpent;
    final pct = provider.totalBudget > 0
        ? (provider.totalSpent / provider.totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final alerts = provider.alerts;
    final recentExpenses = provider.expenses.take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
                        Text(formatMonth(DateTime.now()),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showAddExpense(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_rounded, color: AppTheme.bg, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Main balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  borderColor: AppTheme.accent.withOpacity(0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Spent', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency(provider.totalSpent, provider.currency),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Circular-ish overall progress
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation(
                            pct > 0.9 ? AppTheme.danger : pct > 0.75 ? AppTheme.warning : AppTheme.accent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}% of budget used',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          Text(
                            '${remaining >= 0 ? '' : '-'}${formatCurrency(remaining.abs(), provider.currency)} ${remaining >= 0 ? 'left' : 'over'}',
                            style: TextStyle(
                              color: remaining >= 0 ? AppTheme.accent : AppTheme.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 16),

                      // Quick stats row
                      Row(
                        children: [
                          Expanded(child: StatTile(
                            label: 'BUDGET',
                              value: formatCurrency(provider.totalBudget, provider.currency),
                          )),
                          Container(width: 1, height: 40, color: AppTheme.border),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: StatTile(
                                label: 'EXPENSES',
                                value: provider.expenses.length.toString(),
                                subtitle: 'this period',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Alerts section
            if (alerts.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppTheme.warning, size: 18),
                          const SizedBox(width: 8),
                          const Text('Alerts', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${alerts.length}',
                                style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...alerts.map((a) => AlertBanner(alert: a)),
                    ],
                  ),
                ),
              ),
            ],

            // Recent expenses
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            if (recentExpenses.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('No expenses yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ExpenseTile(
                      expense: recentExpenses[i],
                      onDelete: () => context.read<AppProvider>().deleteExpense(recentExpenses[i].id),
                    ),
                    childCount: recentExpenses.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }
}
