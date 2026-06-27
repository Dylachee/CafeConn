import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cafe_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_widgets.dart';

class TableDetailsScreen extends StatelessWidget {
  const TableDetailsScreen({super.key, required this.tableId});
  final String tableId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final table = state.tables.firstWhere((t) => t.id == tableId);
    final order = state.orders.cast<CafeOrder?>().firstWhere((o) => o?.id == table.currentOrderId, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Стол ${table.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _TableHeader(table: table),
          Expanded(
            child: order == null 
              ? const _EmptyCheck() 
              : _OrderList(order: order),
          ),
          _BottomActions(table: table),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.table});
  final CafeTable table;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ГОСТИ', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  QuantityStepper(
                    value: table.guestCount,
                    onChanged: (v) => context.read<CafeState>().setGuestCount(table.id, v),
                  ),
                ],
              ),
              const Spacer(),
              if (table.attention != null)
                AppButton(
                  label: table.ack ? 'Принято' : 'Принял',
                  onPressed: table.ack ? null : () => context.read<CafeState>().ackAttention(table.id),
                  kind: ButtonKind.secondary,
                  expand: false,
                  color: table.ack ? AppColors.ok : AppColors.call,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.order});
  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final items = order.items;
    final deliveredCount = items.where((i) => i.done).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$deliveredCount/${items.length} ОТДАНО', style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
              TextButton(onPressed: () {}, child: const Text('Неотданные сверху')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairline),
            itemBuilder: (context, i) => _OrderItemRow(item: items[i], orderId: order.id),
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.orderId});
  final CartLine item;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => context.read<CafeState>().toggleItemDone(orderId, item.id),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.read<CafeState>().toggleItemDone(orderId, item.id),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.done ? AppColors.ok : Colors.transparent,
                  border: Border.all(color: item.done ? AppColors.ok : AppColors.ink40, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: item.done ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.item.name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: item.done ? TextDecoration.lineThrough : null,
                      color: item.done ? AppColors.ink40 : AppColors.ink,
                    ),
                  ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: item.notes.map((n) => NoteChip(label: n, color: item.done ? AppColors.sunken : null)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity} × ${item.lockedPrice.toStringAsFixed(1)}',
                  style: AppTypography.mono.copyWith(fontSize: 14, color: AppColors.ink55),
                ),
                Text(
                  item.total.toStringAsFixed(1),
                  style: AppTypography.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCheck extends StatelessWidget {
  const _EmptyCheck();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.ink40),
        SizedBox(height: 12),
        Text('Чек пуст', style: TextStyle(color: AppColors.ink55, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.table});
  final CafeTable table;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'МЕНЮ',
              icon: Icons.add_rounded,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'СЧЁТ',
            kind: ButtonKind.secondary,
            expand: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
