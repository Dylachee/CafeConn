import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/cafe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/table_card.dart';
import '../widgets/quick_check_overlay.dart';
import '../sheets/add_edit_table_sheet.dart';
import '../widgets/pressable.dart';
import 'dart:ui';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  TableStatus? _filter;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final colors = Theme.of(context).appColors;
    
    final filteredTables = state.tables.where((t) {
      if (_filter != null && t.status != _filter) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return t.number.toString().contains(q) || t.waiter.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              title: 'Столы',
              subtitle: 'Зал 1 · ${state.tables.where((t) => t.status != TableStatus.free).length} активных · ${state.tables.where((t) => t.status == TableStatus.free).length} свободно',
              actions: [
                _HeaderAction(
                  icon: Icons.add_rounded,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddEditTableSheet(),
                  ),
                  isPrimary: true,
                ),
                const SizedBox(width: 10),
                _HeaderAction(
                  icon: Icons.filter_list_rounded,
                  onTap: () => _showStatusPicker(context),
                ),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.shadowCard(context),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(fontSize: 14, color: colors.ink),
                  decoration: InputDecoration(
                    hintText: 'Поиск стола или официанта',
                    hintStyle: TextStyle(color: colors.ink3),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.ink3, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // Status Filters
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'Все',
                    isActive: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...TableStatus.values.map((s) => _FilterChip(
                        label: _statusLabel(s),
                        status: s,
                        isActive: _filter == s,
                        onTap: () => setState(() => _filter = s),
                      )),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: state.settings.tablesPerRow,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredTables.length,
                itemBuilder: (context, index) {
                  final table = filteredTables[index];
                  return TableCard(
                    table: table,
                    onTap: () => context.push('/tables/${table.number}'),
                    onLongPress: () => _showQuickCheckOverlay(context, table),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCheckOverlay(BuildContext context, CafeTable table) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0x8C0D0B08),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, anim, _) => QuickCheckOverlay(
        table: table,
        onOpenDetail: () {
          Navigator.pop(context);
          context.push('/tables/${table.number}');
        },
        onForward: () {
          // Navigator.pop(context);
          // TODO: Open Forward Sheet
        },
      ),
      transitionBuilder: (context, anim, __, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14 * anim.value, sigmaY: 14 * anim.value),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      },
    );
  }

  String _statusLabel(TableStatus s) {
    switch (s) {
      case TableStatus.free: return 'Свободен';
      case TableStatus.occupied: return 'Занят';
      case TableStatus.newOrder: return 'Новый';
      case TableStatus.ready: return 'Готов';
      case TableStatus.late: return 'Задержка';
    }
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderAction({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? colors.espresso : colors.surface,
          borderRadius: BorderRadius.circular(13),
          boxShadow: !isPrimary ? AppTheme.shadowCard(context) : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? colors.bg : colors.ink,
          size: 22,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final TableStatus? status;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.status, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isActive ? colors.espresso : colors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: isActive ? colors.espresso : colors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor(status!, colors),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? colors.bg : colors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(TableStatus s, AppColors colors) {
    switch (s) {
      case TableStatus.free: return colors.free;
      case TableStatus.occupied: return colors.occupied;
      case TableStatus.newOrder: return colors.warn;
      case TableStatus.ready: return colors.ok;
      case TableStatus.late: return colors.danger;
    }
  }
}
