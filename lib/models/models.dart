import 'package:hive_flutter/hive_flutter.dart';

part 'models.g.dart';

// ============================================================================
// ENUMERATIONS
// ============================================================================

/// User roles in the CafeConnect system
enum UserRole { waiter, cook, bartender, manager, admin }

/// Possible states of a cafe table
enum TableStatus { free, occupied, awaitingPayment, ready, late, newOrder }

/// Stages of an order's lifecycle
enum OrderStatus { accepted, cooking, ready, completed }

/// Kitchen or Bar station routing
enum Station { kitchen, bar }

/// Staff member roles
enum StaffRole { waiter, kitchen, bar, manager, admin }

/// Types of chat messages
enum MessageKind { text, tableCard, orderCard }

// ============================================================================
// HIVE MODELS (with @HiveType annotations)
// ============================================================================

/// Represents a menu item available at the cafe
@HiveType(typeId: 0)
class MenuItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String composition;

  @HiveField(4)
  Station station;

  @HiveField(5)
  bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.composition,
    required this.station,
    this.available = true,
  });

  MenuItem copy() => MenuItem(
        id: id,
        name: name,
        price: price,
        composition: composition,
        station: station,
        available: available,
      );
}

/// Represents a single line item in an order
@HiveType(typeId: 1)
class OrderItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int qty;

  @HiveField(2)
  double price;

  @HiveField(3)
  String note;

  @HiveField(4)
  Station station;

  @HiveField(5)
  bool ready;

  OrderItem({
    required this.name,
    required this.qty,
    required this.price,
    required this.note,
    required this.station,
    this.ready = false,
  });

  double get total => price * qty;

  OrderItem copy() => OrderItem(
        name: name,
        qty: qty,
        price: price,
        note: note,
        station: station,
        ready: ready,
      );
}

/// Represents a physical table in the cafe
@HiveType(typeId: 2)
class CafeTable extends HiveObject {
  @HiveField(0)
  int number;

  @HiveField(1)
  List<OrderItem> order;

  @HiveField(2)
  TableStatus status;

  @HiveField(3)
  String notes;

  @HiveField(4)
  String colorTag;

  @HiveField(5)
  String waiter;

  @HiveField(6)
  DateTime? openedAt;

  CafeTable({
    required this.number,
    this.order = const [],
    this.status = TableStatus.free,
    this.notes = '',
    this.colorTag = 'blue',
    this.waiter = '—',
    this.openedAt,
  });
}

/// Represents a station ticket (Kitchen or Bar)
@HiveType(typeId: 3)
class StationTicket extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int tableNumber;

  @HiveField(2)
  List<OrderItem> items;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? readyAt;

  @HiveField(5)
  Station station;

  @HiveField(6)
  bool markReady;

  StationTicket({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.createdAt,
    required this.station,
    this.readyAt,
    this.markReady = false,
  });

  bool get isLate {
    if (readyAt != null) return false;
    final elapsedMinutes = DateTime.now().difference(createdAt).inMinutes;
    return elapsedMinutes > 20;
  }

  int get elapsedMinutes => DateTime.now().difference(createdAt).inMinutes;
}

/// Represents a staff member
@HiveType(typeId: 4)
class StaffMember extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  StaffRole role;

  @HiveField(2)
  String status;

  StaffMember({
    required this.name,
    required this.role,
    required this.status,
  });
}

/// Represents a snapshot of a table state (for forwarded checks)
@HiveType(typeId: 5)
class TableSnapshot extends HiveObject {
  @HiveField(0)
  int number;

  @HiveField(1)
  List<OrderItem> items;

  @HiveField(2)
  double total;

  TableSnapshot({
    required this.number,
    required this.items,
    required this.total,
  });
}

/// Represents a chat group for staff communication
@HiveType(typeId: 6)
class ChatGroup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<String> members;

  ChatGroup({
    required this.id,
    required this.title,
    this.members = const [],
  });
}

/// Represents a single chat message
@HiveType(typeId: 7)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  MessageKind kind;

  @HiveField(2)
  bool own;

  @HiveField(3)
  String who;

  @HiveField(4)
  String text;

  @HiveField(5)
  String time;

  @HiveField(6)
  int? tableNumber;

  @HiveField(7)
  TableSnapshot? snapshot;

  ChatMessage({
    required this.id,
    required this.kind,
    required this.own,
    required this.who,
    required this.text,
    required this.time,
    this.tableNumber,
    this.snapshot,
  });
}

/// Represents app settings and user preferences
@HiveType(typeId: 8)
class Settings extends HiveObject {
  @HiveField(0)
  int themeModeIndex; // 0=system, 1=light, 2=dark

  @HiveField(1)
  bool soundEnabled;

  @HiveField(2)
  double textScaleFactor;

  @HiveField(3)
  int tablesPerRow; // 3 or 4

  @HiveField(4)
  bool gestureHints;

  @HiveField(5)
  String defaultOrderZone; // "New", "Ready", "All"

  @HiveField(6)
  String currencySymbol;

  @HiveField(7)
  bool currencyBefore; // true = "$100", false = "100$"

  @HiveField(8)
  bool use24hClock;

  @HiveField(9)
  bool hapticsEnabled;

  @HiveField(10)
  bool hapticsLongPress;

  @HiveField(11)
  bool hapticsStatus;

  @HiveField(12)
  int lateThreshold; // minutes

  @HiveField(13)
  bool showBanners;

  @HiveField(14)
  bool offlineMode;

  @HiveField(15)
  String? currentUser;

  Settings({
    this.themeModeIndex = 0,
    this.soundEnabled = false,
    this.textScaleFactor = 1.0,
    this.tablesPerRow = 3,
    this.gestureHints = true,
    this.defaultOrderZone = 'New',
    this.currencySymbol = '€',
    this.currencyBefore = false,
    this.use24hClock = true,
    this.hapticsEnabled = true,
    this.hapticsLongPress = true,
    this.hapticsStatus = true,
    this.lateThreshold = 20,
    this.showBanners = true,
    this.offlineMode = false,
    this.currentUser,
  });

  Settings copy() => Settings(
        themeModeIndex: themeModeIndex,
        soundEnabled: soundEnabled,
        textScaleFactor: textScaleFactor,
        tablesPerRow: tablesPerRow,
        gestureHints: gestureHints,
        defaultOrderZone: defaultOrderZone,
        currencySymbol: currencySymbol,
        currencyBefore: currencyBefore,
        use24hClock: use24hClock,
        hapticsEnabled: hapticsEnabled,
        hapticsLongPress: hapticsLongPress,
        hapticsStatus: hapticsStatus,
        lateThreshold: lateThreshold,
        showBanners: showBanners,
        offlineMode: offlineMode,
        currentUser: currentUser,
      );
}

/// Represents an action queued for offline sync
@HiveType(typeId: 9)
class OfflineQueueItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String action; // e.g., "addOrder", "updateTable", "sendMessage"

  @HiveField(2)
  String payload; // JSON-encoded action data

  @HiveField(3)
  DateTime timestamp;

  OfflineQueueItem({
    required this.id,
    required this.action,
    required this.payload,
    required this.timestamp,
  });
}
