import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/cafe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/dish_card.dart';
import '../widgets/app_button.dart';
import '../widgets/money_text.dart';
import '../sheets/precheck_sheet.dart';
import '../sheets/dish_reference_sheet.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _selectMode = false;
  final Map<String, int> _selected = {};
  String _category = 'Все';
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
    
    final categories = ['Все', ...state.menu.map((m) => m.category).toSet()];
    
    final filteredMenu = state.menu.where((m) {
      if (_category != 'Все' && m.category != _category) return false;
      if (_query.isNotEmpty) {
        return m.name.toLowerCase().contains(_query.toLowerCase());
      }
      return true;
    }).toList();

    final selCount = _selected.values.fold(0, (sum, q) => sum + q);
    final selTotal = _selected.entries.fold(0.0, (sum, entry) {
      final item = state.menu.firstWhere((m) => m.id == entry.key);
      return sum + (item.price * entry.value);
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Header(
                  title: _selectMode ? 'Выбрано: $selCount' : 'Меню',
                  subtitle: _selectMode 
                      ? 'Режим выбора · отметьте позиции'
                      : 'Витрина · состав, аллергены, время',
                  actions: [
                    _SelectToggle(
                      isActive: _selectMode,
                      onTap: () => setState(() {
                        _selectMode = !_selectMode;
                        if (!_selectMode) _selected.clear();
                      }),
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
                        hintText: 'Поиск блюда',
                        hintStyle: TextStyle(color: colors.ink3),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.ink3, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                // Categories
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: categories.map((c) => _CatChip(
                      label: c,
                      isActive: _category == c,
                      onTap: () => setState(() => _category = c),
                    )).toList(),
                  ),
                ),

                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, _selectMode && selCount > 0 ? 150 : 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filteredMenu.length,
                    itemBuilder: (context, index) {
                      final item = filteredMenu[index];
                      final isSelected = _selected.containsKey(item.id);
                      return DishCard(
                        item: item,
                        selectMode: _selectMode,
                        isSelected: isSelected,
                        selectedQty: _selected[item.id] ?? 1,
                        onTap: () {
                          if (_selectMode) {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(item.id);
                              } else {
                                _selected[item.id] = 1;
                              }
                            });
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DishReferenceSheet(item: item),
                            );
                          }
                        },
                        onQtyChanged: (q) => setState(() => _selected[item.id] = q),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Selection Bottom Bar
            if (_selectMode && selCount > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 84, // Above tab bar
                child: _SelectionBar(
                  count: selCount,
                  total: selTotal,
                  onReset: () => setState(() => _selected.clear()),
                  onNext: () async {
                    final res = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PrecheckSheet(selectedItems: _selected),
                    );
                    if (res == true) {
                      setState(() {
                        _selectMode = false;
                        _selected.clear();
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _SelectToggle({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? colors.espresso : colors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: isActive ? colors.espresso : colors.hairline),
          boxShadow: !isActive ? AppTheme.shadowCard(context) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isActive ? 'Готово' : 'Выбрать',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? colors.bg : colors.ink2,
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CatChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isActive ? colors.espresso : colors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: isActive ? colors.espresso : colors.hairline),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? colors.bg : colors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onReset;
  final VoidCallback onNext;

  const _SelectionBar({
    required this.count,
    required this.total,
    required this.onReset,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colors.bg.withOpacity(0.85),
            border: Border(top: BorderSide(color: colors.hairline)),
          ),
          child: Row(
            children: [
              TextButton(
                onTap: onReset,
                child: Text(
                  'Сброс',
                  style: TextStyle(
                    color: colors.ink2,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Пречек ($count)',
                onTap: onNext,
                width: 180,
                // Using child instead of label to show total if needed, but keeping it simple for now
              ),
            ],
          ),
        ),
      ),
    );
  }
}
