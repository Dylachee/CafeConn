import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/cafe_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_widgets.dart';

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  int activeSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель управления', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SegmentControl(
            segments: const ['Обзор', 'Команда', 'Меню', 'Доступ'],
            selected: activeSegment,
            onChanged: (i) => setState(() => activeSegment = i),
          ),
          Expanded(
            child: IndexedStack(
              index: activeSegment,
              children: const [
                _OverviewTab(),
                _TeamTab(),
                _MenuTab(),
                _AccessTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.segments, required this.selected, required this.onChanged});
  final List<String> segments;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: AppColors.sunken, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: List.generate(segments.length, (i) => Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == i ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected == i ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                ),
                child: Text(
                  segments[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected == i ? FontWeight.w700 : FontWeight.w500,
                    color: selected == i ? AppColors.ink : AppColors.ink55,
                  ),
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: const [
            _MetricCard(label: 'Выручка', value: '42.8k \$', icon: Icons.payments_outlined, color: AppColors.ok),
            _MetricCard(label: 'Заказы', value: '124', icon: Icons.receipt_outlined, color: AppColors.bar),
            _MetricCard(label: 'Средний чек', value: '34.5 \$', icon: Icons.analytics_outlined, color: AppColors.gold),
            _MetricCard(label: 'Отказы', value: '2%', icon: Icons.cancel_outlined, color: AppColors.late),
          ],
        ),
        const SizedBox(height: 24),
        Text('ВЫРУЧКА ПО ЧАСАМ', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AppCard(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(8, (i) => Container(
              width: 20,
              height: (40 + (i * 12)) % 100 + 20,
              decoration: BoxDecoration(color: AppColors.espresso, borderRadius: BorderRadius.circular(4)),
            )),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.label.copyWith(fontSize: 11)),
            ],
          ),
          Text(value, style: AppTypography.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final staff = state.staff;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.sunken,
                  child: Text(staff[i].name[0], style: const TextStyle(color: AppColors.ink)),
                ),
                title: Text(staff[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_roleLabel(staff[i].role), style: const TextStyle(fontSize: 12)),
                trailing: StatusBadge(
                  label: staff[i].online ? 'ОНЛАЙН' : 'ОФЛАЙН',
                  color: staff[i].online ? AppColors.ok : AppColors.ink40,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Добавить сотрудника',
            icon: Icons.person_add_rounded,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.admin => 'Админ',
    UserRole.manager => 'Менеджер',
    UserRole.waiter => 'Официант',
    UserRole.cook => 'Повар',
    UserRole.bartender => 'Бармен',
  };
}

class _MenuTab extends StatelessWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final menu = state.menu;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: menu.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: menu[i].station == FeedType.kitchen ? AppColors.kitchen : AppColors.bar, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menu[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${menu[i].category} · ${menu[i].station == FeedType.kitchen ? 'Кухня' : 'Бар'}', style: AppTypography.label.copyWith(fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.sunken, borderRadius: BorderRadius.circular(6)),
                child: Text('${menu[i].price.toStringAsFixed(1)} \$', style: AppTypography.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: menu[i].available,
              onChanged: (v) {},
              activeTrackColor: AppColors.espresso,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessTab extends StatelessWidget {
  const _AccessTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _AccessRow(role: 'Официант', permissions: ['Создание заказов', 'Закрытие стола', 'Чаты']),
        SizedBox(height: 12),
        _AccessRow(role: 'Повар / Бармен', permissions: ['Просмотр заказов', 'Отметка готовности', 'Чаты']),
        SizedBox(height: 12),
        _AccessRow(role: 'Менеджер', permissions: ['Все функции', 'Отчеты', 'Управление столами']),
      ],
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.role, required this.permissions});
  final String role;
  final List<String> permissions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: permissions.map((p) => NoteChip(label: p)).toList(),
          ),
        ],
      ),
    );
  }
}
