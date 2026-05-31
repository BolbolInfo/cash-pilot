import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final currency    = provider.currency;
    final catTotals   = provider.categoryTotals;
    final monthlyTrend = provider.monthlyTrend;
    final total       = provider.totalSpent;

    final pieData = catTotals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Text('Analytics', style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),

          // Pie chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Spending by Category',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 24),
                  if (pieData.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40),
                        child: Text('No data yet', style: TextStyle(color: AppTheme.textMuted))))
                  else
                    Row(children: [
                      SizedBox(
                        width: 160, height: 160,
                        child: PieChart(PieChartData(
                          pieTouchData: PieTouchData(touchCallback: (event, resp) {
                            setState(() {
                              if (!event.isInterestedForInteractions || resp?.touchedSection == null) {
                                _touchedIndex = null;
                              } else {
                                _touchedIndex = resp!.touchedSection!.touchedSectionIndex;
                              }
                            });
                          }),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: pieData.asMap().entries.map((entry) {
                            final i    = entry.key;
                            final catId = entry.value.key;
                            final val  = entry.value.value;
                            final cat  = provider.categoryById(catId);
                            final isTouched = i == _touchedIndex;
                            return PieChartSectionData(
                              color: Color(cat?.colorValue ?? 0xFF94A3B8),
                              value: val,
                              title: isTouched && total > 0 ? '${(val / total * 100).toStringAsFixed(0)}%' : '',
                              radius: isTouched ? 55 : 48,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            );
                          }).toList(),
                        )),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: pieData.take(5).map((entry) {
                            final cat = provider.categoryById(entry.key);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(children: [
                                Container(width: 10, height: 10,
                                    decoration: BoxDecoration(color: Color(cat?.colorValue ?? 0xFF94A3B8), shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(cat?.label.split(' ').first ?? entry.key,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                Text(formatCurrency(entry.value, currency),
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Monthly bar chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('6-Month Trend',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: monthlyTrend.isEmpty ? 100
                          : monthlyTrend.map((m) => m['total'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.card,
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            formatCurrency(rod.toY, currency),
                            const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < monthlyTrend.length) {
                              return Padding(padding: const EdgeInsets.only(top: 8),
                                  child: Text(formatShortMonth(monthlyTrend[idx]['month'] as DateTime),
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)));
                            }
                            return const SizedBox.shrink();
                          },
                        )),
                        leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true, horizontalInterval: 200,
                        getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: monthlyTrend.asMap().entries.map((entry) {
                        final total = entry.value['total'] as double;
                        return BarChartGroupData(x: entry.key, barRods: [
                          BarChartRodData(
                            toY: total, width: 24,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: [AppTheme.accent.withOpacity(0.4), AppTheme.accent],
                            ),
                          ),
                        ]);
                      }).toList(),
                    )),
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Category breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Category Breakdown',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 16),
                  ...provider.categories.map((cat) {
                    final spent  = provider.spentFor(cat.id);
                    final budget = provider.budgetFor(cat.id);
                    if (spent == 0 && budget == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(cat.label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 8),
                        BudgetBar(spent: spent, limit: budget, color: Color(cat.colorValue)),
                      ]),
                    );
                  }),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }
}
