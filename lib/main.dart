import 'dart:async';
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
import 'package:mobile_scanner/mobile_scanner.dart';
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
            initialLocation: '/login',
            routes: [
              GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
              GoRoute(path: '/qr', builder: (_, __) => const QrEntryScreen()),
              GoRoute(path: '/client', builder: (_, __) => const CustomerMenuScreen()),
              GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
              GoRoute(path: '/status', builder: (_, __) => const OrderStatusScreen()),
              GoRoute(path: '/tables', builder: (_, __) => const WaiterTableGridScreen()),
              GoRoute(path: '/waiter-menu', builder: (_, __) => const WaiterOrderScreen()),
              GoRoute(path: '/kitchen', builder: (_, __) => const OrderFeedScreen(feed: FeedType.kitchen)),
              GoRoute(path: '/bar', builder: (_, __) => const OrderFeedScreen(feed: FeedType.bar)),
              GoRoute(path: '/chats', builder: (_, __) => const StaffChatListScreen()),
              GoRoute(path: '/chat', builder: (_, __) => const StaffChatScreen()),
              GoRoute(path: '/manager', builder: (_, __) => const ManagerDashboardScreen()),
              GoRoute(path: '/team', builder: (_, __) => const TeamManagementScreen()),
              GoRoute(path: '/menu-admin', builder: (_, __) => const MenuManagementScreen()),
            ],
          );
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'CafeConnect',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

class AppTheme {
  static const bg = Color(0xFFF5F5F0);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF007AFF);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B30);
  static const separator = Color(0xFFE5E5EA);
  static const secondary = Color(0x993C3C43);
  static const darkBg = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: brightness),
      scaffoldBackgroundColor: isDark ? darkBg : bg,
      textTheme: GoogleFonts.interTextTheme(),
    );
    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      cardColor: isDark ? darkCard : card,
      dividerColor: isDark ? const Color(0xFF38383A) : separator,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0),
        titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0),
        titleMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0),
        labelSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0),
      ),
    );
  }
}

enum UserRole { client, waiter, cook, bartender, manager, smm }
enum TableStatus { free, newOrder, occupied, ready, late }
enum OrderStatus { accepted, cooking, ready, completed }
enum FeedType { kitchen, bar }
enum ButtonKind { primary, secondary, ghost, dark }

class AppUser {
  AppUser(this.id, this.name, this.role, this.login, this.password, this.status, {this.online = true});
  final String id;
  String name;
  UserRole role;
  String login;
  String password;
  String status;
  bool online;
}

class CafeTable {
  CafeTable(this.id, this.number, this.color, this.status, this.guestCount, {this.currentOrderId});
  final String id;
  final int number;
  Color color;
  TableStatus status;
  int guestCount;
  String? currentOrderId;
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
}

class CartLine {
  CartLine({required this.item, this.quantity = 1, this.modifiers = ''});
  final MenuItem item;
  int quantity;
  String modifiers;
  double get total => item.price * quantity;
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
}

class ChatGroup {
  ChatGroup(this.id, this.name, this.type, this.members, {this.pinned = false, this.muted = false});
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
}

class CafeState extends ChangeNotifier {
  final _api = MockCafeApi();
  final _box = Hive.box('cafeconnect');
  final List<AppUser> users = [];
  final List<CafeTable> tables = [];
  final List<MenuItem> menu = [];
  final List<CafeOrder> orders = [];
  final List<AppUser> staff = [];
  final List<ChatGroup> groups = [];
  final List<ChatMessage> messages = [];
  final Map<String, String> drafts = {};
  final Map<String, List<CartLine>> waiterCarts = {};
  final List<CafeOrder> offlineQueue = [];
  AppUser? currentUser;
  CafeTable? currentTable;
  ChatGroup? currentGroup;
  String selectedCategory = 'Все';
  String menuSearch = '';
  bool online = true;
  bool noConnectionDismissed = false;
  int heroIndex = 0;
  Timer? _retryTimer;
  Timer? _fakeRealtimeTimer;

  void refresh() => notifyListeners();

  Future<void> boot() async {
    users
      ..clear()
      ..addAll(_api.seedUsers());
    staff
      ..clear()
      ..addAll(users.where((u) => u.role != UserRole.client));
    tables
      ..clear()
      ..addAll(_api.seedTables());
    menu
      ..clear()
      ..addAll(_api.seedMenu());
    groups
      ..clear()
      ..addAll(_api.seedGroups(staff));
    messages
      ..clear()
      ..addAll(_api.seedMessages(groups));
    final cachedTable = _box.get('table') as int?;
    if (cachedTable != null) currentTable = tables.firstWhereOrNull((t) => t.number == cachedTable);
    _retryTimer = Timer.periodic(5.seconds, (_) => retryQueuedOrders());
    _fakeRealtimeTimer = Timer.periodic(12.seconds, (_) => simulateRealtimeOrder());
    notifyListeners();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _fakeRealtimeTimer?.cancel();
    super.dispose();
  }

  Future<bool> login(String login, String password) async {
    await Future.delayed(250.ms);
    final user = users.firstWhereOrNull((u) => u.login == login && u.password == password);
    if (user == null) {
      HapticFeedback.heavyImpact();
      return false;
    }
    currentUser = user;
    HapticFeedback.lightImpact();
    notifyListeners();
    return true;
  }

  String roleHome(UserRole role) {
    return switch (role) {
      UserRole.client => '/qr',
      UserRole.waiter => '/tables',
      UserRole.cook => '/kitchen',
      UserRole.bartender => '/bar',
      UserRole.manager || UserRole.smm => '/manager',
    };
  }

  bool validateTableCode(String code) {
    final number = int.tryParse(code);
    final table = tables.firstWhereOrNull((t) => t.number == number);
    if (table == null) {
      HapticFeedback.heavyImpact();
      return false;
    }
    currentTable = table;
    _box.put('table', table.number);
    HapticFeedback.lightImpact();
    notifyListeners();
    return true;
  }

  List<String> get categories => ['Все', ...menu.map((m) => m.category).toSet()];
  List<MenuItem> get promoItems => menu.where((m) => m.promo && m.available).take(5).toList();
  List<MenuItem> filteredMenu({String? category}) {
    final cat = category ?? selectedCategory;
    return menu.where((item) {
      final okCategory = cat == 'Все' || item.category == cat;
      final okSearch = menuSearch.isEmpty || item.name.toLowerCase().contains(menuSearch.toLowerCase());
      return item.available && okCategory && okSearch;
    }).toList();
  }

  List<CartLine> get cart => waiterCarts.putIfAbsent('client', () => []);
  List<CartLine> tableCart(String tableId) => waiterCarts.putIfAbsent(tableId, () => []);
  int get cartCount => cart.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => cart.fold(0.0, (sum, line) => sum + line.total);

  void addToCart(MenuItem item, int quantity, String modifiers, {String? tableId}) {
    final lines = tableId == null ? cart : tableCart(tableId);
    final existing = lines.firstWhereOrNull((line) => line.item.id == item.id && line.modifiers == modifiers);
    if (existing == null) {
      lines.add(CartLine(item: item, quantity: quantity, modifiers: modifiers));
    } else {
      existing.quantity = quantity;
      existing.modifiers = modifiers;
    }
    _box.put('cart_count', cartCount);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta) {
    line.quantity = max(1, line.quantity + delta);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void deleteLine(CartLine line, {String? tableId}) {
    (tableId == null ? cart : tableCart(tableId)).remove(line);
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Future<CafeOrder> submitOrder({String? tableId}) async {
    final table = tableId == null ? currentTable ?? tables[3] : tables.firstWhere((t) => t.id == tableId);
    final source = tableId == null ? cart : tableCart(table.id);
    final lines = source.map((l) => CartLine(item: l.item, quantity: l.quantity, modifiers: l.modifiers)).toList();
    final food = lines.where((l) => l.item.category != 'Напитки' && l.item.category != 'Кофе').toList();
    final drinks = lines.where((l) => l.item.category == 'Напитки' || l.item.category == 'Кофе').toList();
    CafeOrder last = _makeOrder(table, lines, FeedType.kitchen);
    if (!online) {
      offlineQueue.add(last);
    } else {
      if (food.isNotEmpty) orders.add(_makeOrder(table, food, FeedType.kitchen));
      if (drinks.isNotEmpty) orders.add(_makeOrder(table, drinks, FeedType.bar));
      last = orders.last;
    }
    table.status = TableStatus.newOrder;
    table.currentOrderId = last.id;
    source.clear();
    addSystemMessage(last);
    HapticFeedback.mediumImpact();
    notifyListeners();
    return last;
  }

  CafeOrder _makeOrder(CafeTable table, List<CartLine> lines, FeedType feed) {
    return CafeOrder(
      id: (1200 + orders.length + offlineQueue.length + 1).toString(),
      tableId: table.id,
      items: lines,
      status: OrderStatus.cooking,
      createdAt: DateTime.now().subtract(Duration(minutes: Random().nextInt(18))),
      splitTo: feed,
    );
  }

  void markReady(CafeOrder order) {
    order.status = OrderStatus.ready;
    final table = tables.firstWhereOrNull((t) => t.id == order.tableId);
    table?.status = TableStatus.ready;
    HapticFeedback.lightImpact();
    notifyListeners();
    Timer(900.ms, () {
      order.status = OrderStatus.completed;
      notifyListeners();
    });
  }

  void addSystemMessage(CafeOrder order) {
    final group = groups.firstWhereOrNull((g) => g.type == order.splitTo);
    if (group == null) return;
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: group.id,
      senderId: 'system',
      text: '#orders Новый заказ #${order.id}: ${order.items.map((e) => '${e.quantity}x ${e.item.name}').join(', ')}',
      tags: const ['#orders'],
      timestamp: DateTime.now(),
    ));
  }

  void callWaiter() {
    currentGroup = groups.firstWhere((g) => g.name == 'Общий чат');
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: currentGroup!.id,
      senderId: 'client',
      text: '#table Стол ${currentTable?.number.toString().padLeft(2, '0') ?? '04'} просит официанта',
      tags: const ['#table'],
      timestamp: DateTime.now(),
    ));
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void requestBill() {
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      groupId: groups.first.id,
      senderId: 'client',
      text: '#bill Стол ${currentTable?.number.toString().padLeft(2, '0') ?? '04'} просит счёт',
      tags: const ['#bill'],
      timestamp: DateTime.now(),
    ));
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void toggleOnline() {
    online = !online;
    noConnectionDismissed = false;
    notifyListeners();
  }

  void retryQueuedOrders() {
    if (!online || offlineQueue.isEmpty) return;
    orders.addAll(offlineQueue);
    offlineQueue.clear();
    notifyListeners();
  }

  void simulateRealtimeOrder() {
    if (!online || orders.length > 6) return;
    final table = tables[Random().nextInt(tables.length)];
    final item = menu[Random().nextInt(menu.length)];
    final order = _makeOrder(table, [CartLine(item: item, quantity: Random().nextInt(2) + 1)], item.category == 'Кофе' ? FeedType.bar : FeedType.kitchen);
    orders.add(order);
    table.status = TableStatus.newOrder;
    addSystemMessage(order);
    notifyListeners();
  }

  void toggleTableFilter(TableStatus? status) {
    if (status == null) return;
    notifyListeners();
  }

  void closeTable(CafeTable table) {
    table.status = TableStatus.free;
    table.currentOrderId = null;
    table.guestCount = 0;
    notifyListeners();
  }

  void addWalkIn() {
    final table = tables.firstWhereOrNull((t) => t.status == TableStatus.free) ?? tables.first;
    table.status = TableStatus.occupied;
    table.guestCount = max(1, table.guestCount);
    currentTable = table;
    notifyListeners();
  }

  void toggleAvailability(MenuItem item) {
    item.available = !item.available;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void saveMenuItem(MenuItem item, String name, String description, double price, String category, List<String> tags, int prepTime) {
    item
      ..name = name
      ..description = description
      ..price = price
      ..category = category
      ..tags = tags
      ..prepTime = prepTime;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void createStaff(String name, UserRole role, String login, String password) {
    final user = AppUser('u${users.length + 1}', name, role, login, password, 'Смена активна');
    users.add(user);
    staff.add(user);
    notifyListeners();
  }

  void deleteStaff(AppUser user) {
    staff.remove(user);
    users.remove(user);
    notifyListeners();
  }

  void createGroup(String name, List<AppUser> members) {
    groups.add(ChatGroup('g${groups.length + 1}', name, null, members.map((m) => m.id).toList()));
    notifyListeners();
  }

  void sendMessage(String text, {bool voice = false}) {
    if (currentGroup == null || text.trim().isEmpty) return;
    final tags = RegExp(r'#[\wа-яА-Я]+').allMatches(text).map((m) => m.group(0)!).toList();
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
    drafts[currentGroup!.id] = '';
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void react(ChatMessage message, String reaction) {
    message.reactions = [...message.reactions, reaction];
    notifyListeners();
  }
}

class MockCafeApi {
  List<AppUser> seedUsers() => [
        AppUser('client', 'Гость', UserRole.client, 'client', '1234', 'За столом'),
        AppUser('waiter', 'Елена Соколова', UserRole.waiter, 'waiter', '1234', 'Смена активна'),
        AppUser('cook', 'Марко Чен', UserRole.cook, 'cook', '1234', 'На кухне'),
        AppUser('bar', 'Сара Дженкинс', UserRole.bartender, 'bar', '1234', 'За баром'),
        AppUser('manager', 'Алекс Ривера', UserRole.manager, 'manager', '1234', 'Онлайн'),
      ];

  List<CafeTable> seedTables() => List.generate(12, (i) {
        final statuses = [TableStatus.free, TableStatus.occupied, TableStatus.newOrder, TableStatus.ready, TableStatus.late];
        final status = statuses[i % statuses.length];
        return CafeTable('t${i + 1}', i + 1, AppTheme.primary, status, status == TableStatus.free ? 0 : (i % 4) + 1);
      });

  List<MenuItem> seedMenu() => [
        MenuItem(id: 'm1', name: 'Флэт уайт', description: 'Шёлковый эспрессо с мягким молоком и плотной микропеной.', price: 4.50, category: 'Кофе', imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=900&q=80', tags: ['Dairy'], prepTime: 4, promo: true),
        MenuItem(id: 'm2', name: 'Круассан с маслом', description: 'Слоёный, тёплый, хрустящий круассан на французском масле.', price: 3.80, category: 'Выпечка', imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=900&q=80', tags: ['Gluten', 'Eggs'], prepTime: 3),
        MenuItem(id: 'm3', name: 'Трюфельный бенедикт', description: 'Яйца пашот, голландский соус и тонкая трюфельная нота.', price: 18.50, category: 'Завтраки', imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=900&q=80', tags: ['Eggs', 'Gluten'], prepTime: 14, promo: true),
        MenuItem(id: 'm4', name: 'Авокадо тост', description: 'Заквасочный хлеб, авокадо, лайм, зелень и хлопья чили.', price: 12.00, category: 'Завтраки', imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=900&q=80', tags: ['Vegan', 'Spicy'], prepTime: 8),
        MenuItem(id: 'm5', name: 'Колд брю', description: 'Освежающий кофе холодной экстракции с цитрусовым послевкусием.', price: 5.20, category: 'Кофе', imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80', tags: ['Vegan'], prepTime: 2, promo: true),
        MenuItem(id: 'm6', name: 'Лимонад базилик', description: 'Домашний лимонад с базиликом, лимоном и лёгкой газировкой.', price: 4.90, category: 'Напитки', imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?auto=format&fit=crop&w=900&q=80', tags: ['Vegan'], prepTime: 3),
        MenuItem(id: 'm7', name: 'Боул с лососем', description: 'Рис, лосось, огурец, авокадо, эдамаме и кунжутный соус.', price: 16.40, category: 'Кухня', imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80', tags: ['Dairy-free'], prepTime: 12),
        MenuItem(id: 'm8', name: 'Черничный маффин', description: 'Мягкий маффин с черникой и хрустящей сахарной шапкой.', price: 4.10, category: 'Выпечка', imageUrl: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=900&q=80', tags: ['Gluten', 'Eggs'], prepTime: 2),
      ];

  List<ChatGroup> seedGroups(List<AppUser> staff) => [
        ChatGroup('g1', 'Общий чат', null, staff.map((s) => s.id).toList(), pinned: true),
        ChatGroup('g2', 'Кухня', FeedType.kitchen, staff.where((s) => s.role != UserRole.bartender).map((s) => s.id).toList(), pinned: true),
        ChatGroup('g3', 'Бар', FeedType.bar, staff.where((s) => s.role != UserRole.cook).map((s) => s.id).toList()),
      ];

  List<ChatMessage> seedMessages(List<ChatGroup> groups) => [
        ChatMessage(id: 'm1', groupId: groups[0].id, senderId: 'waiter', text: '#orders Стол 04 сделал заказ, проверяю напитки.', tags: ['#orders'], timestamp: DateTime.now().subtract(22.minutes)),
        ChatMessage(id: 'm2', groupId: groups[1].id, senderId: 'cook', text: '#kitchen Бенедикт будет готов через минуту.', tags: ['#kitchen'], timestamp: DateTime.now().subtract(11.minutes)),
        ChatMessage(id: 'm3', groupId: groups[2].id, senderId: 'bar', text: '#ready Колд брю готов к выдаче.', tags: ['#ready'], timestamp: DateTime.now().subtract(4.minutes)),
      ];
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
      UserRole.client => 'Клиент',
      UserRole.waiter => 'Официант',
      UserRole.cook => 'Повар',
      UserRole.bartender => 'Бармен',
      UserRole.manager => 'Менеджер',
      UserRole.smm => 'SMM',
    };

Color statusColor(TableStatus status) => switch (status) {
      TableStatus.free => Colors.grey,
      TableStatus.newOrder => AppTheme.warning,
      TableStatus.occupied => AppTheme.primary,
      TableStatus.ready => AppTheme.success,
      TableStatus.late => AppTheme.danger,
    };

String statusLabel(TableStatus status) => switch (status) {
      TableStatus.free => 'Свободен',
      TableStatus.newOrder => 'Новый',
      TableStatus.occupied => 'Занят',
      TableStatus.ready => 'Готово',
      TableStatus.late => 'Поздно',
    };

class AppButton extends StatefulWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.icon, this.kind = ButtonKind.primary, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonKind kind;
  final bool loading;

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
    final bg = primary ? AppTheme.primary : dark ? Colors.black : ghost ? Colors.transparent : Colors.white;
    final fg = primary || dark ? Colors.white : AppTheme.primary;
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
        scale: down ? .96 : 1,
        child: AnimatedContainer(
          duration: 200.ms,
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ghost ? Colors.transparent : (primary || dark ? bg : AppTheme.primary)),
          ),
          child: widget.loading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: 19), const SizedBox(width: 8)],
                    Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 16))),
                  ],
                ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.index = 0, this.borderColor});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final int index;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Theme.of(context).dividerColor),
      ),
      child: child,
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 260.ms).slideY(begin: .08, end: 0);
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
  const StatusBadge(this.status, {super.key});
  final TableStatus status;

  @override
  Widget build(BuildContext context) {
    final dot = Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor(status), shape: BoxShape.circle));
    if (status == TableStatus.newOrder) return dot.animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(.8, .8), end: const Offset(1.6, 1.6), duration: 800.ms).fadeOut();
    if (status == TableStatus.late) return dot.animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: .2, end: 1, duration: 500.ms);
    if (status == TableStatus.ready) return dot.animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.45, 1.45), duration: 600.ms);
    return dot;
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 180.ms,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppTheme.primary : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) const Icon(Icons.check, color: Colors.white, size: 15),
            if (active) const SizedBox(width: 5),
            Text(label, style: TextStyle(color: active ? Colors.white : AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _step(Icons.remove, () => onChanged(max(1, value - 1))),
        SizedBox(width: 42, child: Center(child: Text('$value', style: Theme.of(context).textTheme.titleMedium))),
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
      child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppTheme.separator, shape: BoxShape.circle), child: Icon(icon, size: 18)),
    );
  }
}

class MenuImage extends StatelessWidget {
  const MenuImage(this.url, {super.key, this.radius = 16, this.aspectRatio = 1});
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
          errorWidget: (_, __, ___) => Container(color: AppTheme.separator, child: const Icon(Icons.local_cafe)),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(color: AppTheme.separator).animate(onPlay: (c) => c.repeat()).shimmer(duration: 900.ms, color: Colors.white70);
  }
}

class MenuGridItem extends StatelessWidget {
  const MenuGridItem({super.key, required this.item, required this.onTap, this.index = 0, this.trailing});
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
          Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(item.price.rub, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final login = TextEditingController(text: 'client');
  final password = TextEditingController(text: '1234');
  bool error = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 44),
          Text('CafeConnect', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          const Text('Тёплая автоматизация для любимого кафе', style: TextStyle(color: AppTheme.secondary)),
          const SizedBox(height: 34),
          AppCard(
            child: Column(
              children: [
                AppTextField(controller: login, label: 'Логин'),
                const SizedBox(height: 12),
                AppTextField(controller: password, label: 'Пароль', obscure: true),
                if (error) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Неверный логин или пароль', style: TextStyle(color: AppTheme.danger))),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Войти',
                  icon: Icons.login,
                  onPressed: () async {
                    final state = context.read<CafeState>();
                    final ok = await state.login(login.text.trim(), password.text.trim());
                    if (!mounted) return;
                    if (ok) context.go(state.roleHome(state.currentUser!.role)); else setState(() => error = true);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: ['client', 'waiter', 'cook', 'bar', 'manager'].map((name) => CategoryChip(label: name, active: login.text == name, onTap: () => setState(() => login.text = name))).toList()),
          const Spacer(),
          AppButton(label: 'Симулировать отсутствие сети', icon: Icons.wifi_off, kind: ButtonKind.secondary, onPressed: () => context.read<CafeState>().toggleOnline()),
        ],
      ),
    );
  }
}

class QrEntryScreen extends StatefulWidget {
  const QrEntryScreen({super.key});
  @override
  State<QrEntryScreen> createState() => _QrEntryScreenState();
}

class _QrEntryScreenState extends State<QrEntryScreen> {
  bool success = false;
  bool manual = false;
  String code = '';
  bool error = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: _ScannerBackdrop()),
          Center(
            child: AnimatedContainer(
              duration: 500.ms,
              width: success ? 420 : 200,
              height: success ? 420 : 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? AppTheme.success.withOpacity(.35) : Colors.transparent,
                border: Border.all(color: AppTheme.primary, width: 3),
              ),
              child: const _CornerMarkers(),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(.98, .98), end: const Offset(1.04, 1.04), duration: 900.ms),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Column(
              children: [
                if (manual) _ManualKeypad(code: code, error: error, onDigit: _digit, onClear: () => setState(() => code = '')),
                const SizedBox(height: 12),
                AppButton(label: manual ? 'Проверить стол' : 'Ввести код вручную', kind: ButtonKind.secondary, onPressed: manual ? _validate : () => setState(() => manual = true)),
                const SizedBox(height: 10),
                AppButton(label: 'Демо скан QR', icon: Icons.qr_code_scanner, onPressed: () => _finish('04')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _digit(String value) {
    if (code.length >= 6) return;
    setState(() => code += value);
  }

  void _validate() => _finish(code);

  void _finish(String value) {
    final ok = context.read<CafeState>().validateTableCode(value);
    if (!ok) {
      setState(() => error = true);
      return;
    }
    setState(() => success = true);
    Future.delayed(520.ms, () => mounted ? context.go('/client') : null);
  }
}

class _ScannerBackdrop extends StatelessWidget {
  const _ScannerBackdrop();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      MobileScanner(onDetect: (_) {}),
      Container(color: Colors.black.withOpacity(.55)),
    ]);
  }
}

class _CornerMarkers extends StatelessWidget {
  const _CornerMarkers();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornersPainter());
  }
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primary..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const l = 38.0;
    canvas.drawLine(Offset(16, 42), const Offset(16, 16), paint);
    canvas.drawLine(const Offset(16, 16), Offset(l, 16), paint);
    canvas.drawLine(Offset(size.width - 16, 42), Offset(size.width - 16, 16), paint);
    canvas.drawLine(Offset(size.width - 16, 16), Offset(size.width - l, 16), paint);
    canvas.drawLine(Offset(16, size.height - 42), Offset(16, size.height - 16), paint);
    canvas.drawLine(Offset(16, size.height - 16), Offset(l, size.height - 16), paint);
    canvas.drawLine(Offset(size.width - 16, size.height - 42), Offset(size.width - 16, size.height - 16), paint);
    canvas.drawLine(Offset(size.width - 16, size.height - 16), Offset(size.width - l, size.height - 16), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ManualKeypad extends StatelessWidget {
  const _ManualKeypad({required this.code, required this.error, required this.onDigit, required this.onClear});
  final String code;
  final bool error;
  final ValueChanged<String> onDigit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Text(code.padRight(4, '•'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: error ? AppTheme.danger : Colors.black)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          children: [...List.generate(9, (i) => '${i + 1}'), 'C', '0', '←'].map((d) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: AppButton(label: d, kind: ButtonKind.ghost, onPressed: d == 'C' ? onClear : d == '←' ? onClear : () => onDigit(d)),
            );
          }).toList(),
        ),
      ]),
    ).animate(target: error ? 1 : 0).shakeX(duration: 300.ms);
  }
}

class CustomerMenuScreen extends StatelessWidget {
  const CustomerMenuScreen({super.key});
  @override
  Widget build(BuildContext context) => MenuShell(clientMode: true, title: 'CafeConnect', tableBadge: context.watch<CafeState>().currentTable?.number ?? 4);
}

class WaiterOrderScreen extends StatelessWidget {
  const WaiterOrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final table = context.watch<CafeState>().currentTable ?? context.watch<CafeState>().tables.first;
    return MenuShell(clientMode: false, title: 'Стол ${table.number.toString().padLeft(2, '0')}', tableBadge: table.number);
  }
}

class MenuShell extends StatelessWidget {
  const MenuShell({super.key, required this.clientMode, required this.title, required this.tableBadge});
  final bool clientMode;
  final String title;
  final int tableBadge;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final tableId = clientMode ? null : state.currentTable?.id;
    final count = (clientMode ? state.cart : state.tableCart(tableId ?? 't1')).fold(0, (s, l) => s + l.quantity);
    return AppScaffold(
      bottomNav: clientMode ? null : const StaffBottomNav(current: '/tables'),
      floatingActionButton: count > 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () => clientMode ? context.push('/cart') : _showWaiterCart(context, tableId ?? 't1'),
              child: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                Positioned(right: -12, top: -12, child: CartBadge(count: count)),
              ]),
            )
          : null,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => Future.delayed(600.ms),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _MenuHeader(title: title, tableBadge: tableBadge, clientMode: clientMode)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: HeroCarousel(items: state.promoItems)),
          SliverPersistentHeader(pinned: true, delegate: _ChipHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 96),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = state.filteredMenu()[index];
                return MenuGridItem(item: item, index: index, onTap: () => showDishDetails(context, item, tableId: tableId));
              }, childCount: state.filteredMenu().length),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.title, required this.tableBadge, required this.clientMode});
  final String title;
  final int tableBadge;
  final bool clientMode;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineLarge)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: Text('СТОЛ ${tableBadge.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
      ]),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: TextField(
            onChanged: (v) {
              state.menuSearch = v;
              state.refresh();
            },
            decoration: InputDecoration(
              hintText: 'Поиск по меню',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(.82),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ChipHeader extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final state = context.watch<CafeState>();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: state.categories.map((c) => CategoryChip(label: c, active: state.selectedCategory == c, onTap: () {
          state.selectedCategory = c;
          state.refresh();
        })).toList(),
      ),
    );
  }

  @override
  double get maxExtent => 54;
  @override
  double get minExtent => 54;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.items});
  final List<MenuItem> items;
  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final controller = PageController();
  Timer? timer;
  int index = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(5.seconds, (_) {
      if (!mounted || widget.items.isEmpty) return;
      index = (index + 1) % widget.items.length;
      controller.animateToPage(index, duration: 400.ms, curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: MediaQuery.sizeOf(context).width * 9 / 16,
      child: Stack(children: [
        PageView.builder(
          controller: controller,
          onPageChanged: (v) => setState(() => index = v),
          itemCount: widget.items.length,
          itemBuilder: (context, i) {
            final item = widget.items[i];
            return GestureDetector(
              onTap: () => showDishDetails(context, item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(fit: StackFit.expand, children: [
                  MenuImage(item.imageUrl, radius: 32, aspectRatio: 16 / 9),
                  DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(.72)]))),
                  Positioned(left: 18, right: 18, bottom: 18, child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                    ])),
                    AppButton(label: 'Подробнее', kind: ButtonKind.secondary, onPressed: () => showDishDetails(context, item)),
                  ])),
                ]),
              ),
            );
          },
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (i) => AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.all(3),
                width: i == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(i == index ? 1 : .45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
        child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      ).animate(key: ValueKey(count)).scale(begin: const Offset(0, 0), end: const Offset(1.2, 1.2), duration: 240.ms).then().scale(end: const Offset(1, 1), duration: 160.ms);
}

Future<void> showDishDetails(BuildContext context, MenuItem item, {String? tableId}) async {
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
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.item.price * qty;
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .94,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(controller: scroll, padding: EdgeInsets.zero, children: [
          Stack(children: [
            MenuImage(widget.item.imageUrl, radius: 20, aspectRatio: 16 / 9),
            Positioned(right: 14, top: 14, child: CircleAvatar(backgroundColor: Colors.white.withOpacity(.9), child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)))),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge)),
                Text(widget.item.price.rub, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
              ]),
              const SizedBox(height: 10),
              Text(widget.item.description, maxLines: expanded ? null : 3, overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.secondary)),
              AppButton(label: expanded ? 'Свернуть' : 'Подробнее', kind: ButtonKind.ghost, onPressed: () => setState(() => expanded = !expanded)),
              Wrap(spacing: 8, runSpacing: 8, children: widget.item.tags.map((t) => _AllergenChip(t)).toList()),
              const SizedBox(height: 18),
              Row(children: [const Expanded(child: Text('Количество', style: TextStyle(fontWeight: FontWeight.w700))), QuantityStepper(value: qty, onChanged: (v) => setState(() => qty = v))]),
              const SizedBox(height: 16),
              AppTextField(controller: notes, label: 'Особые пожелания', hint: 'например, без лука, поострее'),
              const SizedBox(height: 18),
              AppButton(label: 'Добавить в заказ · ${total.rub}', icon: Icons.add_shopping_cart, onPressed: () {
                context.read<CafeState>().addToCart(widget.item, qty, notes.text.trim(), tableId: widget.tableId);
                Navigator.pop(context);
              }),
            ]),
          ),
        ]),
      ).animate().slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOutBack),
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = label == 'Vegan' ? AppTheme.success : label == 'Spicy' ? AppTheme.warning : AppTheme.separator;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: color.withOpacity(label == 'Vegan' || label == 'Spicy' ? .16 : 1), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: label == 'Vegan' ? AppTheme.success : label == 'Spicy' ? AppTheme.warning : Colors.black)));
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool sending = false;
  bool sent = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return AppScaffold(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)), Text('Корзина', style: Theme.of(context).textTheme.headlineLarge)]),
        Expanded(
          child: state.cart.isEmpty
              ? EmptyState(onBrowse: () => context.pop())
              : ListView(children: groupBy(state.cart, (CartLine l) => l.item.category).entries.expand((entry) => [
                    Padding(padding: const EdgeInsets.only(top: 18, bottom: 8), child: Text(entry.key, style: Theme.of(context).textTheme.titleLarge)),
                    ...entry.value.map((line) => CartLineTile(line: line)),
                  ]).toList()),
        ),
        BlurBar(child: Row(children: [
          Expanded(child: Text('Итого: ${state.subtotal.rub}', style: Theme.of(context).textTheme.titleMedium)),
          SizedBox(width: 150, child: AppButton(label: sent ? 'Отправлено' : sending ? '' : 'Заказать', loading: sending, icon: sent ? Icons.check : Icons.send, onPressed: state.cart.isEmpty ? null : _send)),
        ])),
      ]),
    );
  }

  Future<void> _send() async {
    setState(() => sending = true);
    await Future.delayed(800.ms);
    await context.read<CafeState>().submitOrder();
    if (!mounted) return;
    setState(() { sending = false; sent = true; });
    await Future.delayed(300.ms);
    if (mounted) context.go('/status');
  }
}

class CartLineTile extends StatelessWidget {
  const CartLineTile({super.key, required this.line, this.tableId});
  final CartLine line;
  final String? tableId;
  @override
  Widget build(BuildContext context) {
    final state = context.read<CafeState>();
    return Dismissible(
      key: ValueKey('${line.item.id}${line.modifiers}$tableId'),
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => state.deleteLine(line, tableId: tableId),
      child: AppCard(
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(line.item.name, style: Theme.of(context).textTheme.titleMedium),
            if (line.modifiers.isNotEmpty) Text(line.modifiers, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondary)),
            const SizedBox(height: 6),
            Text(line.total.rub, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ])),
          QuantityStepper(value: line.quantity, onChanged: (v) {
            line.quantity = v;
            state.refresh();
          }),
        ]),
      ),
    ).animate().slideX(begin: 0, end: 0, duration: 250.ms);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 120, height: 120, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.08), borderRadius: BorderRadius.circular(60)), child: const Icon(Icons.local_cafe, size: 64, color: AppTheme.primary)),
        const SizedBox(height: 14),
        Text('Корзина пуста', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Выберите что-нибудь уютное из меню', style: TextStyle(color: AppTheme.secondary)),
        const SizedBox(height: 16),
        AppButton(label: 'Вернуться к меню', kind: ButtonKind.secondary, onPressed: onBrowse),
      ]));
}

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final order = state.orders.lastWhereOrNull((o) => o.tableId == state.currentTable?.id) ?? state.orders.lastOrNull;
    final ready = order?.status == OrderStatus.ready || order?.status == OrderStatus.completed;
    return AppScaffold(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Заказ #${order?.id ?? '1284'}', style: Theme.of(context).textTheme.headlineLarge)),
          _Pill(ready ? 'Готово' : 'Готовится', ready ? AppTheme.success : AppTheme.warning),
        ]),
        const SizedBox(height: 4),
        Text('Стол ${(state.currentTable?.number ?? 4).toString().padLeft(2, '0')} · ${TimeOfDay.now().format(context)}', style: const TextStyle(color: AppTheme.secondary)),
        const SizedBox(height: 22),
        StepTracker(ready: ready),
        const SizedBox(height: 18),
        AppCard(child: Row(children: [const Icon(Icons.restaurant, color: AppTheme.warning), const SizedBox(width: 12), Expanded(child: Text(ready ? 'Ваш заказ ждёт выдачи' : 'Повар готовит ${order?.items.firstOrNull?.item.name ?? 'ваш заказ'}'))])),
        const SizedBox(height: 12),
        Expanded(child: ListView(children: (order?.items ?? []).map((line) => AppCard(index: 1, child: Row(children: [
          Expanded(child: Text(line.item.name, style: Theme.of(context).textTheme.titleMedium)),
          StatusBadge(ready ? TableStatus.ready : TableStatus.newOrder),
          const SizedBox(width: 8),
          Text(ready ? 'Готово' : 'Готовится'),
          const SizedBox(width: 8),
          Text(line.total.rub, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ]))).toList())),
        BlurBar(child: Row(children: [
          Expanded(child: AppButton(label: 'Позвать официанта', kind: ButtonKind.dark, onPressed: () {
            state.callWaiter();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Официант получил запрос')));
          })),
          const SizedBox(width: 10),
          Expanded(child: AppButton(label: 'Попросить счёт', onPressed: () {
            state.requestBill();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запрос счёта отправлен')));
          }).animate(target: ready ? 1 : 0).scale(end: const Offset(1.04, 1.04), duration: 600.ms)),
        ])),
      ]),
    );
  }
}

class StepTracker extends StatelessWidget {
  const StepTracker({super.key, required this.ready});
  final bool ready;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StepCircle(label: 'Принят', icon: Icons.check, done: true),
      const Expanded(child: Divider(color: AppTheme.success, thickness: 2)),
      _StepCircle(label: 'Готовится', icon: Icons.restaurant, done: false, active: !ready),
      Expanded(child: Divider(color: ready ? AppTheme.success : AppTheme.separator, thickness: 2)),
      _StepCircle(label: 'Готово', icon: Icons.check, done: ready),
    ]);
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.label, required this.icon, this.done = false, this.active = false});
  final String label;
  final IconData icon;
  final bool done;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = done ? AppTheme.success : active ? AppTheme.primary : Colors.grey;
    return Column(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: done ? color : Colors.transparent, border: Border.all(color: color, width: 3), shape: BoxShape.circle), child: Icon(icon, color: done ? Colors.white : color)).animate(onPlay: active ? (c) => c.repeat(reverse: true) : null).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 600.ms),
      const SizedBox(height: 6),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}

class WaiterTableGridScreen extends StatelessWidget {
  const WaiterTableGridScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/tables'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Header(title: 'Столы', subtitle: 'Этаж 1 · ${state.tables.where((t) => t.status != TableStatus.free).length} активных', actions: [
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поиск включён'))), icon: const Icon(Icons.search)),
          IconButton(onPressed: () => _showStatusFilter(context), icon: const Icon(Icons.filter_list)),
        ]),
        SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: TableStatus.values.map((s) => CategoryChip(label: statusLabel(s), active: false, onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Фильтр: ${statusLabel(s)}'))))).toList())),
        const SizedBox(height: 12),
        Expanded(child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: state.tables.length,
          itemBuilder: (_, i) {
            final table = state.tables[i];
            return GestureDetector(
              onLongPress: () => _showTableMenu(context, table),
              child: AppCard(
                index: i,
                onTap: () {
                  state.currentTable = table;
                  if (table.status == TableStatus.free) table.status = TableStatus.occupied;
                  context.push('/waiter-menu');
                },
                child: Stack(children: [
                  Positioned(right: 0, top: 0, child: StatusBadge(table.status)),
                  Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(table.number.toString().padLeft(2, '0'), style: Theme.of(context).textTheme.headlineLarge),
                    Text('${table.guestCount} гостей', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondary)),
                  ])),
                ]),
              ),
            );
          },
        )),
        BlurBar(child: Row(children: [
          Expanded(child: AppButton(label: 'Гость без QR', kind: ButtonKind.secondary, onPressed: state.addWalkIn)),
          const SizedBox(width: 10),
          Expanded(child: AppButton(label: 'Мои заказы', onPressed: () => context.push('/kitchen'))),
        ])),
      ]),
    );
  }
}

void _showStatusFilter(BuildContext context) => showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Wrap(spacing: 8, runSpacing: 8, children: TableStatus.values.map((s) => CategoryChip(label: statusLabel(s), active: false, onTap: () => Navigator.pop(context))).toList())));

void _showTableMenu(BuildContext context, CafeTable table) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => ClipRRect(
  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: Container(color: Colors.white.withOpacity(.9), padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
    AppButton(label: 'Детали стола ${table.number}', icon: Icons.info, onPressed: () => Navigator.pop(context)),
    const SizedBox(height: 10),
    AppButton(label: 'Закрыть стол', icon: Icons.close, kind: ButtonKind.secondary, onPressed: () { context.read<CafeState>().closeTable(table); Navigator.pop(context); }),
    const SizedBox(height: 10),
    AppButton(label: 'Сменить цвет', icon: Icons.palette, kind: ButtonKind.secondary, onPressed: () { table.color = Colors.primaries[Random().nextInt(Colors.primaries.length)]; context.read<CafeState>().refresh(); Navigator.pop(context); }),
  ]))),
));

void _showWaiterCart(BuildContext context, String tableId) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => WaiterCartSheet(tableId: tableId));

class WaiterCartSheet extends StatefulWidget {
  const WaiterCartSheet({super.key, required this.tableId});
  final String tableId;
  @override
  State<WaiterCartSheet> createState() => _WaiterCartSheetState();
}

class _WaiterCartSheetState extends State<WaiterCartSheet> {
  bool sent = false;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final lines = state.tableCart(widget.tableId);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Заказ стола', style: Theme.of(context).textTheme.headlineLarge),
          Expanded(child: ListView(controller: scroll, children: lines.map((l) => CartLineTile(line: l, tableId: widget.tableId)).toList())),
          AppButton(label: sent ? 'Отправлено' : 'Отправить на кухню', icon: sent ? Icons.check : Icons.send, onPressed: () async {
            await state.submitOrder(tableId: widget.tableId);
            setState(() => sent = true);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отправлено на кухню и в бар')));
            Future.delayed(400.ms, () => Navigator.pop(context));
          }),
        ]),
      ),
    );
  }
}

class OrderFeedScreen extends StatelessWidget {
  const OrderFeedScreen({super.key, required this.feed});
  final FeedType feed;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final active = state.orders.where((o) => o.splitTo == feed && o.status != OrderStatus.completed).toList();
    return AppScaffold(
      bottomNav: StaffBottomNav(current: feed == FeedType.kitchen ? '/kitchen' : '/bar'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Header(title: feed == FeedType.kitchen ? 'Кухня' : 'Бар', subtitle: '${active.length} активных заказов', actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.schedule)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ]),
        Expanded(child: ListView.builder(itemCount: active.length, itemBuilder: (_, i) => OrderCard(order: active[i], index: i))),
        BlurBar(child: Row(children: [
          const StatusBadge(TableStatus.ready),
          const SizedBox(width: 8),
          const Expanded(child: Text('Система онлайн')),
          AppButton(label: 'Открыть чат', kind: ButtonKind.secondary, onPressed: () {
            state.currentGroup = state.groups.firstWhere((g) => g.type == feed);
            context.push('/chat');
          }),
        ])),
      ]),
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
    final color = late ? AppTheme.danger : age.inMinutes > 15 ? AppTheme.warning : AppTheme.success;
    return AppCard(
      index: index,
      borderColor: late ? AppTheme.danger : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StatusBadge(table?.status ?? TableStatus.occupied),
          const SizedBox(width: 8),
          Expanded(child: Text('СТОЛ ${(table?.number ?? 0).toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.titleMedium)),
          _LiveTimer(createdAt: order.createdAt, color: color),
        ]),
        const Divider(height: 24),
        ...order.items.map((line) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${line.quantity}x ${line.item.name}${line.modifiers.isEmpty ? '' : '\n   ${line.modifiers}'}'))),
        const SizedBox(height: 8),
          AppButton(label: order.status == OrderStatus.ready ? 'Готово' : 'Отметить готовым', icon: Icons.check, onPressed: () => state.markReady(order)),
      ]),
    ).animate(onPlay: late ? (c) => c.repeat(reverse: true) : null).tint(color: late ? AppTheme.danger.withOpacity(.05) : Colors.transparent, duration: 500.ms);
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
  late Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(1.seconds, (_) => mounted ? setState(() {}) : null);
  }
  @override
  void dispose() { timer.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.createdAt);
    return Text('${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}', style: TextStyle(color: widget.color, fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 17));
  }
}

class StaffChatListScreen extends StatelessWidget {
  const StaffChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final groups = [...state.groups]..sort((a, b) => b.pinned.toString().compareTo(a.pinned.toString()));
    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/chats'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Header(title: 'Чаты', subtitle: 'Команда на связи'),
        Expanded(child: ListView.builder(itemCount: groups.length, itemBuilder: (_, i) {
          final group = groups[i];
          final last = state.messages.where((m) => m.groupId == group.id).lastOrNull;
          return Dismissible(
            key: ValueKey(group.id),
            background: Container(color: AppTheme.primary, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Text('Закрепить / Без звука / Удалить', style: TextStyle(color: Colors.white))),
            confirmDismiss: (_) async {
              group.pinned = !group.pinned;
              state.refresh();
              return false;
            },
            child: AppCard(
              index: i,
              onTap: () {
                state.currentGroup = group;
                context.push('/chat');
              },
              child: Row(children: [
                Avatar(label: group.name, online: true),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(group.name, style: Theme.of(context).textTheme.titleMedium)), if (group.pinned) const Icon(Icons.push_pin, size: 15)]),
                  Text(last?.text ?? 'Нет сообщений', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.secondary, fontSize: 13)),
                ])),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(last == null ? '' : TimeOfDay.fromDateTime(last.timestamp).format(context), style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 5),
                  const CartBadge(count: 2),
                ]),
              ]),
            ),
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
  String? tagFilter;
  bool recording = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    final group = state.currentGroup ?? state.groups.first;
    final all = state.messages.where((m) => m.groupId == group.id).toList();
    final messages = tagFilter == null ? all : all.where((m) => m.tags.contains(tagFilter)).toList();
    return AppScaffold(
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
          Avatar(label: group.name, online: true),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group.name, style: Theme.of(context).textTheme.titleMedium),
            const Text('8 участников онлайн', style: TextStyle(color: AppTheme.success, fontSize: 13)),
          ])),
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Информация о группе'))), icon: const Icon(Icons.info_outline)),
        ]),
        if (all.isNotEmpty) AppCard(padding: const EdgeInsets.all(10), child: Row(children: [const Icon(Icons.push_pin, size: 18), const SizedBox(width: 8), Expanded(child: Text(all.last.text, maxLines: 1, overflow: TextOverflow.ellipsis)), IconButton(onPressed: () => setState(() => tagFilter = null), icon: const Icon(Icons.close, size: 18))])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 12), itemCount: messages.length + 1, itemBuilder: (_, i) {
          if (i == messages.length) return const TypingDots();
          return ChatBubble(message: messages[i], onTag: (tag) => setState(() => tagFilter = tag), onReact: (emoji) => state.react(messages[i], emoji));
        })),
        Row(children: [
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вложение добавлено в черновик'))), icon: const Icon(Icons.add_circle_outline)),
          Expanded(child: AppTextField(controller: input, label: 'Сообщение...', onChanged: (_) => setState(() {}))),
          GestureDetector(
            onLongPressStart: (_) => setState(() => recording = true),
            onLongPressEnd: (_) {
              setState(() => recording = false);
              state.sendMessage('#голос Голосовое сообщение', voice: true);
            },
            child: Icon(Icons.mic, color: recording ? AppTheme.danger : AppTheme.secondary),
          ),
          IconButton(
            onPressed: input.text.trim().isEmpty ? null : () {
              state.sendMessage(input.text.trim());
              input.clear();
              setState(() {});
            },
            icon: const CircleAvatar(backgroundColor: AppTheme.primary, child: Icon(Icons.arrow_upward, color: Colors.white)),
          ),
        ]).animate(target: recording ? 1 : 0).shakeX(),
      ]),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.onTag, required this.onReact});
  final ChatMessage message;
  final ValueChanged<String> onTag;
  final ValueChanged<String> onReact;
  @override
  Widget build(BuildContext context) {
    final own = message.own;
    final bg = own ? AppTheme.primary : AppTheme.separator;
    final fg = own ? Colors.white : Colors.black;
    return GestureDetector(
      onLongPress: () => showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Wrap(spacing: 8, children: ['OK', 'Иду', 'Минуту', '❤️'].map((r) => AppButton(label: r, kind: ButtonKind.secondary, onPressed: () { onReact(r); Navigator.pop(context); })).toList()))),
      child: Align(
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (message.voice) const _Waveform(),
            Wrap(children: message.text.split(' ').map((part) => part.startsWith('#') ? GestureDetector(onTap: () => onTag(part), child: Text('$part ', style: TextStyle(color: own ? Colors.white : AppTheme.primary, fontWeight: FontWeight.w700))) : Text('$part ', style: TextStyle(color: fg))).toList()),
            const SizedBox(height: 4),
            Text(TimeOfDay.fromDateTime(message.timestamp).format(context), style: TextStyle(color: own ? Colors.white70 : AppTheme.secondary, fontSize: 13)),
            if (message.reactions.isNotEmpty) Text(message.reactions.join(' ')),
          ]),
        ),
      ),
    );
  }
}

class TypingDots extends StatelessWidget {
  const TypingDots({super.key});
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) => Container(width: 7, height: 7, margin: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle)).animate(delay: Duration(milliseconds: i * 150), onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(.5, .5), end: const Offset(1, 1), duration: 450.ms)));
}

class _Waveform extends StatefulWidget {
  const _Waveform();
  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> {
  double speed = 1;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => speed = speed == 1 ? 1.5 : speed == 1.5 ? 2 : 1),
    child: Row(children: [
      const Icon(Icons.play_arrow, size: 18),
      ...List.generate(16, (i) => Container(width: 3, height: 8 + (i % 5) * 4, margin: const EdgeInsets.symmetric(horizontal: 1), color: AppTheme.primary.withOpacity(.7))),
      const SizedBox(width: 8),
      Text('${speed}x'),
    ]),
  );
}

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return AppScaffold(
      bottomNav: const StaffBottomNav(current: '/manager'),
      child: ListView(children: [
        Header(title: 'CafeConnect', subtitle: 'Панель менеджера', actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings))]),
        SectionTitle('Команда', action: () => context.push('/team')),
        ...state.staff.take(4).map((u) => StaffMemberRow(user: u)),
        SectionTitle('Меню', action: () => context.push('/menu-admin')),
        GridView.count(crossAxisCount: 2, childAspectRatio: .75, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: state.menu.take(4).mapIndexed((i, item) => MenuGridItem(item: item, index: i, onTap: () => context.push('/menu-admin'))).toList()),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          AppButton(label: 'Создать группу', kind: ButtonKind.secondary, onPressed: () => context.push('/team')),
          AppButton(label: 'Добавить сотрудника', kind: ButtonKind.secondary, onPressed: () => context.push('/team')),
          AppButton(label: 'Редактировать меню', onPressed: () => context.push('/menu-admin')),
        ]),
      ]),
    );
  }
}

class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return AppScaffold(
      child: ListView(children: [
        Header(title: 'Управление', subtitle: 'Сотрудники и права', actions: [IconButton(onPressed: () => _showStaffForm(context), icon: const Icon(Icons.add))]),
        ...state.staff.map((u) => StaffMemberRow(user: u)),
        AppCard(onTap: () => _showStaffForm(context), child: const Center(child: Padding(padding: EdgeInsets.all(14), child: Text('Добавить сотрудника', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))))),
        const SectionTitle('Группы связи'),
        AppCard(onTap: () => _showGroupForm(context), child: Row(children: [const Icon(Icons.groups, color: AppTheme.primary), const SizedBox(width: 10), const Expanded(child: Text('Создать новую группу')), const Icon(Icons.chevron_right)])),
        ...state.groups.map((g) => AppCard(child: Row(children: [Avatar(label: g.name), const SizedBox(width: 10), Expanded(child: Text(g.name)), Text('${g.members.length} чел.', style: const TextStyle(color: AppTheme.secondary))]))),
      ]),
    );
  }
}

class StaffMemberRow extends StatelessWidget {
  const StaffMemberRow({super.key, required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role) { UserRole.manager => const Color(0xFFBF5AF2), UserRole.waiter => AppTheme.primary, UserRole.cook => AppTheme.warning, UserRole.bartender => AppTheme.success, UserRole.smm => const Color(0xFFFF2D55), UserRole.client => Colors.grey };
    return Dismissible(
      key: ValueKey(user.id),
      background: Container(alignment: Alignment.centerRight, color: AppTheme.danger, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (_) async {
        context.read<CafeState>().deleteStaff(user);
        return false;
      },
      child: AppCard(
        onTap: () => _showStaffForm(context, user: user),
        child: Row(children: [
          Avatar(label: user.name, online: user.online),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: Theme.of(context).textTheme.titleMedium),
            Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle)), const SizedBox(width: 6), Text(roleLabel(user.role), style: const TextStyle(color: AppTheme.secondary))]),
          ])),
          Text(user.status, style: TextStyle(color: user.online ? AppTheme.success : AppTheme.secondary, fontSize: 13)),
        ]),
      ),
    );
  }
}

void _showStaffForm(BuildContext context, {AppUser? user}) {
  final name = TextEditingController(text: user?.name ?? '');
  final login = TextEditingController(text: user?.login ?? '');
  final password = TextEditingController(text: user?.password ?? '');
  var role = user?.role ?? UserRole.waiter;
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (context, set) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(user == null ? 'Новый сотрудник' : 'Редактировать', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      AppTextField(controller: name, label: 'Имя'),
      const SizedBox(height: 10),
      DropdownButtonFormField(value: role, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Роль'), items: UserRole.values.where((r) => r != UserRole.client).map((r) => DropdownMenuItem(value: r, child: Text(roleLabel(r)))).toList(), onChanged: (v) => set(() => role = v!)),
      const SizedBox(height: 10),
      AppTextField(controller: login, label: 'Логин'),
      const SizedBox(height: 10),
      AppTextField(controller: password, label: 'Пароль', obscure: true),
      const SizedBox(height: 14),
      AppButton(label: 'Создать', onPressed: () {
        context.read<CafeState>().createStaff(name.text, role, login.text, password.text);
        Navigator.pop(context);
      }),
    ]),
  )));
}

void _showGroupForm(BuildContext context) {
  final name = TextEditingController();
  final selected = <AppUser>{};
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (context, set) {
    final state = context.watch<CafeState>();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Новая группа', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AppTextField(controller: name, label: 'Название'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.staff
              .map((u) => CategoryChip(
                    label: u.name.split(' ').first,
                    active: selected.contains(u),
                    onTap: () => set(() {
                      if (selected.contains(u)) {
                        selected.remove(u);
                      } else {
                        selected.add(u);
                      }
                    }),
                  ))
              .toList(),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Создать группу',
          onPressed: () {
            state.createGroup(name.text, selected.toList());
            Navigator.pop(context);
          },
        ),
      ]),
    );
  }));
}

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CafeState>();
    return AppScaffold(
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Header(title: 'Меню', subtitle: 'Доступность позиций', actions: [AppButton(label: 'Редактировать', kind: ButtonKind.secondary, onPressed: () => _showMenuEditor(context, state.menu.first))])),
        SliverToBoxAdapter(child: SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: state.categories.skip(1).map((c) => CategoryChip(label: c, active: state.selectedCategory == c, onTap: () { state.selectedCategory = c; state.refresh(); })).toList()))),
        SliverPadding(
          padding: const EdgeInsets.only(top: 14, bottom: 18),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .62),
            delegate: SliverChildBuilderDelegate((context, i) {
              final item = state.filteredMenu(category: state.selectedCategory == 'Все' ? null : state.selectedCategory)[i];
              return MenuGridItem(item: item, index: i, onTap: () => _showMenuEditor(context, item), trailing: CupertinoSwitch(value: item.available, activeColor: AppTheme.success, onChanged: (_) => state.toggleAvailability(item)));
            }, childCount: state.filteredMenu(category: state.selectedCategory == 'Все' ? null : state.selectedCategory).length),
          ),
        ),
        SliverToBoxAdapter(child: const SectionTitle('Hero Banner')),
        SliverToBoxAdapter(child: Column(children: state.promoItems.map((p) => AppCard(child: Row(children: [const Icon(Icons.drag_handle), const SizedBox(width: 8), Expanded(child: Text(p.name)), CupertinoSwitch(value: p.promo, activeColor: AppTheme.success, onChanged: (_) { p.promo = !p.promo; state.refresh(); })]))).toList())),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 10, bottom: 40), child: AppButton(label: 'Добавить промо', kind: ButtonKind.secondary, onPressed: () { state.menu.first.promo = true; state.refresh(); }))),
      ]),
    );
  }
}

void _showMenuEditor(BuildContext context, MenuItem item) {
  final name = TextEditingController(text: item.name);
  final description = TextEditingController(text: item.description);
  final price = TextEditingController(text: item.price.toStringAsFixed(2));
  final prep = TextEditingController(text: '${item.prepTime}');
  var category = item.category;
  final tags = item.tags.toSet();
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (context, set) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
    child: ListView(shrinkWrap: true, children: [
      MenuImage(item.imageUrl, radius: 16, aspectRatio: 16 / 9),
      const SizedBox(height: 12),
      AppButton(label: 'Заменить фото', kind: ButtonKind.secondary, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото обновлено')))),
      const SizedBox(height: 12),
      AppTextField(controller: name, label: 'Название'),
      const SizedBox(height: 10),
      AppTextField(controller: description, label: 'Описание'),
      const SizedBox(height: 10),
      AppTextField(controller: price, label: 'Цена', keyboardType: TextInputType.number),
      const SizedBox(height: 10),
      DropdownButtonFormField(value: category, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Категория'), items: ['Кофе', 'Выпечка', 'Завтраки', 'Кухня', 'Напитки', 'Сезонное'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => set(() => category = v!)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ['Vegan', 'Spicy', 'Gluten-free', 'Dairy', 'Eggs']
            .map((t) => CategoryChip(
                  label: t,
                  active: tags.contains(t),
                  onTap: () => set(() {
                    if (tags.contains(t)) {
                      tags.remove(t);
                    } else {
                      tags.add(t);
                    }
                  }),
                ))
            .toList(),
      ),
      const SizedBox(height: 10),
      AppTextField(controller: prep, label: 'Время приготовления, мин', keyboardType: TextInputType.number),
      const SizedBox(height: 14),
      AppButton(label: 'Сохранить', onPressed: () {
        context.read<CafeState>().saveMenuItem(item, name.text, description.text, double.tryParse(price.text) ?? item.price, category, tags.toList(), int.tryParse(prep.text) ?? item.prepTime);
        Navigator.pop(context);
      }),
    ]),
  )));
}

class Header extends StatelessWidget {
  const Header({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 16), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      if (subtitle != null) Text(subtitle!, style: const TextStyle(color: AppTheme.secondary)),
    ])),
    ...actions,
  ]));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
    if (action != null) AppButton(label: 'Все', kind: ButtonKind.ghost, onPressed: action),
  ]));
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.label, this.online = false});
  final String label;
  final bool online;
  @override
  Widget build(BuildContext context) {
    final initials = label
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1).toUpperCase())
        .take(2)
        .join();
    return Stack(clipBehavior: Clip.none, children: [
      CircleAvatar(radius: 24, backgroundColor: AppTheme.primary.withOpacity(.16), child: Text(initials, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800))),
      if (online) Positioned(right: -1, bottom: -1, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
    ]);
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.controller, required this.label, this.hint, this.obscure = false, this.keyboardType, this.onChanged});
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
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.separator)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.separator)),
      contentPadding: const EdgeInsets.all(16),
    ),
  );
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child, this.bottomNav, this.floatingActionButton});
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(children: [
            if (!state.online && !state.noConnectionDismissed) Container(
              margin: const EdgeInsets.only(top: 6, bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Expanded(child: Text('Нет соединения. Заказы сохраняются локально.', style: TextStyle(color: Colors.white))),
                IconButton(onPressed: () { state.noConnectionDismissed = true; state.refresh(); }, icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Expanded(child: child),
          ]),
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
      ('Домой', Icons.home, '/manager'),
      ('Столы', Icons.table_bar, '/tables'),
      ('Чаты', Icons.chat_bubble, '/chats'),
      ('Профиль', Icons.person, '/login'),
    ];
    return NavigationBar(
      selectedIndex: max(0, items.indexWhere((e) => e.$3 == current)),
      onDestinationSelected: (i) => context.go(items[i].$3),
      destinations: items.map((e) => NavigationDestination(icon: Icon(e.$2, color: e.$3 == current ? AppTheme.primary : Colors.grey), label: e.$3 == current ? e.$1 : '')).toList(),
    );
  }
}

class BlurBar extends StatelessWidget {
  const BlurBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(.82), border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(20)), child: child)),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)));
}
