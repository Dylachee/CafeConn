import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cafe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/app_button.dart';
import '../widgets/metric_card.dart';
import '../widgets/app_card.dart';
import 'panel/team_tab.dart';
import 'panel/menu_tab.dart';
import 'panel/access_tab.dart';
import 'settings_screen.dart';

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  String _activeTab = 'overview';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final colors = Theme.of(context).appColors;
    
    final tabs = [
      {'key': 'overview', 'label': 'Обзор'},
      {'key': 'team', 'label': 'Команда'},
      {'key': 'menu', 'label': 'Меню'},
      {'key': 'access', 'label': 'Доступ'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              title: 'Панель',
              subtitle: 'Управление · смена с 08:00',
              actions: [
                _IconButton(
                  icon: Icons.settings_rounded,
                  onTap: () => context.push('/panel/settings'),
                ),
              ],
            ),

            // Tab Switcher
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: tabs.map((tab) {
                  final isActive = _activeTab == tab['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = tab['key']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? colors.espresso : colors.sunken,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tab['label']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                            color: isActive ? colors.bg : colors.ink2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: _buildTabContent(_activeTab, state, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String tab, CafeState state, AppColors colors) {
    switch (tab) {
      case 'overview': return _OverviewTab(state: state, colors: colors);
      case 'team': return const TeamTab();
      case 'menu': return const MenuTab();
      case 'access': return const AccessTab();
      default: return Container();
    }
  }
}

class _OverviewTab extends StatelessWidget {
  final CafeState state;
  final AppColors colors;

  const _OverviewTab({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            MetricCard(
              label: 'Выручка сегодня',
              value: '1 248 \$',
              delta: '▲ 12% к вчера',
              deltaColor: colors.ok,
              color: colors.ok,
            ),
            MetricCard(
              label: 'Средний чек',
              value: '24.6 \$',
              delta: '▲ 3%',
              deltaColor: colors.ok,
              color: colors.gold,
            ),
            MetricCard(
              label: 'Активные столы',
              value: '${state.tables.where((t) => t.status != TableStatus.free).length} / 12',
              delta: '${state.tables.where((t) => t.status == TableStatus.free).length} свободно',
              color: colors.occupied,
            ),
            MetricCard(
              label: 'Ср. время готовки',
              value: '12 мин',
              delta: '0 с задержкой',
              color: colors.kitchen,
            ),
          ],
        ),
        
        const SectionHeader(title: 'Выручка по часам'),
        AppCard(
          height: 160,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [30, 45, 60, 40, 70, 90, 80, 50].map((h) {
              final isPeak = h == 90;
              return Container(
                width: 22,
                height: h.toDouble(),
                decoration: BoxDecoration(
                  color: isPeak ? colors.espresso : const Color(0xFFE4D7C2),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(13),
          boxShadow: AppTheme.shadowCard(context),
        ),
        child: Icon(icon, color: colors.ink, size: 22),
      ),
    );
  }
}
