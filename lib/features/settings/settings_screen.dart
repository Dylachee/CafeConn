import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/cafe_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final prefs = state.prefs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Профиль'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.sunken, child: Icon(Icons.person, color: AppColors.ink)),
                  title: Text(state.currentUser?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_roleLabel(state.currentUser?.role ?? UserRole.waiter)),
                  trailing: TextButton(onPressed: () {}, child: const Text('Выйти', style: TextStyle(color: AppColors.late))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Уведомления'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Звук прибытия',
                  value: prefs.soundArrival,
                  onChanged: (v) => _update(context, (p) => p.copyWith(soundArrival: v)),
                ),
                const Divider(indent: 16, height: 1),
                _ToggleRow(
                  label: 'Звук вызова',
                  value: prefs.soundCall,
                  onChanged: (v) => _update(context, (p) => p.copyWith(soundCall: v)),
                ),
                const Divider(indent: 16, height: 1),
                _ToggleRow(
                  label: 'Звук счёта',
                  value: prefs.soundBill,
                  onChanged: (v) => _update(context, (p) => p.copyWith(soundBill: v)),
                ),
                const Divider(indent: 16, height: 1),
                _ToggleRow(
                  label: 'Виброотклик',
                  value: prefs.haptics,
                  onChanged: (v) => _update(context, (p) => p.copyWith(haptics: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Внешний вид'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SegmentedRow(
                  label: 'Тема',
                  options: const ['Светлая', 'Тёмная', 'Авто'],
                  selected: prefs.theme == 'light' ? 0 : prefs.theme == 'dark' ? 1 : 2,
                  onChanged: (i) => _update(context, (p) => p.copyWith(theme: ['light', 'dark', 'system'][i])),
                ),
                const Divider(indent: 16, height: 1),
                _SegmentedRow(
                  label: 'Текст',
                  options: const ['S', 'M', 'L'],
                  selected: prefs.textSize == 'S' ? 0 : prefs.textSize == 'M' ? 1 : 2,
                  onChanged: (i) => _update(context, (p) => p.copyWith(textSize: ['S', 'M', 'L'][i])),
                ),
                const Divider(indent: 16, height: 1),
                _ToggleRow(
                  label: 'Высокий контраст',
                  value: prefs.highContrast,
                  onChanged: (v) => _update(context, (p) => p.copyWith(highContrast: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Данные'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.restart_alt_rounded, color: AppColors.late),
              title: const Text('Сброс к демо-данным', style: TextStyle(color: AppColors.late, fontWeight: FontWeight.w600)),
              onTap: () => _confirmReset(context),
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'v0.1.0+1 (Alpha)',
              style: TextStyle(color: AppColors.ink40, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _update(BuildContext context, AppPrefs Function(AppPrefs) updater) {
    final state = context.read<CafeState>();
    state.updatePrefs(updater(state.prefs));
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.admin => 'Администратор',
    UserRole.manager => 'Менеджер',
    UserRole.waiter => 'Официант',
    UserRole.cook => 'Повар',
    UserRole.bartender => 'Бармен',
  };

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Сбросить данные?'),
        content: const Text('Все текущие заказы и изменения будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              context.read<CafeState>().resetToDemo();
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: const Text('Сбросить', style: TextStyle(color: AppColors.late)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12, bottom: 8),
    child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink40)),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    value: value,
    onChanged: onChanged,
    activeThumbColor: AppColors.espresso,
    activeTrackColor: AppColors.espresso,
  );
}

class _SegmentedRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SegmentedRow({required this.label, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: AppColors.sunken, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: List.generate(options.length, (i) => GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected == i ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selected == i ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                ),
                child: Text(options[i], style: TextStyle(fontSize: 13, fontWeight: selected == i ? FontWeight.w600 : FontWeight.w400)),
              ),
            )),
          ),
        ),
      ],
    ),
  );
}
