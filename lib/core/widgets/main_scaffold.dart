import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: BottomNavigationBar(
          currentIndex: _getSelectedIndex(location),
          onTap: (i) => _onItemTapped(i, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.espresso,
          unselectedItemColor: AppColors.ink40,
          selectedLabelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.label,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Столы'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Заказы'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Чаты'),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: 'Панель'),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/tables')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/chats')) return 2;
    if (location.startsWith('/panel')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/tables');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/chats');
        break;
      case 3:
        context.go('/panel');
        break;
    }
  }
}
