import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cafe_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_widgets.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final tables = state.tables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Столы', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.read<CafeState>().hub.simulateSignal(AttentionType.callWaiter, 't1'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: state.prefs.textSize == 'L' ? 2 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: tables.length,
        itemBuilder: (context, i) => TableCard(table: tables[i]),
      ),
    );
  }
}

class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.table});
  final CafeTable table;

  @override
  Widget build(BuildContext context) {
    final hasAttention = table.attention != null;
    final isAcked = table.ack;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () {},
      border: hasAttention && !isAcked
          ? Border.all(color: _getAttentionColor(table.attention!), width: 2)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                table.number,
                style: AppTypography.h2.copyWith(fontSize: 24),
              ),
              if (hasAttention)
                _AttentionDot(type: table.attention!, acked: isAcked)
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(table.status),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            table.waiter ?? '—',
            style: AppTypography.label.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 12, color: AppColors.ink40),
              const SizedBox(width: 4),
              Text(
                '${table.guestCount}/${table.seats}',
                style: AppTypography.mono.copyWith(fontSize: 12, color: AppColors.ink55),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.free: return AppColors.free;
      case TableStatus.occupied: return AppColors.arrived;
      case TableStatus.awaitingPayment: return AppColors.bill;
      case TableStatus.ready: return AppColors.ok;
      case TableStatus.late: return AppColors.late;
      case TableStatus.newOrder: return AppColors.call;
    }
  }

  Color _getAttentionColor(AttentionType type) {
    switch (type) {
      case AttentionType.arrived: return AppColors.arrived;
      case AttentionType.callWaiter: return AppColors.call;
      case AttentionType.billRequest: return AppColors.bill;
    }
  }
}

class _AttentionDot extends StatelessWidget {
  const _AttentionDot({required this.type, required this.acked});
  final AttentionType type;
  final bool acked;

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: acked ? null : [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
        ],
      ),
    ).animate(onPlay: (c) => acked ? c.stop() : c.repeat(reverse: true))
     .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms);
  }

  Color _getColor() {
    switch (type) {
      case AttentionType.arrived: return AppColors.arrived;
      case AttentionType.callWaiter: return AppColors.call;
      case AttentionType.billRequest: return AppColors.bill;
    }
  }
}
