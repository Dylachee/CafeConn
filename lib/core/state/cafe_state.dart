import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/hive_service.dart';
import '../services/mock_api.dart';

abstract class RealtimeHub {
  Stream<AttentionSignal> get attentionStream;
  Future<void> ackSignal(String tableId, AttentionType type);
  void simulateSignal(AttentionType type, String tableId);
}

class MockRealtimeHub implements RealtimeHub {
  final _controller = StreamController<AttentionSignal>.broadcast();
  
  @override
  Stream<AttentionSignal> get attentionStream => _controller.stream;

  @override
  Future<void> ackSignal(String tableId, AttentionType type) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  void simulateSignal(AttentionType type, String tableId) {
    _controller.add(AttentionSignal(
      tableId: tableId,
      type: type,
      createdAt: DateTime.now(),
    ));
  }
}

class CafeState extends ChangeNotifier {
  final _api = MockCafeApi();
  final hub = MockRealtimeHub();
  
  final List<AppUser> users = [];
  final List<CafeTable> tables = [];
  final List<MenuItem> menu = [];
  final List<CafeOrder> orders = [];
  final List<AppUser> staff = [];
  final List<ChatGroup> groups = [];
  final List<ChatMessage> messages = [];
  
  AppPrefs prefs = const AppPrefs();
  AppUser? currentUser;
  
  bool online = true;
  StreamSubscription? _attentionSub;

  CafeState() {
    _attentionSub = hub.attentionStream.listen(_onAttentionSignal);
  }

  @override
  void dispose() {
    _attentionSub?.cancel();
    super.dispose();
  }

  void _onAttentionSignal(AttentionSignal signal) {
    final tableIndex = tables.indexWhere((t) => t.id == signal.tableId);
    if (tableIndex != -1) {
      tables[tableIndex] = tables[tableIndex].copyWith(
        attention: signal.type,
        ack: false,
        attentionReason: signal.reason,
      );
      
      _notifyWithFeedback(signal);
      _persistTables();
      notifyListeners();
    }
  }

  void _notifyWithFeedback(AttentionSignal signal) {
    if (prefs.haptics) HapticFeedback.vibrate();
  }

  // --- Boot & Persistence ---

  Future<void> boot() async {
    await HiveService.init();
    
    prefs = HiveService.loadPrefs();
    
    users.addAll(_api.seedUsers());
    staff.addAll(users);
    currentUser = users.firstWhere((u) => u.id == 'waiter');

    final savedMenu = HiveService.loadMenu();
    if (savedMenu.isNotEmpty) {
      menu.addAll(savedMenu);
    } else {
      menu.addAll(_api.seedMenu());
      HiveService.saveMenu(menu);
    }

    final savedTables = HiveService.loadTables();
    if (savedTables.isNotEmpty) {
      tables.addAll(savedTables);
    } else {
      tables.addAll(_api.seedTables());
      HiveService.saveTables(tables);
    }

    final savedOrders = HiveService.loadOrders(menu);
    orders.addAll(savedOrders);

    notifyListeners();
  }

  void resetToDemo() {
    HiveService.resetAll();
    users.clear();
    tables.clear();
    menu.clear();
    orders.clear();
    staff.clear();
    groups.clear();
    messages.clear();
    boot();
  }

  void _persistTables() => HiveService.saveTables(tables);
  void _persistOrders() => HiveService.saveOrders(orders);
  void _persistPrefs() => HiveService.savePrefs(prefs);

  // --- Mutations ---

  void setGuestCount(String tableId, int count) {
    final i = tables.indexWhere((t) => t.id == tableId);
    if (i != -1) {
      tables[i] = tables[i].copyWith(guestCount: count);
      _persistTables();
      notifyListeners();
    }
  }

  void ackAttention(String tableId) {
    final i = tables.indexWhere((t) => t.id == tableId);
    if (i != -1 && tables[i].attention != null) {
      tables[i] = tables[i].copyWith(ack: true);
      _persistTables();
      notifyListeners();
      hub.ackSignal(tableId, tables[i].attention!);
    }
  }

  void clearAttention(String tableId) {
    final i = tables.indexWhere((t) => t.id == tableId);
    if (i != -1) {
      tables[i] = tables[i].copyWith(clearAttention: true);
      _persistTables();
      notifyListeners();
    }
  }

  void toggleItemDone(String orderId, String itemId) {
    final oIdx = orders.indexWhere((o) => o.id == orderId);
    if (oIdx != -1) {
      final iIdx = orders[oIdx].items.indexWhere((i) => i.id == itemId);
      if (iIdx != -1) {
        final newItems = List<CartLine>.from(orders[oIdx].items);
        newItems[iIdx] = newItems[iIdx].copyWith(done: !newItems[iIdx].done);
        orders[oIdx] = orders[oIdx].copyWith(items: newItems, updatedAt: DateTime.now());
        if (prefs.haptics) HapticFeedback.lightImpact();
        _persistOrders();
        notifyListeners();
      }
    }
  }

  void setItemReady(String orderId, String itemId, bool ready) {
    final oIdx = orders.indexWhere((o) => o.id == orderId);
    if (oIdx != -1) {
      final iIdx = orders[oIdx].items.indexWhere((i) => i.id == itemId);
      if (iIdx != -1) {
        final newItems = List<CartLine>.from(orders[oIdx].items);
        newItems[iIdx] = newItems[iIdx].copyWith(ready: ready);
        orders[oIdx] = orders[oIdx].copyWith(items: newItems, updatedAt: DateTime.now());
        _persistOrders();
        notifyListeners();
      }
    }
  }

  void addOrder(CafeOrder order) {
    orders.add(order);
    final i = tables.indexWhere((t) => t.id == order.tableId);
    if (i != -1) {
      tables[i] = tables[i].copyWith(
        status: TableStatus.occupied,
        currentOrderId: order.id,
        openedAt: tables[i].openedAt ?? DateTime.now(),
      );
    }
    _persistOrders();
    _persistTables();
    notifyListeners();
  }

  void updatePrefs(AppPrefs newPrefs) {
    prefs = newPrefs;
    _persistPrefs();
    notifyListeners();
  }
}
