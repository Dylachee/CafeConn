import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cafe_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_widgets.dart';

class OrdersFeedScreen extends StatefulWidget {
  const OrdersFeedScreen({super.key});

  @override
  State<OrdersFeedScreen> createState() => _OrdersFeedScreenState();
}

class _OrdersFeedScreenState extends State<OrdersFeedScreen> {
  FeedType activeFeed = FeedType.kitchen;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    
    // Filter orders and items based on the active feed
    final feedOrders = state.orders.where((o) => 
      o.items.any((i) => i.item.station == activeFeed && !i.done)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FeedBtn(
                  label: 'КУХНЯ',
                  active: activeFeed == FeedType.kitchen,
                  onTap: () => setState(() => activeFeed = FeedType.kitchen),
                  color: AppColors.kitchen,
                ),
                const SizedBox(width: 8),
                _FeedBtn(
                  label: 'БАР',
                  active: activeFeed == FeedType.bar,
                  onTap: () => setState(() => activeFeed = FeedType.bar),
                  color: AppColors.bar,
                ),
              ],
            ),
          ),
        ),
      ),
      body: feedOrders.isEmpty
          ? const _EmptyFeed()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedOrders.length,
              itemBuilder: (context, i) => _OrderCard(
                order: feedOrders[i],
                station: activeFeed,
              ),
            ),
    );
  }
}

class _FeedBtn extends StatelessWidget {
  const _FeedBtn({required this.label, required this.active, required this.onTap, required this.color});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : AppColors.sunken,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.ink55,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.station});
  final CafeOrder order;
  final FeedType station;

  @override
  Widget build(BuildContext context) {
    final state = context.read<CafeState>();
    final table = state.tables.firstWhere((t) => t.id == order.tableId);
    final stationItems = order.items.where((i) => i.item.station == station && !i.done).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.espresso,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(table.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Стол ${table.number}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(table.waiter ?? '—', style: AppTypography.label.copyWith(fontSize: 12)),
                  ],
                ),
                const Spacer(),
                _LiveTimer(createdAt: order.createdAt),
              ],
            ),
          ),
          const Divider(height: 1),
          ...stationItems.map((item) => _StationItemRow(orderId: order.id, item: item)),
        ],
      ),
    );
  }
}

class _StationItemRow extends StatelessWidget {
  const _StationItemRow({required this.orderId, required this.item});
  final String orderId;
  final CartLine item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Text(item.quantity.toString(), style: AppTypography.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: item.notes.map((n) => NoteChip(label: n)).toList(),
                  ),
                ],
              ],
            ),
          ),
          AppButton(
            label: item.ready ? 'ГОТОВО ✓' : 'ГОТОВО',
            onPressed: () => context.read<CafeState>().setItemReady(orderId, item.id, !item.ready),
            kind: item.ready ? ButtonKind.secondary : ButtonKind.primary,
            expand: false,
            height: 32,
            color: item.ready ? AppColors.ok : null,
          ),
        ],
      ),
    );
  }
}

class _LiveTimer extends StatefulWidget {
  const _LiveTimer({required this.createdAt});
  final DateTime createdAt;
  @override
  State<_LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<_LiveTimer> {
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(widget.createdAt);
    final color = diff.inMinutes >= 20 ? AppColors.late : diff.inMinutes >= 15 ? AppColors.call : AppColors.ok;
    
    return Text(
      '${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
      style: AppTypography.mono.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.ok.withOpacity(0.3)),
        const SizedBox(height: 12),
        const Text('Нет активных заказов', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const Text('Все гости накормлены', style: TextStyle(color: AppColors.ink55)),
      ],
    ),
  );
}
