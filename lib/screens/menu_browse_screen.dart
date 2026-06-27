import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cafe_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_widgets.dart';

class MenuBrowseScreen extends StatefulWidget {
  const MenuBrowseScreen({super.key});

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
  String selectedCategory = 'Все';
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final menu = state.menu.where((m) => 
      (selectedCategory == 'Все' || m.category == selectedCategory) &&
      (m.name.toLowerCase().contains(searchController.text.toLowerCase()))
    ).toList();

    final categories = ['Все', ...state.menu.map((m) => m.category).toSet()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Меню', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(controller: searchController, label: 'Поиск', hint: 'Название блюда...', icon: Icons.search_rounded),
          ),
          const SizedBox(height: 12),
          _CategoryScroll(
            categories: categories,
            selected: selectedCategory,
            onChanged: (c) => setState(() => selectedCategory = c),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: menu.length,
              itemBuilder: (context, i) => _MenuGridItem(item: menu[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryScroll extends StatelessWidget {
  const _CategoryScroll({required this.categories, required this.selected, required this.onChanged});
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(c),
            selected: selected == c,
            onSelected: (_) => onChanged(c),
            selectedColor: AppColors.espresso,
            labelStyle: TextStyle(
              color: selected == c ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _MenuGridItem extends StatelessWidget {
  const _MenuGridItem({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.sunken,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                image: item.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover) : null,
              ),
              child: item.imageUrl.isEmpty ? const Center(child: Icon(Icons.restaurant, color: AppColors.ink40)) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.price.toStringAsFixed(1)} \$', style: AppTypography.mono.copyWith(fontWeight: FontWeight.w700)),
                    const Icon(Icons.add_circle_outline, size: 20, color: AppColors.espresso),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
