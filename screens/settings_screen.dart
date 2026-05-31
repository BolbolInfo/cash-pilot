import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../models/currency.dart';
import '../models/category.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),

          // ── Currency ──────────────────────────────────────────
          _SectionHeader(title: 'Currency'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(provider.currency.symbol,
                        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  title: Text(provider.currency.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                  subtitle: Text(provider.currency.code, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  onTap: () => _showCurrencyPicker(context),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Categories ────────────────────────────────────────
          _SectionHeader(title: 'Categories', action: TextButton.icon(
            onPressed: () => _showAddCategory(context),
            icon: const Icon(Icons.add_rounded, color: AppTheme.accent, size: 18),
            label: const Text('Add', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
          )),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final cat = provider.categories[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Color(cat.colorValue).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(cat.label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                      subtitle: cat.isDefault
                          ? const Text('Default', style: TextStyle(color: AppTheme.textMuted, fontSize: 11))
                          : const Text('Custom', style: TextStyle(color: AppTheme.accent, fontSize: 11)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 18),
                          onPressed: () => _showEditCategory(context, cat),
                        ),
                        if (!cat.isDefault)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                            onPressed: () => _confirmDeleteCategory(context, cat),
                          ),
                      ]),
                    ),
                  );
                },
                childCount: provider.categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Data ──────────────────────────────────────────────
          _SectionHeader(title: 'Data'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _SettingsTile(
                    icon: Icons.upload_file_rounded,
                    iconColor: AppTheme.accent,
                    title: 'Export as CSV',
                    subtitle: 'Save all expenses to a CSV file',
                    onTap: () => _exportCsv(context),
                  ),
                  const Divider(color: AppTheme.border, height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.download_rounded,
                    iconColor: const Color(0xFF6EE7B7),
                    title: 'Import from CSV',
                    subtitle: 'Merge expenses from a CSV file',
                    onTap: () => _importCsv(context),
                  ),
                  const Divider(color: AppTheme.border, height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: AppTheme.danger,
                    title: 'Clear All Expenses',
                    subtitle: 'Permanently delete all data',
                    onTap: () => _confirmClearAll(context),
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  // ── Currency picker ──────────────────────────────────────────

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final current = ctx.watch<AppProvider>().currency;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text('Select Currency', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: AppCurrency.all.length,
                itemBuilder: (_, i) {
                  final c        = AppCurrency.all[i];
                  final selected = c.code == current.code;
                  return GestureDetector(
                    onTap: () {
                      ctx.read<AppProvider>().setCurrency(c);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.accent.withOpacity(0.1) : AppTheme.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppTheme.accent : AppTheme.border, width: selected ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (selected ? AppTheme.accent : AppTheme.textSecondary).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(c.symbol, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: TextStyle(color: selected ? AppTheme.textPrimary : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                          Text(c.code, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ])),
                        if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 20),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── Add category ─────────────────────────────────────────────

  void _showAddCategory(BuildContext context) => _showCategoryForm(context, null);
  void _showEditCategory(BuildContext context, AppCategory cat) => _showCategoryForm(context, cat);

  void _showCategoryForm(BuildContext context, AppCategory? existing) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '😀');
    int   selectedColor = existing?.colorValue ?? kCategoryColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(existing == null ? 'New Category' : 'Edit Category',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            // Emoji + Label row
            Row(children: [
              GestureDetector(
                onTap: () async {
                  final result = await showDialog<String>(
                    context: ctx,
                    builder: (_) => _EmojiPickerDialog(current: emojiCtrl.text),
                  );
                  if (result != null) { emojiCtrl.text = result; setS(() {}); }
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Color(selectedColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(selectedColor)),
                  ),
                  alignment: Alignment.center,
                  child: Text(emojiCtrl.text, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: labelCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Category name'),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            const Text('Color', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: kCategoryColors.map((c) {
                final sel = c == selectedColor;
                return GestureDetector(
                  onTap: () => setS(() => selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: sel ? AppTheme.textPrimary : Colors.transparent, width: 2.5),
                      boxShadow: sel ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 8)] : [],
                    ),
                    child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final label = labelCtrl.text.trim();
                  if (label.isEmpty) return;
                  final prov = context.read<AppProvider>();
                  if (existing == null) {
                    prov.addCategory(label: label, emoji: emojiCtrl.text, colorValue: selectedColor);
                  } else {
                    prov.updateCategory(existing.id, label: label, emoji: emojiCtrl.text, colorValue: selectedColor);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existing == null ? 'Add Category' : 'Save Changes', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        );
      }),
    );
  }

  void _confirmDeleteCategory(BuildContext context, AppCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${cat.label}?', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: const Text('Expenses in this category will be moved to "Other".',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<AppProvider>().deleteCategory(cat.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── CSV Export ────────────────────────────────────────────────

  Future<void> _exportCsv(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final csv      = provider.exportCsv();
    try {
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Expenses export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  // ── CSV Import ────────────────────────────────────────────────

  Future<void> _importCsv(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;
      final csv   = String.fromCharCodes(bytes);
      final count = await context.read<AppProvider>().importCsv(csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(count > 0 ? 'Imported $count new expenses ✓' : 'No new expenses found'),
          backgroundColor: count > 0 ? AppTheme.accent.withOpacity(0.8) : AppTheme.warning,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  // ── Clear all ─────────────────────────────────────────────────

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Expenses?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: const Text('This will permanently delete all your expense data. This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<AppProvider>().clearAllExpenses();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(children: [
        Text(title.toUpperCase(),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (action != null) action!,
      ]),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData iconData;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required IconData icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : iconData = icon;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Icon(iconData, color: iconColor, size: 20),
    ),
    title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
    subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    onTap: onTap,
  );
}

// Simple emoji picker dialog
class _EmojiPickerDialog extends StatelessWidget {
  final String current;
  const _EmojiPickerDialog({required this.current});

  static const _emojis = [
    '🍽️','🚗','🛍️','🎬','💊','⚡','✈️','📦','🏠','🎮','📱','💻',
    '🎵','📚','🐶','🌿','💪','🍕','☕','🏋️','💰','🎁','🧴','🛒',
    '🏥','🚌','🚂','⛽','🧾','💡','📡','🎓','🎯','🏖️','🌎','💎',
  ];

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppTheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Pick Emoji', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    content: SizedBox(
      width: 300,
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _emojis.map((e) => GestureDetector(
          onTap: () => Navigator.pop(context, e),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: e == current ? AppTheme.accent.withOpacity(0.2) : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: e == current ? AppTheme.accent : AppTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(e, style: const TextStyle(fontSize: 22)),
          ),
        )).toList(),
      ),
    ),
  );
}
