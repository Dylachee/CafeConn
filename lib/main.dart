import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  await Hive.openBox('cafeconnect');
  runApp(const CafeConnectApp());
}

class CafeConnectApp extends StatelessWidget {
  const CafeConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CafeState()..boot(),
      child: Consumer<CafeState>(
        builder: (context, state, _) {
          final router = GoRouter(
            refreshListenable: state,
            initialLocation: '/tables',
            routes: [
              GoRoute(
                  path: '/tables',
                  builder: (_, __) => const WaiterTableGridScreen()),
              GoRoute(
                  path: '/table-details',
                  builder: (_, __) => const TableDetailsScreen()),
              GoRoute(
                  path: '/waiter-menu',
                  builder: (_, __) => const WaiterOrderScreen()),
              GoRoute(
                  path: '/orders',
                  builder: (_, __) => const UnifiedOrderFeedScreen()),
              GoRoute(
                  path: '/menu-staff',
                  builder: (_, __) => const StaffMenuScreen()),
              GoRoute(
                  path: '/chats',
                  builder: (_, __) => const StaffChatListScreen()),
              GoRoute(
                  path: '/chat', builder: (_, __) => const StaffChatScreen()),
              GoRoute(
                  path: '/panel', builder: (_, __) => const StaffPanelScreen()),
              GoRoute(
                  path: '/settings',
                  builder: (_, __) => const SettingsScreen()),
            ],
          );
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'CafeConnect Staff',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.themeMode,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(state.textScale)),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}

class AppTheme {
  // Фон и поверхности (тёплые)
  static const bg = Color(0xFFF2EFE8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFBF9F4);
  static const surfaceSunken = Color(0xFFEBE6DB);

  // Текст
  static const ink = Color(0xFF1E1B16);
  static const ink2 = Color(0x8C1E1B16);
  static const ink3 = Color(0x661E1B16);
  static const separator = Color(0xFFE7E2D8);

  // Действия
  static const cta = Color(0xFF221F1A); // Эспрессо

  // Семантика статусов
  static const success = Color(0xFF3E9C63);
  static const warning = Color(0xFFE0823A); // Зона Кухня
  static const danger = Color(0xFFD9564A);
  static const bar = Color(0xFF3C7BCF); // Зона Бар
  static const gold = Color(0xFFB98A3C);

  // Статусы столов
  static const tFree = Color(0xFFB8B1A3);
  static const tOccupied = Color(0xFF5B86B0);

  // Тени
  static const shadowCard = BoxShadow(
      color: Color(0x1F2B2418),
      blurRadius: 22,
      spreadRadius: -14,
      offset: Offset(0, 10));
  static const shadowSheet = BoxShadow(
      color: Color(0x472B2418),
      blurRadius: 60,
      spreadRadius: -20,
      offset: Offset(0, 30));

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cta,
        brightness: brightness,
        background: isDark ? const Color(0xFF17150F) : bg,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF17150F) : bg,
      textTheme: GoogleFonts.interTextTheme(),
    );
    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      cardColor: isDark ? const Color(0xFF201C15) : card,
      dividerColor: isDark ? const Color(0xFF2E2920) : separator,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6),
        titleLarge: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4),
        titleMedium: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0),
        labelSmall: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0),
      ),
    );
  }
}

enum UserRole { waiter, cook, bartender, manager, admin }

enum TableStatus { free, occupied, awaitingPayment, ready, late, newOrder }

enum OrderStatus { accepted, cooking, ready, completed }

enum FeedType { kitchen, bar }

enum ButtonKind { primary, secondary, ghost, dark }

enum MessageKind { text, tableCard, orderCard }

class AppUser {
  AppUser(this.id, this.name, this.role, this.status,
      {this.online = true, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  final String id;
  String name;
  UserRole role;
  String status;
  bool online;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.index,
        'status': status,
        'online': online,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
  static AppUser fromJson(Map<String, dynamic> j) => AppUser(
        j['id'],
        j['name'],
        UserRole.values[j['role'] as int],
        j['status'],
        online: j['online'] as bool,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      );
}

class CafeTable {
  CafeTable(this.id, this.number, this.color, this.status, this.guestCount,
      {this.currentOrderId, this.notes = const []});
  final String id;
  final int number;
  Color color;
  TableStatus status;
  int guestCount;
  String? currentOrderId;
  List<String> notes;
  DateTime? openedAt;
  String waiterName = '—';

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'colorValue': color.value,
        'status': status.index,
        'guestCount': guestCount,
        'notes': notes,
        'openedAt': openedAt?.millisecondsSinceEpoch,
        'waiterName': waiterName,
      };
  static CafeTable fromJson(Map<String, dynamic> j) {
    final t = CafeTable(
        j['id'],
        j['number'] as int,
        Color(j['colorValue'] as int),
        TableStatus.values[j['status'] as int],
        j['guestCount'] as int,
        notes: List<String>.from(j['notes'] as List));
    if (j['openedAt'] != null)
      t.openedAt = DateTime.fromMillisecondsSinceEpoch(j['openedAt'] as int);
    t.waiterName = j['waiterName'] as String? ?? '—';
    return t;
  }
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.tags,
    required this.prepTime,
    this.available = true,
    this.promo = false,
    this.composition = '',
    this.allergens = const [],
  });
  final String id;
  String name;
  String description;
  double price;
  String category;
  final String imageUrl;
  List<String> tags;
  int prepTime;
  bool available;
  bool promo;
  String composition;
  List<String> allergens;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'tags': tags,
        'prepTime': prepTime,
        'available': available,
        'promo': promo,
        'composition': composition,
        'allergens': allergens,
      };
  static MenuItem fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        price: (j['price'] as num).toDouble(),
        category: j['category'],
        imageUrl: j['imageUrl'],
        tags: List<String>.from(j['tags']),
        prepTime: j['prepTime'] as int,
        available: j['available'] as bool,
        promo: j['promo'] as bool,
        composition: j['composition'],
        allergens: List<String>.from(j['allergens']),
      );
}

class CartLine {
  CartLine(
      {required this.item,
      this.quantity = 1,
      this.modifiers = '',
      this.sent = false})
      : lockedPrice = item.price;
  final MenuItem item;
  int quantity;
  final double lockedPrice;
  String modifiers;
  bool sent;
  double get total => lockedPrice * quantity;

  Map<String, dynamic> toJson() => {
        'itemId': item.id,
        'quantity': quantity,
        'modifiers': modifiers,
        'sent': sent,
        'lockedPrice': lockedPrice,
      };
}

class CafeOrder {
  CafeOrder({
    required this.id,
    required this.tableId,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.splitTo,
  });
  final String id;
  final String tableId;
  final List<CartLine> items;
  OrderStatus status;
  final DateTime createdAt;
  final FeedType splitTo;
  double get total => items.fold(0.0, (sum, line) => sum + line.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.index,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'splitTo': splitTo.index,
      };
  static CafeOrder fromJson(Map<String, dynamic> j, List<MenuItem> menu) =>
      CafeOrder(
        id: j['id'],
        tableId: j['tableId'],
        items: (j['items'] as List).map((e) {
          final m = e as Map<String, dynamic>;
          final item = menu.firstWhere((mi) => mi.id == m['itemId'],
              orElse: () => menu.first);
          return CartLine(
              item: item,
              quantity: m['quantity'] as int,
              modifiers: m['modifiers'] as String,
              sent: m['sent'] as bool);
        }).toList(),
        status: OrderStatus.values[j['status'] as int],
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        splitTo: FeedType.values[j['splitTo'] as int],
      );
}

class ChatGroup {
  ChatGroup(this.id, this.name, this.type, this.members,
      {this.pinned = false, this.muted = false});
  final String id;
  String name;
  FeedType? type;
  List<String> members;
  bool pinned;
  bool muted;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.tags,
    required this.timestamp,
    this.own = false,
    this.voice = false,
    this.reactions = const [],
    this.kind = MessageKind.text,
    this.refId,
  });
  final String id;
  final String groupId;
  final String senderId;
  final String text;
  final List<String> tags;
  final DateTime timestamp;
  final bool own;
  final bool voice;
  List<String> reactions;
  final MessageKind kind;
  final String? refId;
}

class CafeState extends ChangeNotifier {
  final _api = MockCafeApi();
  Box get _box => Hive.box('cafeconnect');
  final List<AppUser> users = [];
  final List<CafeTable> tables = [];
  final List<MenuItem> menu = [];
  final List<CafeOrder> orders = [];
  final List<AppUser> staff = [];
  final List<ChatGroup> groups = [];
  final List<ChatMessage> messages = [];
  final Map<String, List<CartLine>> tableChecks = {};
  final List<Map<String, dynamic>> _pendingQueue = [];
  int get pendingQueueCount => _pendingQueue.length;
  final syncSuccess = ValueNotifier<bool>(false);

  AppUser? currentUser;
  CafeTable? currentTable;
  ChatGroup? currentGroup;
  String selectedCategory = 'Все';
  String menuSearch = '';
  bool online = true;
  bool noConnectionDismissed = false;
  bool soundEnabled = true;
  ThemeMode themeMode = ThemeMode.light;

  int tablesPerRow = 3;
  bool showGestureHints = true;
  String currencySymbol = r'$';
  bool currencyPrefix = false;
  bool use24hClock = true;
  double textScale = 1.0;
  bool hapticsEnabled = true;
  double soundVolume = 0.6;
  int lateThresholdMinutes = 20;
  bool showNewOrderBanner = true;
  bool showSyncToast = true;
  bool offlineModeSimulated = false;
  String activeUserName = 'Елена Соколова';

  void setSetting<T>(String key, T value, Function(T) apply) {
    apply(value);
    _box.put(key, value);
    notifyListeners();
  }

  Timer? _retryTimer;
  Timer? _fakeRealtimeTimer;

  void refresh() => notifyListeners();

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _box.put('theme', themeMode.index);
    notifyListeners();
  }

  Future<void> boot() async {
    // --- Seed users & staff (these are config, not user-editable, re-seed always) ---
    users
      ..clear()
      ..addAll(_api.seedUsers());
    staff
      ..clear()
      ..addAll(users);

    // --- Menu: load from Hive if present, else seed ---
    final rawMenu = _box.get('menu') as String?;
    if (rawMenu != null) {
      final list = jsonDecode(rawMenu) as List;
      menu
        ..clear()
        ..addAll(list.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)));
    } else {
      menu
        ..clear()
        ..addAll(_api.seedMenu());
      _saveMenu();
    }

    // --- Tables: load from Hive if present, else seed ---
    final rawTables = _box.get('tables') as String?;
    if (rawTables != null) {
      final list = jsonDecode(rawTables) as List;
      tables
        ..clear()
        ..addAll(
            list.map((e) => CafeTable.fromJson(e as Map<String, dynamic>)));
      // Restore checks (tableChecks) for each table
      for (final t in tables) {
        final rawCheck = _box.get('check_${t.id}') as String?;
        if (rawCheck != null) {
          final lines = jsonDecode(rawCheck) as List;
          tableChecks[t.id] = lines.map((e) {
            final m = e as Map<String, dynamic>;
            final item = menu.firstWhere((mi) => mi.id == m['itemId'],
                orElse: () => menu.first);
            return CartLine(
                item: item,
                quantity: m['quantity'] as int,
                modifiers: m['modifiers'] as String,
                sent: m['sent'] as bool);
          }).toList();
        }
      }
    } else {
      tables
        ..clear()
        ..addAll(_api.seedTables());
      _saveTables();
    }

    // --- Chats: always re-seed (ephemeral for now) ---
    groups
      ..clear()
      ..addAll(_api.seedGroups(staff));
    messages
      ..clear()
      ..addAll(_api.seedMessages(groups));

    // --- Settings ---
    final cachedTheme = _box.get('theme') as int?;
    if (cachedTheme != null) themeMode = ThemeMode.values[cachedTheme];

    tablesPerRow = _box.get('tablesPerRow') as int? ?? 3;
    showGestureHints = _box.get('showGestureHints') as bool? ?? true;
    currencySymbol = _box.get('currencySymbol') as String? ?? r'$';
    currencyPrefix = _box.get('currencyPrefix') as bool? ?? false;
    use24hClock = _box.get('use24hClock') as bool? ?? true;
    textScale = (_box.get('textScale') as num?)?.toDouble() ?? 1.0;
    hapticsEnabled = _box.get('hapticsEnabled') as bool? ?? true;
    soundVolume = (_box.get('soundVolume') as num?)?.toDouble() ?? 0.6;
    lateThresholdMinutes = _box.get('lateThreshold') as int? ?? 20;
    activeUserName = _box.get('activeUserName') as String? ?? 'Елена Соколова';
    soundEnabled = _box.get('soundEnabled') as bool? ?? true;

    _retryTimer = Timer.periodic(5.seconds, (_) => retryQueuedOrders());
    _fakeRealtimeTimer =
        Timer.periodic(12.seconds, (_) => simulateRealtimeOrder());
    currentUser = users.firstOrNull;
    notifyListeners();
  }

  void _saveTables() {
    _box.put('tables', jsonEncode(tables.map((t) => t.toJson()).toList()));
    for (final t in tables) {
      final check = tableChecks[t.id];
      if (check != null) {
        _box.put(
            'check_${t.id}', jsonEncode(check.map((l) => l.toJson()).toList()));
      }
    }
  }

  void _saveMenu() =>
      _box.put('menu', jsonEncode(menu.map((m) => m.toJson()).toList()));

  void addNote(CafeTable table, String note) {
    table.notes = [...table.notes, note];
    _saveTables();
    notifyListeners();
  }

  void removeNote(CafeTable table, int index) {
    table.notes.removeAt(index);
    table.notes = [...table.notes];
    _saveTables();
    notifyListeners();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _fakeRealtimeTimer?.cancel();
    super.dispose();
  }

  List<String> get categories =>
      ['Все', ...menu.map((m) => m.category).toSet()];

  List<MenuItem> filteredMenu({String? category}) {
    final cat = category ?? selectedCategory;
    return menu.where((item) {
      final okCategory = cat == 'Все' || item.category == cat;
      final okSearch = menuSearch.isEmpty ||
          item.name.toLowerCase().contains(menuSearch.toLowerCase());
      return okCategory && okSearch;
    }).toList();
  }

  List<CartLine> tableCart(String tableId) =>
      tableChecks.putIfAbsent(tableId, () => []);

  void addToCart(MenuItem item, int quantity, String modifiers,
      {String? tableId}) {
    if (tableId == null) return;
    final lines = tableCart(tableId);
    final existing = lines.firstWhereOrNull(
        (line) => line.item.id == item.id && line.modifiers == modifiers);
    if (existing == null) {
      lines.add(CartLine(item: item, quantity: quantity, modifiers: modifiers));
    } else {
      existing.quantity = quantity;
      existing.modifiers = modifiers;
    }
    HapticFeedback.selectionClick();
    _saveTables();
    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta, {String? tableId}) {
    line.quantity = max(1, line.quantity + delta);
    HapticFeedback.selectionClick();
    _saveTables();
    notifyListeners();
  }

  void deleteLine(CartLine line, {String? tableId}) {
    if (tableId == null) return;
    tableCart(tableId).remove(line);
    HapticFeedback.mediumImpact();
    _saveTables();
    notifyListeners();
  }

  Future<CafeOrder> submitOrder({String? tableId, FeedType? onlyFor}) async {
    final table = tables.firstWhere(
        (t) => t.id == (tableId ?? currentTable?.id ?? tables.first.id));
    final source = tableCart(table.id);

    final toSend = source.where((l) => !l.sent).where((l) {
      if (onlyFor != null) {
        final isDrink =
            l.item.category == 'Напитки' || l.item.category == 'Кофе';
        return onlyFor == FeedType.bar ? isDrink : !isDrink;
      }
      return true;
    }).toList();

    if (toSend.isEmpty) return orders.last;

    final food = toSend
        .where((l) => l.item.category != 'Напитки' && l.item.category != 'Кофе')
        .toList();
    final drinks = toSend
        .where((l) => l.item.category == 'Напитки' || l.item.category == 'Кофе')
        .toList();

    final List<CafeOrder> newOrders = [];
    if (food.isNotEmpty) {
      newOrders.add(_makeOrder(
          table,
          food
              .map((l) => CartLine(
                  item: l.item,
                  quantity: l.quantity,
                  modifiers: l.modifiers,
                  sent: true))
              .toList(),
          FeedType.kitchen));
      for (var l in food) l.sent = true;
    }
    if (drinks.isNotEmpty) {
      newOrders.add(_makeOrder(
          table,
          drinks
              .map((l) => CartLine(
                  item: l.item,
                  quantity: l.quantity,
                  modifiers: l.modifiers,
                  sent: true))
              .toList(),
          FeedType.bar));
      for (var l in drinks) l.sent = true;
    }

    if (!online) {
      _pendingQueue
          .addAll(newOrders.map((o) => {'type': 'order', 'data': o.toJson()}));
      _box.put('pendingQueue', _pendingQueue.length);
    } else {
      orders.addAll(newOrders);
    }

    table.status = TableStatus.occupied;
    if (newOrders.isNotEmpty) {
      table.currentOrderId = newOrders.last.id;
      addSystemMessage(newOrders.last);
    }

    HapticFeedback.mediumImpact();
    _saveTables();
    notifyListeners();
    return newOrders.isNotEmpty ? newOrders.last : orders.last;
  }

  CafeOrder _makeOrder(CafeTable table, List<CartLine> lines, FeedType feed) {
    return CafeOrder(
      id: (1200 + orders.length + 1).toString(),
      tableId: table.id,
      items: lines,
      status: OrderStatus.cooking,
      createdAt: DateTime.now(),
      splitTo: feed,
    );
  }

  void discussInChat(CafeOrder order, ChatGroup group, String comment) {
    final table = tables.firstWhereOrNull((t) => t.id == order.tableId);
    final text =
        '#discuss Заказ Стол${table?.number.toString().padLeft(2, '0') ?? '??'}:${order.items.map((e) => '${e.quantity}x${e.item.name}').join(', ')}\n\n$comment';
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: group.id,
      senderId: currentUser?.id ?? 'system',
      text: text,
      tags: const ['#discuss'],
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void forwardTable(CafeTable table, ChatGroup group, String comment) {
    final text =
        '#forward Стол${table.number.toString().padLeft(2, '0')} ·${statusLabel(table.status)}\n\n$comment';
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: group.id,
      senderId: currentUser?.id ?? 'system',
      text: text,
      tags: const ['#forward'],
      timestamp: DateTime.now(),
      kind: MessageKind.tableCard,
      refId: table.id,
    ));
    notifyListeners();
  }

  void addSystemMessage(CafeOrder order) {
    final group = groups.firstWhereOrNull((g) => g.type == order.splitTo);
    if (group == null) return;
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: group.id,
      senderId: 'system',
      text:
          '#orders Новый заказ #${order.id}:${order.items.map((e) => '${e.quantity}x${e.item.name}').join(', ')}',
      tags: const ['#orders'],
      timestamp: DateTime.now(),
      kind: MessageKind.orderCard,
      refId: order.id,
    ));
  }

  void toggleOnline() {
    online = !online;
    noConnectionDismissed = false;
    notifyListeners();
  }

  void retryQueuedOrders() {
    if (!online || _pendingQueue.isEmpty) return;
    for (final item in _pendingQueue) {
      if (item['type'] == 'order') {
        orders.add(CafeOrder.fromJson(item['data'], menu));
      }
    }
    _pendingQueue.clear();
    _box.delete('pendingQueue');
    syncSuccess.value = true;
    notifyListeners();
  }

  void simulateRealtimeOrder() {
    if (!online || orders.length > 10) return;
    final table = tables[Random().nextInt(tables.length)];
    if (table.status != TableStatus.free) return;
    final item = menu[Random().nextInt(menu.length)];
    final order = _makeOrder(
        table,
        [CartLine(item: item, quantity: Random().nextInt(2) + 1)],
        item.category == 'Кофе' ? FeedType.bar : FeedType.kitchen);
    orders.add(order);
    table.status = TableStatus.newOrder;
    addSystemMessage(order);
    notifyListeners();
  }

  void closeTable(CafeTable table) {
    table.status = TableStatus.free;
    table.currentOrderId = null;
    table.guestCount = 0;
    tableChecks[table.id]?.clear();
    _saveTables();
    notifyListeners();
  }

  void toggleAvailability(MenuItem item) {
    item.available = !item.available;
    HapticFeedback.selectionClick();
    _saveMenu();
    notifyListeners();
  }

  void addTable(int number, Color color) {
    final id = 't${tables.length + 1}';
    tables.add(CafeTable(id, number, color, TableStatus.free, 0));
    _saveTables();
    notifyListeners();
  }

  void editTable(CafeTable table, int number, Color color) {
    final index = tables.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      tables[index] = CafeTable(
          table.id, number, color, table.status, table.guestCount,
          currentOrderId: table.currentOrderId, notes: table.notes);
      _saveTables();
      notifyListeners();
    }
  }

  void deleteTable(CafeTable table) {
    tables.remove(table);
    _saveTables();
    notifyListeners();
  }

  void createStaff(String name, UserRole role) {
    final user = AppUser('u${users.length + 1}', name, role, 'Смена активна');
    users.add(user);
    notifyListeners();
  }

  void sendMessage(String text, {bool voice = false}) {
    if (currentGroup == null || text.trim().isEmpty) return;
    final tags = RegExp(r'#[\wа-яА-Я]+')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: currentGroup!.id,
      senderId: currentUser?.id ?? 'me',
      text: text,
      tags: tags,
      timestamp: DateTime.now(),
      own: true,
      voice: voice,
    ));
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void react(ChatMessage message, String reaction) {
    message.reactions = [...message.reactions, reaction];
    notifyListeners();
  }

  void markReady(CafeOrder order) {
    order.status = order.status == OrderStatus.ready
        ? OrderStatus.completed
        : OrderStatus.ready;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Future<void> resetToDemo() async {
    await _box.clear();
    tableChecks.clear();
    await boot();
  }
}

class MockCafeApi {
  List<AppUser> seedUsers() => [
        AppUser('admin', 'Администратор', UserRole.admin, 'В системе'),
        AppUser('manager', 'Алекс Ривера', UserRole.manager, 'Онлайн'),
        AppUser('waiter', 'Елена Соколова', UserRole.waiter, 'На смене'),
        AppUser('cook', 'Марко Чен', UserRole.cook, 'На кухне'),
        AppUser('bar', 'Сара Дженкинс', UserRole.bartender, 'За баром'),
      ];

  List<CafeTable> seedTables() => List.generate(12, (i) {
        final statuses = [
          TableStatus.free,
          TableStatus.occupied,
          TableStatus.awaitingPayment,
          TableStatus.ready,
          TableStatus.late
        ];
        final status = statuses[i % statuses.length];
        return CafeTable('t${i + 1}', i + 1, AppTheme.cta, status,
            status == TableStatus.free ? 0 : (i % 4) + 1,
            notes: i % 3 == 0 ? ['Аллергия на орехи', 'VIP'] : []);
      });

  List<MenuItem> seedMenu() => [
        MenuItem(
            id: 'm1',
            name: 'Флэт уайт',
            description: 'Шёлковый эспрессо с мягким молоком.',
            price: 4.50,
            category: 'Кофе',
            imageUrl:
                'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
            tags: ['Dairy'],
            prepTime: 4,
            promo: true,
            composition: 'Эспрессо, молоко 3.2%, микропена.',
            allergens: ['Dairy']),
        MenuItem(
            id: 'm2',
            name: 'Круассан',
            description: 'Тёплый хрустящий круассан.',
            price: 3.80,
            category: 'Выпечка',
            imageUrl:
                'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
            tags: ['Gluten'],
            prepTime: 3,
            composition: 'Мука, сливочное масло, сахар, дрожжи.',
            allergens: ['Gluten', 'Eggs']),
        MenuItem(
            id: 'm3',
            name: 'Бенедикт',
            description: 'Яйца пашот с голландским соусом.',
            price: 18.50,
            category: 'Завтраки',
            imageUrl:
                'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
            tags: ['Eggs'],
            prepTime: 14,
            promo: true,
            composition: 'Яйца, бриошь, бекон, голландский соус.',
            allergens: ['Eggs', 'Gluten', 'Dairy']),
        MenuItem(
            id: 'm4',
            name: 'Авокадо тост',
            description: 'Заквасочный хлеб и авокадо.',
            price: 12.00,
            category: 'Завтраки',
            imageUrl:
                'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
            tags: ['Vegan'],
            prepTime: 8,
            composition: 'Заквасочный хлеб, авокадо, семена, чили.',
            allergens: ['Gluten']),
        MenuItem(
            id: 'm5',
            name: 'Колд брю',
            description: 'Кофе холодной экстракции.',
            price: 5.20,
            category: 'Кофе',
            imageUrl:
                'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
            tags: ['Vegan'],
            prepTime: 2,
            composition: 'Кофе холодной заварки 12 часов.'),
        MenuItem(
            id: 'm6',
            name: 'Лимонад',
            description: 'Домашний лимонад с базиликом.',
            price: 4.90,
            category: 'Напитки',
            imageUrl:
                'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400',
            tags: ['Vegan'],
            prepTime: 3,
            composition: 'Лимонный сок, сахарный сироп, базилик, газировка.'),
      ];

  List<ChatGroup> seedGroups(List<AppUser> staff) => [
        ChatGroup('g1', 'Общий чат', null, staff.map((s) => s.id).toList(),
            pinned: true),
        ChatGroup(
            'g2',
            'Кухня',
            FeedType.kitchen,
            staff
                .where((s) =>
                    s.role == UserRole.cook ||
                    s.role == UserRole.manager ||
                    s.role == UserRole.admin)
                .map((s) => s.id)
                .toList(),
            pinned: true),
        ChatGroup(
            'g3',
            'Бар',
            FeedType.bar,
            staff
                .where((s) =>
                    s.role == UserRole.bartender ||
                    s.role == UserRole.manager ||
                    s.role == UserRole.admin)
                .map((s) => s.id)
                .toList()),
      ];

  List<ChatMessage> seedMessages(List<ChatGroup> groups) => [
        ChatMessage(
            id: 'm1',
            groupId: groups[0].id,
            senderId: 'waiter',
            text: '#orders Стол 04 сделал заказ, проверяю напитки.',
            tags: ['#orders'],
            timestamp: DateTime.now().subtract(Duration(minutes: 22))),
        ChatMessage(
            id: 'm2',
            groupId: groups[1].id,
            senderId: 'cook',
            text: '#kitchen Бенедикт будет готов через минуту.',
            tags: ['#kitchen'],
            timestamp: DateTime.now().subtract(Duration(minutes: 11))),
      ];
}

// ================= COMPONENT WIDGETS =================

class AppButton extends StatefulWidget {
  const AppButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.kind = ButtonKind.primary,
      this.loading = false,
      this.color});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonKind kind;
  final bool loading;
  final Color? color;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.kind == ButtonKind.primary;
    final dark = widget.kind == ButtonKind.dark;
    final ghost = widget.kind == ButtonKind.ghost;

    final bg = widget.color ??
        (primary
            ? AppTheme.cta
            : dark
                ? AppTheme.ink
                : ghost
                    ? Colors.transparent
                    : AppTheme.surfaceAlt);
    final fg = primary || dark ? Colors.white : AppTheme.ink;

    return GestureDetector(
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      child: AnimatedScale(
        duration: 200.ms,
        curve: Curves.elasticOut,
        scale: down ? .97 : 1,
        child: AnimatedContainer(
          duration: 200.ms,
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: ghost
                    ? Colors.transparent
                    : (primary || dark ? bg : AppTheme.separator)),
            boxShadow: primary && !down
                ? [
                    const BoxShadow(
                        color: Color(0x1F2B2418),
                        blurRadius: 22,
                        spreadRadius: -14,
                        offset: Offset(0, 10))
                  ]
                : null,
          ),
          child: widget.loading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 19),
                      const SizedBox(width: 8)
                    ],
                    Flexible(
                        child: Text(widget.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                fontSize: 16))),
                  ],
                ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.onTap,
      this.index = 0,
      this.borderColor,
      this.elevation = true,
      this.height,
      this.width});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final int index;
  final Color? borderColor;
  final bool elevation;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? const Color(0xFFF0EBE1)),
        boxShadow: elevation
            ? [
                const BoxShadow(
                    color: Color(0x0A2B2418),
                    blurRadius: 2,
                    offset: Offset(0, 1)),
                const BoxShadow(
                    color: Color(0x1F2B2418),
                    blurRadius: 22,
                    spreadRadius: -14,
                    offset: Offset(0, 10)),
              ]
            : null,
      ),
      child: child,
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 260.ms)
        .slideY(begin: .08, end: 0);

    if (onTap == null) return box;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: box,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.showLabel = false});
  final TableStatus status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 2),
        ],
      ),
    );

    Widget animatedDot = dot;
    if (status == TableStatus.newOrder || status == TableStatus.ready) {
      animatedDot = dot
          .animate(onPlay: (c) => c.repeat())
          .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.3, 1.3),
              duration: 800.ms)
          .then()
          .scale(end: const Offset(1, 1), duration: 800.ms);
    } else if (status == TableStatus.late) {
      animatedDot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: .4, end: 1, duration: 500.ms);
    }

    if (!showLabel) return animatedDot;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          animatedDot,
          const SizedBox(width: 8),
          Text(
            statusLabel(status).toUpperCase(),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip(
      {super.key,
      required this.label,
      required this.active,
      required this.onTap,
      this.icon});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 200.ms,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.cta : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: active ? AppTheme.cta : const Color(0xFFE7E2D8)),
          boxShadow: active
              ? [
                  const BoxShadow(
                      color: Color(0x1F2B2418),
                      blurRadius: 12,
                      offset: Offset(0, 4))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: active ? Colors.white : AppTheme.ink2, size: 16),
              const SizedBox(width: 6)
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.ink2,
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteChip extends StatelessWidget {
  const NoteChip({super.key, required this.label, this.onDelete});
  final String label;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF3E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag, color: Color(0xFFA86A24), size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFA86A24),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child:
                  const Icon(Icons.close, color: Color(0xFFA86A24), size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.delta,
      required this.isPositive,
      required this.color,
      this.index = 0});
  final String label;
  final String value;
  final String delta;
  final bool isPositive;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      index: index,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.ink2,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isPositive ? AppTheme.success : AppTheme.danger),
              const SizedBox(width: 4),
              Text(delta,
                  style: TextStyle(
                      color: isPositive ? AppTheme.success : AppTheme.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper(
      {super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _step(Icons.remove, () => onChanged(max(1, value - 1))),
        SizedBox(
            width: 42,
            child: Center(
                child: Text('$value',
                    style: Theme.of(context).textTheme.titleMedium))),
        _step(Icons.add, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _step(IconData icon, VoidCallback action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        action();
      },
      child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              color: AppTheme.separator, shape: BoxShape.circle),
          child: Icon(icon, size: 18)),
    );
  }
}

class MenuImage extends StatelessWidget {
  const MenuImage(this.url,
      {super.key, this.radius = 16, this.aspectRatio = 1});
  final String url;
  final double radius;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => const ShimmerBox(),
          fadeInDuration: 300.ms,
          errorWidget: (_, __, ___) => Container(
              color: AppTheme.separator, child: const Icon(Icons.local_cafe)),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(color: AppTheme.separator)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 900.ms, color: Colors.white70);
  }
}

class MenuGridItem extends StatelessWidget {
  const MenuGridItem(
      {super.key,
      required this.item,
      required this.onTap,
      this.index = 0,
      this.trailing});
  final MenuItem item;
  final VoidCallback onTap;
  final int index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      index: index,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuImage(item.imageUrl),
          const SizedBox(height: 10),
          Text(item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                  child: Text(item.price.rub,
                      style: const TextStyle(
                          color: AppTheme.cta, fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

// ================= NAVIGATION & SCAFFOLD =================

class AppScaffold extends StatelessWidget {
  const AppScaffold(
      {super.key,
      required this.child,
      this.bottomNav,
      this.floatingActionButton});
  final Widget child;
  final Widget? bottomNav;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNav,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: child,
            ),
            if (!state.online && !state.noConnectionDismissed)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('Нет сети · заказы сохранятся локально',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600))),
                    IconButton(
                        onPressed: () {
                          state.noConnectionDismissed = true;
                          state.refresh();
                        },
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20)),
                  ]),
                ).animate().slideY(
                    begin: -1.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutQuart),
              ),
          ],
        ),
      ),
    );
  }
}

class StaffBottomNav extends StatelessWidget {
  const StaffBottomNav({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'Столы', icon: Icons.table_bar, path: '/tables'),
      (label: 'Заказы', icon: Icons.assignment, path: '/orders'),
      (label: 'Меню', icon: Icons.restaurant_menu, path: '/menu-staff'),
      (label: 'Чаты', icon: Icons.chat_bubble, path: '/chats'),
      (label: 'Панель', icon: Icons.analytics, path: '/panel'),
    ];

    int selected = items.indexWhere((e) => e.path == current);

    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            selectedIndex: max(0, selected),
            onDestinationSelected: (i) => context.go(items[i].path),
            destinations: items.map((e) {
              final active = items.indexOf(e) == selected;
              return NavigationDestination(
                icon: Icon(
                  e.icon,
                  color: active ? AppTheme.ink : const Color(0xFFA8A091),
                ),
                label: e.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ================= SCREENS =================

class WaiterTableGridScreen extends StatefulWidget {
  const WaiterTableGridScreen({super.key});
  @override
  State<WaiterTableGridScreen> createState() => _WaiterTableGridScreenState();
}

class _WaiterTableGridScreenState extends State<WaiterTableGridScreen> {
  TableStatus? filter;
  String search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final filtered = state.tables.where((t) {
      final okFilter = filter == null || t.status == filter;
      final okSearch = search.isEmpty || t.number.toString().contains(search);
      return okFilter && okSearch;
    }).toList();

    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/tables'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            title: 'Столы',
            subtitle:
                'Зал 1 · ${state.tables.where((t) => t.status != TableStatus.free).length} активных · ${state.tables.where((t) => t.status == TableStatus.free).length} свободно',
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [AppTheme.shadowCard]),
                  child: const Icon(Icons.add, color: AppTheme.cta),
                ),
                onPressed: () => _showTableForm(context),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [AppTheme.shadowCard]),
                  child: const Icon(Icons.filter_list, color: AppTheme.ink),
                ),
                onPressed: () => _showStatusPicker(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(
                hintText: 'Поиск стола...',
                prefixIcon: Icon(Icons.search, color: AppTheme.ink3),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryChip(
                    label: 'Все',
                    active: filter == null,
                    onTap: () => setState(() => filter = null)),
                ...TableStatus.values.map((s) => CategoryChip(
                      label: statusLabel(s),
                      active: filter == s,
                      onTap: () => setState(() => filter = s),
                      icon: Icons.circle,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(
                    icon: Icons.table_restaurant_outlined,
                    title: 'Ничего не найдено',
                    sub: 'Нет столов с таким фильтром или номером')
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: state.tablesPerRow,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.85),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final table = filtered[i];
                      return TableCard(
                        table: table,
                        index: i,
                        onTap: () {
                          state.currentTable = table;
                          GoRouter.of(context).push('/table-details');
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _showTableOptions(context, table);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTableOptions(BuildContext context, CafeTable table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Стол ${table.number}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            AppButton(
                label: 'Быстрый чек',
                icon: Icons.receipt_long,
                kind: ButtonKind.secondary,
                onPressed: () {
                  Navigator.pop(context);
                  _showQuickCheck(context, table);
                }),
            const SizedBox(height: 12),
            AppButton(
                label: 'Редактировать стол',
                icon: Icons.edit,
                kind: ButtonKind.secondary,
                onPressed: () {
                  Navigator.pop(context);
                  _showTableForm(context, table: table);
                }),
            const SizedBox(height: 12),
            AppButton(
                label: 'Удалить стол',
                icon: Icons.delete,
                kind: ButtonKind.ghost,
                color: AppTheme.danger,
                onPressed: () {
                  context.read<CafeState>().deleteTable(table);
                  Navigator.pop(context);
                }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTableForm(BuildContext context, {CafeTable? table}) {
    final numController =
        TextEditingController(text: table?.number.toString() ?? '');
    Color selectedColor = table?.color ?? AppTheme.cta;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(table == null ? 'Новый стол' : 'Редактировать стол',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                AppTextField(
                    controller: numController,
                    label: 'Номер стола',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                const Text('ЦВЕТ МЕТКИ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink3)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Colors.black,
                      Colors.brown,
                      Colors.blueGrey,
                      Colors.deepPurple,
                      Colors.indigo,
                      Colors.blue,
                      Colors.teal,
                      Colors.green,
                      Colors.orange,
                      Colors.red
                    ]
                        .map((c) => GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedColor = c),
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: selectedColor == c
                                        ? Border.all(
                                            color: AppTheme.ink, width: 3)
                                        : null),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: table == null ? 'Добавить' : 'Сохранить',
                  onPressed: () {
                    final num = int.tryParse(numController.text);
                    if (num != null) {
                      if (table == null) {
                        context.read<CafeState>().addTable(num, selectedColor);
                      } else {
                        context
                            .read<CafeState>()
                            .editTable(table, num, selectedColor);
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Фильтр по статусу',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AppButton(
                    label: 'Все столы',
                    kind: ButtonKind.secondary,
                    onPressed: () {
                      setState(() => filter = null);
                      Navigator.pop(context);
                    }),
                ...TableStatus.values.map((s) => AppButton(
                      label: statusLabel(s),
                      kind: ButtonKind.secondary,
                      onPressed: () {
                        setState(() => filter = s);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class TableCard extends StatelessWidget {
  const TableCard(
      {super.key,
      required this.table,
      required this.onTap,
      required this.onLongPress,
      this.index = 0});
  final CafeTable table;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final state = context.read<CafeState>();
    final color = statusColor(table.status);
    final isLate = table.status == TableStatus.late;

    return AppCard(
      index: index,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      borderColor: isLate ? AppTheme.danger : null,
      child: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              child: Text('#${table.number}',
                  style: const TextStyle(
                      color: AppTheme.ink3,
                      fontSize: 10,
                      fontWeight: FontWeight.w600))),
          Positioned(top: 0, right: 0, child: StatusBadge(table.status)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${table.number}',
                    style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel(table.status),
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                table.status == TableStatus.free
                    ? 'свободен'
                    : state
                        .tableCart(table.id)
                        .fold(0.0, (s, l) => s + l.total)
                        .rub,
                style: const TextStyle(
                    color: AppTheme.ink2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    )
        .animate(onPlay: isLate ? (c) => c.repeat(reverse: true) : null)
        .shimmer(duration: 2.seconds, color: Colors.white24);
  }
}

void _showQuickCheck(BuildContext context, CafeTable table) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x8C0D0B08),
    transitionDuration: 300.ms,
    pageBuilder: (_, __, ___) => QuickCheckOverlay(table: table),
    transitionBuilder: (context, anim, __, child) => BackdropFilter(
      filter:
          ImageFilter.blur(sigmaX: 14 * anim.value, sigmaY: 14 * anim.value),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
    ),
  );
}

class QuickCheckOverlay extends StatelessWidget {
  const QuickCheckOverlay({super.key, required this.table});
  final CafeTable table;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final items = state.tableCart(table.id);
    final total = items.fold(0.0, (s, l) => s + l.total);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [AppTheme.shadowSheet],
                ),
                child: Column(
                  children: [
                    Container(
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor(table.status),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)))),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Стол${table.number}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge),
                              const Spacer(),
                              StatusBadge(table.status, showLabel: true),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Открыт 14:05 · Елена',
                              style: TextStyle(
                                  color: AppTheme.ink2, fontSize: 13)),
                          const Divider(height: 32),
                          if (items.isEmpty)
                            const Center(
                                child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Text('Чек пуст',
                                        style: TextStyle(
                                            color: AppTheme.ink3,
                                            fontSize: 16))))
                          else
                            ...items.map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text('${l.quantity}×',
                                          style: GoogleFonts.robotoMono(
                                              color: AppTheme.ink2,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(l.item.name,
                                              style: GoogleFonts.robotoMono(
                                                  fontSize: 14))),
                                      Text(l.total.rub,
                                          style: GoogleFonts.robotoMono(
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                )),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ИТОГО',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20)),
                              Text(total.rub,
                                  style: GoogleFonts.robotoMono(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: AppTheme.cta)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: AppButton(
                                      label: 'Переслать',
                                      kind: ButtonKind.secondary,
                                      onPressed: () =>
                                          _showForwardSheet(context, table))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: AppButton(
                                      label: 'Открыть',
                                      onPressed: () {
                                        Navigator.pop(context);
                                        state.currentTable = table;
                                        GoRouter.of(context)
                                            .push('/table-details');
                                      })),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Нажмите на фон, чтобы закрыть',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class TableDetailsScreen extends StatefulWidget {
  const TableDetailsScreen({super.key});
  @override
  State<TableDetailsScreen> createState() => _TableDetailsScreenState();
}

class _TableDetailsScreenState extends State<TableDetailsScreen> {
  final noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final table = state.currentTable ?? state.tables.first;
    final lines = state.tableCart(table.id);
    final total = lines.fold(0.0, (sum, l) => sum + l.total);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.ink)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Стол${table.number}',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const Text('Открыт 14:05 · Елена',
                        style: TextStyle(color: AppTheme.ink2, fontSize: 13)),
                  ],
                ),
              ),
              StatusBadge(table.status, showLabel: true),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                const SectionTitle('Заказ'),
                if (lines.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 48, color: AppTheme.separator),
                          const SizedBox(height: 16),
                          const Text('Чек пуст',
                              style: TextStyle(
                                  color: AppTheme.ink2,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          AppButton(
                              label: 'Добавить блюдо',
                              kind: ButtonKind.secondary,
                              onPressed: () =>
                                  GoRouter.of(context).push('/waiter-menu')),
                        ],
                      ),
                    ),
                  )
                else
                  ...lines.map((l) => Dismissible(
                        key: ValueKey(l.hashCode),
                        onDismissed: (_) =>
                            state.deleteLine(l, tableId: table.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Text('${l.quantity}×',
                                  style: GoogleFonts.robotoMono(
                                      color: AppTheme.ink2,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.item.name,
                                        style: GoogleFonts.robotoMono(
                                            fontWeight: FontWeight.w600)),
                                    if (l.sent)
                                      Text(
                                          l.item.category == 'Напитки' ||
                                                  l.item.category == 'Кофе'
                                              ? 'В баре ✓'
                                              : 'На кухне ✓',
                                          style: TextStyle(
                                              color: l.item.category ==
                                                          'Напитки' ||
                                                      l.item.category == 'Кофе'
                                                  ? AppTheme.bar
                                                  : AppTheme.warning,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              Text(l.total.rub,
                                  style: GoogleFonts.robotoMono()),
                            ],
                          ),
                        ),
                      )),
                if (lines.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ИТОГО',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20)),
                      Text(total.rub,
                          style: GoogleFonts.robotoMono(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppTheme.cta)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                      label: 'Очистить стол',
                      icon: Icons.cleaning_services,
                      kind: ButtonKind.ghost,
                      color: AppTheme.danger,
                      onPressed: () {
                        state.closeTable(table);
                        context.pop();
                      }),
                  const SizedBox(height: 8),
                  AppButton(
                      label: 'Сдача / Оплата',
                      icon: Icons.calculate,
                      kind: ButtonKind.ghost,
                      onPressed: () => _showChangeCalculator(context, total)),
                  const SizedBox(height: 8),
                  AppButton(
                      label: 'Добавить в заказ',
                      icon: Icons.add,
                      kind: ButtonKind.secondary,
                      onPressed: () =>
                          GoRouter.of(context).push('/waiter-menu')),
                ],
                const SizedBox(height: 32),
                const SectionTitle('Заметки'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...table.notes.asMap().entries.map((e) => NoteChip(
                        label: e.value,
                        onDelete: () => state.removeNote(table, e.key))),
                    GestureDetector(
                      onTap: () => _showAddNote(context, table),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.separator),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: AppTheme.ink2),
                              SizedBox(width: 4),
                              Text('Добавить',
                                  style: TextStyle(
                                      color: AppTheme.ink2, fontSize: 13))
                            ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const SectionTitle('Статус стола'),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: TableStatus.values
                        .map((s) => CategoryChip(
                              label: statusLabel(s),
                              active: table.status == s,
                              onTap: () {
                                table.status = s;
                                state.refresh();
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          BlurBar(
            child: Row(
              children: [
                Expanded(
                    child: AppButton(
                        label: 'На кухню',
                        icon: Icons.restaurant,
                        color: AppTheme.warning,
                        onPressed: () {
                          state.submitOrder(
                              tableId: table.id, onlyFor: FeedType.kitchen);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Отправлено на кухню')));
                        })),
                const SizedBox(width: 12),
                Expanded(
                    child: AppButton(
                        label: 'В бар',
                        icon: Icons.local_bar,
                        color: AppTheme.bar,
                        onPressed: () {
                          state.submitOrder(
                              tableId: table.id, onlyFor: FeedType.bar);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Отправлено в бар')));
                        })),
                const SizedBox(width: 12),
                AppButton(
                    label: '',
                    icon: Icons.send,
                    kind: ButtonKind.secondary,
                    onPressed: () => _showForwardSheet(context, table)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNote(BuildContext context, CafeTable table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Новая заметка',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              AppTextField(
                  controller: noteController,
                  label: 'Текст заметки',
                  hint: 'Аллергия, ДР, VIP...'),
              const SizedBox(height: 20),
              AppButton(
                  label: 'Добавить',
                  onPressed: () {
                    if (noteController.text.isNotEmpty) {
                      context
                          .read<CafeState>()
                          .addNote(table, noteController.text);
                      noteController.clear();
                    }
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeCalculator(BuildContext context, double total) {
    final cashController = TextEditingController();
    double change = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Калькулятор сдачи',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('К оплате:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(total.rub,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cta)),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: cashController,
                  label: 'Получено наличных',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final cash = double.tryParse(v) ?? 0;
                    setModalState(() => change = max(0, cash - total));
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.surfaceSunken,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('СДАЧА:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                      Text(change.rub,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                    label: 'Готово', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WaiterOrderScreen extends StatelessWidget {
  const WaiterOrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final table = state.currentTable ?? state.tables.first;
    return AppScaffold(
      child: Column(
        children: [
          Header(
              title: 'Заказ Стол${table.number}',
              subtitle: 'Выберите блюда из меню'),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(pinned: true, delegate: _ChipHeader()),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 12, bottom: 80),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = state.filteredMenu()[index];
                      return MenuGridItem(
                          item: item,
                          index: index,
                          onTap: () => showDishDetails(context, item,
                              tableId: table.id));
                    }, childCount: state.filteredMenu().length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.cta,
        onPressed: () => context.pop(),
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}

class UnifiedOrderFeedScreen extends StatefulWidget {
  const UnifiedOrderFeedScreen({super.key});
  @override
  State<UnifiedOrderFeedScreen> createState() => _UnifiedOrderFeedScreenState();
}

class _UnifiedOrderFeedScreenState extends State<UnifiedOrderFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final kitchenOrders = state.orders
        .where((o) =>
            o.splitTo == FeedType.kitchen && o.status != OrderStatus.completed)
        .toList();
    final barOrders = state.orders
        .where((o) =>
            o.splitTo == FeedType.bar && o.status != OrderStatus.completed)
        .toList();

    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/orders'),
      child: Column(
        children: [
          Header(
              title: 'Заказы',
              subtitle: '${kitchenOrders.length + barOrders.length} активных'),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppTheme.surfaceSunken,
                borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [AppTheme.shadowCard]),
              labelColor: AppTheme.ink,
              unselectedLabelColor: AppTheme.ink2,
              tabs: [
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.restaurant,
                      size: 16, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Text('КУХНЯ (${kitchenOrders.length})')
                ])),
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_bar, size: 16, color: AppTheme.bar),
                  const SizedBox(width: 8),
                  Text('БАР (${barOrders.length})')
                ])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                kitchenOrders.isEmpty
                    ? _EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Всё готово',
                        sub: 'Нет активных заказов на кухне')
                    : ListView.builder(
                        itemCount: kitchenOrders.length,
                        itemBuilder: (_, i) =>
                            OrderCard(order: kitchenOrders[i], index: i)),
                barOrders.isEmpty
                    ? _EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Всё готово',
                        sub: 'Нет активных заказов в баре')
                    : ListView.builder(
                        itemCount: barOrders.length,
                        itemBuilder: (_, i) =>
                            OrderCard(order: barOrders[i], index: i)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.index = 0});
  final CafeOrder order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final table = state.tables.firstWhereOrNull((t) => t.id == order.tableId);
    final age = DateTime.now().difference(order.createdAt);
    final late = age.inMinutes > 20;
    final color = late
        ? AppTheme.danger
        : age.inMinutes > 15
            ? AppTheme.warning
            : AppTheme.success;
    final zoneColor =
        order.splitTo == FeedType.kitchen ? AppTheme.warning : AppTheme.bar;

    return AppCard(
      index: index,
      padding: EdgeInsets.zero,
      borderColor: late ? AppTheme.danger : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: zoneColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: zoneColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('СТОЛ${table?.number ?? '??'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            '#${order.id} ·${order.splitTo == FeedType.kitchen ? 'Кухня' : 'Бар'}',
                            style: const TextStyle(
                                color: AppTheme.ink2,
                                fontSize: 13,
                                fontWeight: FontWeight.w600))),
                    _LiveTimer(createdAt: order.createdAt, color: color),
                  ],
                ),
                const Divider(height: 24),
                ...order.items.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${line.quantity}×',
                              style: TextStyle(
                                  color: zoneColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(line.item.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600))),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: AppButton(
                            label: order.status == OrderStatus.ready
                                ? 'Завершить'
                                : 'Готово',
                            onPressed: () => state.markReady(order))),
                    const SizedBox(width: 12),
                    AppButton(
                        label: '',
                        icon: Icons.chat_bubble_outline,
                        kind: ButtonKind.secondary,
                        onPressed: () => _showDiscussModal(context, order)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: late ? (c) => c.repeat(reverse: true) : null).tint(
        color:
            late ? AppTheme.danger.withValues(alpha: .05) : Colors.transparent,
        duration: 500.ms);
  }
}

class StaffMenuScreen extends StatefulWidget {
  const StaffMenuScreen({super.key});

  @override
  State<StaffMenuScreen> createState() => _StaffMenuScreenState();
}

class _StaffMenuScreenState extends State<StaffMenuScreen> {
  final Set<MenuItem> selectedItems = {};
  bool selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final items = state.filteredMenu();

    return AppScaffold(
      bottomNav:
          selectionMode ? null : const StaffBottomNav(current: '/menu-staff'),
      child: Column(
        children: [
          Header(
            title: selectionMode ? 'Выбрано: ${selectedItems.length}' : 'Меню',
            subtitle: selectionMode
                ? 'Нажмите на позиции для выбора'
                : 'Витрина для персонала',
            actions: [
              if (selectionMode && selectedItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: AppTheme.success, size: 28),
                  onPressed: () =>
                      _showAssignTableSheet(context, selectedItems.toList()),
                ),
              IconButton(
                icon: Icon(selectionMode ? Icons.close : Icons.select_all,
                    color: AppTheme.ink),
                onPressed: () {
                  setState(() {
                    selectionMode = !selectionMode;
                    if (!selectionMode) selectedItems.clear();
                  });
                },
              ),
            ],
          ),
          if (!selectionMode) ...[
            AppCard(
              padding: EdgeInsets.zero,
              child: TextField(
                onChanged: (v) {
                  state.menuSearch = v;
                  state.refresh();
                },
                decoration: const InputDecoration(
                  hintText: 'Поиск блюда...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.ink3),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StaffMenuChips(),
          ],
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selectedItems.contains(item);
                final zoneColor =
                    (item.category == 'Напитки' || item.category == 'Кофе')
                        ? AppTheme.bar
                        : AppTheme.warning;

                return Stack(
                  children: [
                    AppCard(
                      index: i,
                      padding: const EdgeInsets.all(10),
                      borderColor: isSelected ? AppTheme.cta : null,
                      onTap: () {
                        if (selectionMode) {
                          setState(() {
                            if (isSelected)
                              selectedItems.remove(item);
                            else
                              selectedItems.add(item);
                          });
                        } else {
                          _showStaffDishDetails(context, item);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              MenuImage(item.imageUrl, radius: 13),
                              Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: zoneColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white,
                                              width: 1.5)))),
                              Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Row(children: [
                                        const Icon(Icons.schedule,
                                            size: 10, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text('${item.prepTime}м',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700))
                                      ]))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.price.rub,
                                  style: const TextStyle(
                                      color: AppTheme.cta,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: item.available
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                      shape: BoxShape.circle)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppTheme.cta, shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignTableSheet(BuildContext context, List<MenuItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Открыть стол',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Выберите стол для заказа из ${items.length} позиций',
                style: const TextStyle(color: AppTheme.ink2)),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemCount: context.read<CafeState>().tables.length,
                itemBuilder: (context, index) {
                  final table = context.read<CafeState>().tables[index];
                  return AppCard(
                    padding: EdgeInsets.zero,
                    elevation: false,
                    onTap: () {
                      for (var item in items) {
                        context
                            .read<CafeState>()
                            .addToCart(item, 1, '', tableId: table.id);
                      }
                      Navigator.pop(context);
                      setState(() {
                        selectionMode = false;
                        selectedItems.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Заказ добавлен на Стол ${table.number}')));
                    },
                    child: Center(
                      child: Text('${table.number}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
                label: 'Отмена',
                kind: ButtonKind.secondary,
                onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class StaffChatListScreen extends StatelessWidget {
  const StaffChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final groups = [...state.groups]
      ..sort((a, b) => b.pinned.toString().compareTo(a.pinned.toString()));
    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/chats'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Header(title: 'Чаты', subtitle: 'Команда на связи'),
        Expanded(
            child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (_, i) {
                  final group = groups[i];
                  final last = state.messages
                      .where((m) => m.groupId == group.id)
                      .lastOrNull;
                  final zoneColor = group.type == FeedType.kitchen
                      ? AppTheme.warning
                      : group.type == FeedType.bar
                          ? AppTheme.bar
                          : AppTheme.ink3;
                  return AppCard(
                    index: i,
                    onTap: () {
                      state.currentGroup = group;
                      GoRouter.of(context).push('/chat');
                    },
                    child: Row(children: [
                      Avatar(label: group.name, color: zoneColor),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(
                                  child: Text(group.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16))),
                              if (group.pinned)
                                const Icon(Icons.push_pin,
                                    size: 14, color: AppTheme.ink3)
                            ]),
                            Text(last?.text ?? 'Нет сообщений',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.ink2, fontSize: 13)),
                          ])),
                      const SizedBox(width: 8),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                last == null
                                    ? ''
                                    : '${last.timestamp.hour}:${last.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: AppTheme.ink3, fontSize: 11)),
                            const SizedBox(height: 5),
                            if (i == 0)
                              Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                      color: AppTheme.warning,
                                      shape: BoxShape.circle),
                                  child: const Text('2',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900))),
                          ]),
                    ]),
                  );
                })),
      ]),
    );
  }
}

class StaffChatScreen extends StatefulWidget {
  const StaffChatScreen({super.key});
  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  final input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final group = state.currentGroup ?? state.groups.first;
    final messages =
        state.messages.where((m) => m.groupId == group.id).toList();
    final zoneColor = group.type == FeedType.kitchen
        ? AppTheme.warning
        : group.type == FeedType.bar
            ? AppTheme.bar
            : AppTheme.ink3;

    return AppScaffold(
      child: Column(children: [
        Row(children: [
          IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: AppTheme.ink)),
          Avatar(label: group.name, color: zoneColor),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(group.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                const Text('8 онлайн',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
        Expanded(
            child: messages.isEmpty
                ? _EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Чатик пуст',
                    sub: 'Начните общение — отправьте первое сообщение')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      if (msg.kind == MessageKind.tableCard)
                        return ForwardedTableCard(message: msg);
                      return ChatBubble(message: msg);
                    })),
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(children: [
            Expanded(
                child: AppTextField(controller: input, label: 'Сообщение...')),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                state.sendMessage(input.text.trim());
                input.clear();
              },
              child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.cta,
                  child: Icon(Icons.send, color: Colors.white, size: 20)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class StaffPanelScreen extends StatefulWidget {
  const StaffPanelScreen({super.key});
  @override
  State<StaffPanelScreen> createState() => _StaffPanelScreenState();
}

class _StaffPanelScreenState extends State<StaffPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/panel'),
      child: Column(
        children: [
          Header(title: 'Панель', subtitle: 'Управление системой', actions: [
            IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => GoRouter.of(context).push('/settings')),
          ]),
          Container(
            height: 38,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.cta,
              labelColor: AppTheme.ink,
              unselectedLabelColor: AppTheme.ink2,
              tabs: const [
                Tab(text: 'Обзор'),
                Tab(text: 'Команда'),
                Tab(text: 'Меню'),
                Tab(text: 'Доступ')
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                const TeamManagementScreen(),
                const MenuManagementScreen(),
                _AccessTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: const [
            MetricCard(
                label: 'Выручка',
                value: '1,280 \$',
                delta: '▲ 12%',
                isPositive: true,
                color: AppTheme.success),
            MetricCard(
                label: 'Средний чек',
                value: '42.50 \$',
                delta: '▼ 3%',
                isPositive: false,
                color: AppTheme.danger,
                index: 1),
            MetricCard(
                label: 'Столы',
                value: '8 / 12',
                delta: 'активны',
                isPositive: true,
                color: AppTheme.tOccupied,
                index: 2),
            MetricCard(
                label: 'Готовка',
                value: '14 мин',
                delta: '▲ 2 мин',
                isPositive: false,
                color: AppTheme.warning,
                index: 3),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Выручка по часам'),
        AppCard(
          height: 160,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [30, 50, 80, 45, 90, 120, 70, 40]
                .map((h) => Container(
                    width: 20,
                    height: h.toDouble(),
                    decoration: BoxDecoration(
                        color:
                            h == 120 ? AppTheme.cta : const Color(0xFFE4D7C2),
                        borderRadius: BorderRadius.circular(4))))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return ListView(children: [
      Row(children: [
        const Expanded(child: SectionTitle('Сотрудники')),
        AppButton(
            label: 'Добавить',
            kind: ButtonKind.ghost,
            icon: Icons.person_add,
            onPressed: () => _showStaffForm(context))
      ]),
      ...state.users.map((u) => StaffMemberRow(user: u)),
    ]);
  }
}

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return ListView(children: [
      Row(children: [
        const Expanded(child: SectionTitle('Позиции')),
        AppButton(
            label: 'Добавить блюдо',
            kind: ButtonKind.ghost,
            icon: Icons.add,
            onPressed: () => _showMenuForm(context)),
      ]),
      ...state.menu.map((item) => AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () => _showMenuForm(context, item: item),
            child: Row(
              children: [
                MenuImage(item.imageUrl, radius: 10, aspectRatio: 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(item.price.rub,
                          style: const TextStyle(
                              color: AppTheme.cta,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                CupertinoSwitch(
                    value: item.available,
                    activeColor: AppTheme.success,
                    onChanged: (v) => state.toggleAvailability(item)),
              ],
            ),
          )),
    ]);
  }
}

void _showMenuForm(BuildContext context, {MenuItem? item}) {
  final name = TextEditingController(text: item?.name ?? '');
  final desc = TextEditingController(text: item?.description ?? '');
  final price = TextEditingController(text: item?.price.toString() ?? '');
  final category = TextEditingController(text: item?.category ?? 'Кухня');
  final prep = TextEditingController(text: item?.prepTime.toString() ?? '10');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item == null ? 'Новая позиция' : 'Редактировать позицию',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              AppTextField(controller: name, label: 'Название'),
              const SizedBox(height: 12),
              AppTextField(
                  controller: desc,
                  label: 'Описание',
                  hint: 'Состав, особенности...'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: AppTextField(
                          controller: price,
                          label: 'Цена',
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: AppTextField(
                          controller: prep,
                          label: 'Время (мин)',
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(controller: category, label: 'Категория'),
              const SizedBox(height: 24),
              AppButton(
                label: 'Сохранить',
                onPressed: () {
                  if (item == null) {
                    final newItem = MenuItem(
                      id: 'm${context.read<CafeState>().menu.length + 1}',
                      name: name.text,
                      description: desc.text,
                      price: double.tryParse(price.text) ?? 0.0,
                      category: category.text,
                      imageUrl:
                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                      tags: [],
                      prepTime: int.tryParse(prep.text) ?? 10,
                    );
                    context.read<CafeState>().menu.add(newItem);
                  } else {
                    item.name = name.text;
                    item.description = desc.text;
                    item.price = double.tryParse(price.text) ?? item.price;
                    item.category = category.text;
                    item.prepTime = int.tryParse(prep.text) ?? item.prepTime;
                  }
                  context.read<CafeState>().refresh();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccessTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SectionTitle('Права ролей'),
        _roleAccessCard('Официант', [
          ('Заказы', true),
          ('Счёт', true),
          ('Меню', true),
          ('Админка', false)
        ]),
        _roleAccessCard('Повар', [
          ('Заказы', true),
          ('Столы', false),
          ('Меню', true),
          ('Админка', false)
        ]),
      ],
    );
  }

  Widget _roleAccessCard(String title, List<(String, bool)> perms) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              children: perms
                  .map((p) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: p.$2
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : AppTheme.separator,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(p.$2 ? Icons.check_circle : Icons.circle,
                            size: 12,
                            color: p.$2 ? AppTheme.success : AppTheme.ink3),
                        const SizedBox(width: 4),
                        Text(p.$1,
                            style: TextStyle(
                                color: p.$2 ? AppTheme.success : AppTheme.ink3,
                                fontSize: 12,
                                fontWeight: FontWeight.w700))
                      ])))
                  .toList()),
        ]),
      );
}

// ================= HELPERS & UTILS =================

class Header extends StatelessWidget {
  const Header(
      {super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(color: AppTheme.ink2, fontSize: 14)),
        ])),
        ...actions,
      ]));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null)
          AppButton(label: 'Все', kind: ButtonKind.ghost, onPressed: action),
      ]));
}

class Avatar extends StatelessWidget {
  const Avatar(
      {super.key, required this.label, this.online = false, this.color});
  final String label;
  final bool online;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final initials = label
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1).toUpperCase())
        .take(2)
        .join();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: (color ?? AppTheme.cta).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14)),
      child: Center(
          child: Text(initials,
              style: TextStyle(
                  color: color ?? AppTheme.cta, fontWeight: FontWeight.w800))),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField(
      {super.key,
      required this.controller,
      required this.label,
      this.hint,
      this.obscure = false,
      this.keyboardType,
      this.onChanged});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppTheme.card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.separator)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.separator)),
          contentPadding: const EdgeInsets.all(16),
        ),
      );
}

class _StaffMenuChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: state.categories
            .map((c) => CategoryChip(
                  label: c,
                  active: state.selectedCategory == c,
                  onTap: () {
                    state.selectedCategory = c;
                    state.refresh();
                  },
                ))
            .toList(),
      ),
    );
  }
}

class _ChipHeader extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final state = context.watch<CafeState>();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: state.categories
            .map((c) => CategoryChip(
                label: c,
                active: state.selectedCategory == c,
                onTap: () {
                  state.selectedCategory = c;
                  state.refresh();
                }))
            .toList(),
      ),
    );
  }

  @override
  double get maxExtent => 58;
  @override
  double get minExtent => 58;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final own = message.own;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: own ? AppTheme.cta : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [AppTheme.shadowCard]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message.text,
              style: TextStyle(color: own ? Colors.white : AppTheme.ink)),
          const SizedBox(height: 4),
          Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: own ? Colors.white70 : AppTheme.ink3, fontSize: 11)),
        ]),
      ),
    );
  }
}

class ForwardedTableCard extends StatelessWidget {
  const ForwardedTableCard({super.key, required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final state = context.read<CafeState>();
    final table = state.tables.firstWhereOrNull((t) => t.id == message.refId);
    return AppCard(
      borderColor: AppTheme.tOccupied,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.forward, size: 14, color: AppTheme.tOccupied),
          const SizedBox(width: 8),
          Text('ПЕРЕСЛАНО · Елена',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tOccupied))
        ]),
        const SizedBox(height: 8),
        Text('Стол${table?.number ?? '??'}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 4),
        Text(message.text,
            style: const TextStyle(fontSize: 13, color: AppTheme.ink2)),
        const Divider(height: 24),
        AppButton(
            label: 'Открыть стол',
            kind: ButtonKind.ghost,
            onPressed: () {
              if (table != null) {
                state.currentTable = table;
                GoRouter.of(context).push('/table-details');
              }
            })
      ]),
    );
  }
}

class StaffMemberRow extends StatelessWidget {
  const StaffMemberRow({super.key, required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _showStaffForm(context, user: user),
      child: Row(children: [
        Avatar(label: user.name),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(roleLabel(user.role),
              style: const TextStyle(color: AppTheme.ink2, fontSize: 13)),
        ])),
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: user.online ? AppTheme.success : AppTheme.ink3,
                shape: BoxShape.circle)),
      ]),
    );
  }
}

void _showStaffForm(BuildContext context, {AppUser? user}) {
  final name = TextEditingController(text: user?.name ?? '');
  var role = user?.role ?? UserRole.waiter;
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
          builder: (context, set) => Container(
                decoration: const BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(user == null ? 'Новый сотрудник' : 'Редактировать',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  AppTextField(controller: name, label: 'Имя'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                      value: role,
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                              value: r, child: Text(roleLabel(r))))
                          .toList(),
                      onChanged: (v) => set(() => role = v!)),
                  const SizedBox(height: 20),
                  AppButton(
                      label: 'Сохранить',
                      onPressed: () {
                        if (user == null) {
                          context
                              .read<CafeState>()
                              .createStaff(name.text, role);
                        } else {
                          user.name = name.text;
                          user.role = role;
                          context.read<CafeState>().refresh();
                        }
                        Navigator.pop(context);
                      }),
                ]),
              )));
}

void _showForwardSheet(BuildContext context, CafeTable table) {
  final comment = TextEditingController();
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
            decoration: const BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Переслать',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  AppTextField(
                      controller: comment, label: 'Добавить комментарий...'),
                  const SizedBox(height: 24),
                  const Text('КУДА ОТПРАВИТЬ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink3)),
                  const SizedBox(height: 12),
                  ...context.read<CafeState>().groups.map((g) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Avatar(label: g.name),
                        title: Text(g.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing:
                            const Icon(Icons.send_rounded, color: AppTheme.cta),
                        onTap: () {
                          context
                              .read<CafeState>()
                              .forwardTable(table, g, comment.text);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Отправлено в чат')));
                        },
                      )),
                ]),
          ));
}

void _showDiscussModal(BuildContext context, CafeOrder order) {
  final comment = TextEditingController();
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
            decoration: const BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Обсудить заказ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              AppTextField(controller: comment, label: 'Комментарий...'),
              const SizedBox(height: 20),
              Wrap(
                  spacing: 8,
                  children: context
                      .read<CafeState>()
                      .groups
                      .map((g) => AppButton(
                          label: g.name,
                          kind: ButtonKind.secondary,
                          onPressed: () {
                            context
                                .read<CafeState>()
                                .discussInChat(order, g, comment.text);
                            Navigator.pop(context);
                          }))
                      .toList()),
            ]),
          ));
}

void _showStaffDishDetails(BuildContext context, MenuItem item) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
            decoration: const BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuImage(item.imageUrl, radius: 16, aspectRatio: 16 / 10),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: Text(item.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800))),
                    Text(item.price.rub,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cta))
                  ]),
                  const SizedBox(height: 12),
                  Text(item.description,
                      style:
                          const TextStyle(color: AppTheme.ink2, fontSize: 15)),
                  const SizedBox(height: 20),
                  const Text('СОСТАВ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink3)),
                  const SizedBox(height: 4),
                  Text(item.composition, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  const Text('АЛЛЕРГЕНЫ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink3)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      children: item.allergens.isEmpty
                          ? [
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Без аллергенов',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)))
                            ]
                          : item.allergens
                              .map((a) => NoteChip(label: a))
                              .toList()),
                  const SizedBox(height: 32),
                  AppButton(
                      label: 'Готово', onPressed: () => Navigator.pop(context)),
                ]),
          ));
}

Future<void> showDishDetails(BuildContext context, MenuItem item,
    {String? tableId}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DishDetailSheet(item: item, tableId: tableId),
  );
}

class DishDetailSheet extends StatefulWidget {
  const DishDetailSheet({super.key, required this.item, this.tableId});
  final MenuItem item;
  final String? tableId;
  @override
  State<DishDetailSheet> createState() => _DishDetailSheetState();
}

class _DishDetailSheetState extends State<DishDetailSheet> {
  int qty = 1;
  final notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(widget.item.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700))),
              Text(widget.item.price.rub,
                  style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.cta,
                      fontWeight: FontWeight.w700))
            ]),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(
                  child: Text('Количество',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              QuantityStepper(
                  value: qty, onChanged: (v) => setState(() => qty = v))
            ]),
            const SizedBox(height: 16),
            AppTextField(controller: notes, label: 'Пожелания'),
            const SizedBox(height: 24),
            AppButton(
                label: 'Добавить в чек ·${(widget.item.price * qty).rub}',
                onPressed: () {
                  context.read<CafeState>().addToCart(
                      widget.item, qty, notes.text.trim(),
                      tableId: widget.tableId);
                  Navigator.pop(context);
                }),
          ]),
    );
  }
}

class _LiveTimer extends StatefulWidget {
  const _LiveTimer({required this.createdAt, required this.color});
  final DateTime createdAt;
  final Color color;
  @override
  State<_LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<_LiveTimer> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(1.seconds, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.createdAt);
    return Text(
        '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
        style: GoogleFonts.robotoMono(
            color: widget.color, fontWeight: FontWeight.w700, fontSize: 16));
  }
}

class TypingDots extends StatelessWidget {
  const TypingDots({super.key});
  @override
  Widget build(BuildContext context) => Row(
      children: List.generate(
          3,
          (i) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppTheme.ink3, shape: BoxShape.circle))
              .animate(
                  delay: Duration(milliseconds: i * 150),
                  onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(.5, .5),
                  end: const Offset(1, 1),
                  duration: 450.ms)));
}

extension DurationNum on int {
  Duration get ms => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
}

extension Money on double {
  String get rub => '${toStringAsFixed(2)} \$';
}

String roleLabel(UserRole role) => switch (role) {
      UserRole.admin => 'Админ',
      UserRole.manager => 'Менеджер',
      UserRole.waiter => 'Официант',
      UserRole.cook => 'Повар',
      UserRole.bartender => 'Бармен',
    };

Color statusColor(TableStatus status) => switch (status) {
      TableStatus.free => AppTheme.tFree,
      TableStatus.occupied => AppTheme.tOccupied,
      TableStatus.awaitingPayment => AppTheme.gold,
      TableStatus.ready => AppTheme.success,
      TableStatus.late => AppTheme.danger,
      TableStatus.newOrder => AppTheme.warning,
    };

String statusLabel(TableStatus status) => switch (status) {
      TableStatus.free => 'Свободен',
      TableStatus.occupied => 'Занят',
      TableStatus.awaitingPayment => 'Счёт',
      TableStatus.ready => 'Готово',
      TableStatus.late => 'Задержка',
      TableStatus.newOrder => 'Новый',
    };

class BlurBar extends StatelessWidget {
  const BlurBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: .82),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(20)),
                child: child)),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13)));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Настройки',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection('Аккаунт', [
            _SettingsRow(
                label: 'Текущий сотрудник', value: state.activeUserName),
          ]),
          _SettingsSection('Внешний вид', [
            _SettingsSegmented(
              label: 'Тема',
              options: const ['Светлая', 'Тёмная', 'Системная'],
              selected: state.themeMode.index,
              onChanged: (i) => state.setSetting(
                  'theme', i, (v) => state.themeMode = ThemeMode.values[v]),
            ),
            _SettingsSegmented(
              label: 'Размер текста',
              options: const ['Мал.', 'Норм.', 'Бол.'],
              selected: state.textScale == 0.85
                  ? 0
                  : state.textScale == 1.15
                      ? 2
                      : 1,
              onChanged: (i) {
                final scales = [0.85, 1.0, 1.15];
                state.setSetting(
                    'textScale', scales[i], (v) => state.textScale = v);
              },
            ),
          ]),
          _SettingsSection('Дисплей', [
            _SettingsSegmented(
              label: 'Столов в ряду',
              options: const ['3', '4'],
              selected: state.tablesPerRow == 3 ? 0 : 1,
              onChanged: (i) => state.setSetting('tablesPerRow', i == 0 ? 3 : 4,
                  (v) => state.tablesPerRow = v),
            ),
            _SettingsToggle(
                label: 'Подсказки жестов',
                value: state.showGestureHints,
                onChanged: (v) => state.setSetting(
                    'showGestureHints', v, (x) => state.showGestureHints = x)),
            _SettingsToggle(
                label: '24-часовой формат',
                value: state.use24hClock,
                onChanged: (v) => state.setSetting(
                    'use24hClock', v, (x) => state.use24hClock = x)),
          ]),
          _SettingsSection('Вибро и звук', [
            _SettingsToggle(
                label: 'Вибрация',
                value: state.hapticsEnabled,
                onChanged: (v) => state.setSetting(
                    'hapticsEnabled', v, (x) => state.hapticsEnabled = x)),
            _SettingsToggle(
                label: 'Звуки',
                value: state.soundEnabled,
                onChanged: (v) => state.setSetting(
                    'soundEnabled', v, (x) => state.soundEnabled = x)),
          ]),
          _SettingsSection('Данные и синхронизация', [
            _SettingsToggle(
                label: 'Симулировать офлайн (QA)',
                value: state.offlineModeSimulated,
                onChanged: (v) {
                  state.setSetting('offlineModeSimulated', v,
                      (x) => state.offlineModeSimulated = x);
                  state.online = !v;
                  state.refresh();
                }),
            _SettingsRow(
                label: 'Ожидают отправки',
                value: '${state.pendingQueueCount} действий'),
            _SettingsRow(
                label: 'Сброс к демо-данным',
                trailing: const Icon(Icons.restart_alt, color: AppTheme.danger),
                onTap: () => _confirmResetToDemo(context, state)),
          ]),
          _SettingsSection('О приложении', [
            const _SettingsRow(label: 'Версия', value: 'v0.1.0-alpha'),
          ]),
        ],
      ),
    );
  }

  void _confirmResetToDemo(BuildContext context, CafeState state) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Сброс данных'),
        content: const Text(
            'Это удалит все текущие изменения и вернет демо-данные. Продолжить?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          TextButton(
              onPressed: () {
                state.resetToDemo();
                Navigator.pop(c);
              },
              child: const Text('Сбросить',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection(this.title, this.children);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 12, top: 24, bottom: 8),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink3))),
          AppCard(padding: EdgeInsets.zero, child: Column(children: children)),
        ],
      );
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsRow(
      {required this.label, this.value, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (value != null)
            Text(value!, style: const TextStyle(color: AppTheme.ink2)),
          if (trailing != null) trailing!,
        ]),
        onTap: onTap,
      );
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsToggle(
      {required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.cta,
      );
}

class _SettingsSegmented extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SettingsSegmented(
      {required this.label,
      required this.options,
      required this.selected,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceSunken,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                  children: List.generate(
                      options.length,
                      (i) => GestureDetector(
                            onTap: () => onChanged(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: selected == i
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: selected == i
                                      ? [
                                          const BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4)
                                        ]
                                      : null),
                              child: Text(options[i],
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected == i
                                          ? FontWeight.w600
                                          : FontWeight.w400)),
                            ),
                          ))),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.success.withValues(alpha: .3)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(sub, style: const TextStyle(color: AppTheme.ink2)),
          ],
        ),
      );
}
