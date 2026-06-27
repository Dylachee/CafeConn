import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/cafe_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

class StaffChatListScreen extends StatelessWidget {
  const StaffChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final groups = state.groups.isEmpty ? _seedGroups() : state.groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () {},
          child: Row(
            children: [
              _GroupAvatar(group: groups[i]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groups[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Text('Последнее сообщение...', style: TextStyle(fontSize: 13, color: AppColors.ink55), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('12:45', style: TextStyle(fontSize: 11, color: AppColors.ink40)),
                  SizedBox(height: 4),
                  _UnreadBadge(count: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ChatGroup> _seedGroups() => const [
    ChatGroup(id: 'g1', name: 'Общий чат', pinned: true),
    ChatGroup(id: 'g2', name: 'Кухня', type: FeedType.kitchen),
    ChatGroup(id: 'g3', name: 'Бар', type: FeedType.bar),
  ];
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});
  final ChatGroup group;

  @override
  Widget build(BuildContext context) {
    final color = group.type == FeedType.kitchen ? AppColors.kitchen : group.type == FeedType.bar ? AppColors.bar : AppColors.espresso;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(14)),
      child: Icon(
        group.type == FeedType.kitchen ? Icons.restaurant_rounded : group.type == FeedType.bar ? Icons.local_bar_rounded : Icons.groups_rounded,
        color: color,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.espresso, borderRadius: BorderRadius.circular(10)),
      child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
