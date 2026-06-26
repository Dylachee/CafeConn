import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cafe_state.dart';
import '../widgets/common.dart';
import '../widgets/chat_group_row.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(
              title: 'Чаты',
              subtitle: 'Команда на связи',
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChatGroupRow(
                      group: group,
                      onTap: () {}, // TODO: Navigate to Chat Dialog
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
