import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/cafe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/segmented_control.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Station? _selectedStation;

  @override
  void initState() {
    super.initState();
    // Use station from settings if possible, otherwise default to kitchen
    _selectedStation = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final colors = Theme.of(context).appColors;
    
    _selectedStation ??= Station.values[state.settings.defaultOrdersZoneIndex];

    final filteredTickets = state.tickets.where((t) => t.station == _selectedStation && !t.ready).toList();
    
    final kCount = state.tickets.where((t) => t.station == Station.kitchen && !t.ready).length;
    final bCount = state.tickets.where((t) => t.station == Station.bar && !t.ready).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              title: 'Заказы',
              subtitle: '${_selectedStation == Station.kitchen ? "Кухня" : "Бар"} · ${filteredTickets.length} активных',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppSegmentedControl<Station>(
                selectedValue: _selectedStation!,
                onSelected: (v) => setState(() => _selectedStation = v),
                segments: [
                  AppSegment(
                    value: Station.kitchen,
                    label: 'КУХНЯ',
                    dotColor: colors.kitchen,
                    badgeCount: kCount,
                  ),
                  AppSegment(
                    value: Station.bar,
                    label: 'БАР',
                    dotColor: colors.bar,
                    badgeCount: bCount,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: filteredTickets.length,
                itemBuilder: (context, index) {
                  final ticket = filteredTickets[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: OrderCard(
                      ticket: ticket,
                      onMarkReady: () => state.markTicketReady(ticket),
                      onDiscuss: () {}, // TODO: Open Chat
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
