import 'package:flutter/material.dart';

enum UserRole { waiter, cook, bartender, manager, admin }

enum TableStatus { free, occupied, awaitingPayment, ready, late, newOrder }

enum OrderStatus { accepted, cooking, ready, completed }

enum FeedType { kitchen, bar }

enum MessageKind { text, tableCard, orderCard }

enum AttentionType { arrived, callWaiter, billRequest }

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.status = '',
    this.online = true,
  });

  final String id;
  final String name;
  final UserRole role;
  final String status;
  final bool online;

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? status,
    bool? online,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        status: status ?? this.status,
        online: online ?? this.online,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.index,
        'status': status,
        'online': online,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'],
        role: UserRole.values[j['role'] as int],
        status: j['status'] ?? '',
        online: j['online'] ?? true,
      );
}

@immutable
class CafeTable {
  const CafeTable({
    required this.id,
    required this.number,
    this.name = '',
    this.seats = 4,
    this.guestCount = 0,
    this.status = TableStatus.free,
    this.colorTag = Colors.grey,
    this.attention,
    this.attentionReason,
    this.ack = false,
    this.waiter,
    this.openedAt,
    this.notes = const [],
    this.currentOrderId,
  });

  final String id;
  final String number;
  final String name;
  final int seats;
  final int guestCount;
  final TableStatus status;
  final Color colorTag;
  final AttentionType? attention;
  final String? attentionReason;
  final bool ack;
  final String? waiter;
  final DateTime? openedAt;
  final List<String> notes;
  final String? currentOrderId;

  CafeTable copyWith({
    String? name,
    int? seats,
    int? guestCount,
    TableStatus? status,
    Color? colorTag,
    AttentionType? attention,
    String? attentionReason,
    bool? ack,
    String? waiter,
    DateTime? openedAt,
    List<String>? notes,
    String? currentOrderId,
    bool clearAttention = false,
  }) =>
      CafeTable(
        id: id,
        number: number,
        name: name ?? this.name,
        seats: seats ?? this.seats,
        guestCount: guestCount ?? this.guestCount,
        status: status ?? this.status,
        colorTag: colorTag ?? this.colorTag,
        attention: clearAttention ? null : (attention ?? this.attention),
        attentionReason: clearAttention ? null : (attentionReason ?? this.attentionReason),
        ack: clearAttention ? false : (ack ?? this.ack),
        waiter: waiter ?? this.waiter,
        openedAt: openedAt ?? this.openedAt,
        notes: notes ?? this.notes,
        currentOrderId: currentOrderId ?? this.currentOrderId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'seats': seats,
        'guestCount': guestCount,
        'status': status.index,
        'colorTagValue': colorTag.toARGB32(),
        'attention': attention?.index,
        'attentionReason': attentionReason,
        'ack': ack,
        'waiter': waiter,
        'openedAt': openedAt?.millisecondsSinceEpoch,
        'notes': notes,
        'currentOrderId': currentOrderId,
      };

  factory CafeTable.fromJson(Map<String, dynamic> j) => CafeTable(
        id: j['id'],
        number: j['number'].toString(),
        name: j['name'] ?? '',
        seats: j['seats'] ?? 4,
        guestCount: j['guestCount'] ?? 0,
        status: TableStatus.values[j['status'] as int],
        colorTag: Color(j['colorTagValue'] as int),
        attention: j['attention'] != null ? AttentionType.values[j['attention'] as int] : null,
        attentionReason: j['attentionReason'],
        ack: j['ack'] ?? false,
        waiter: j['waiter'],
        openedAt: j['openedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(j['openedAt'] as int) : null,
        notes: List<String>.from(j['notes'] ?? []),
        currentOrderId: j['currentOrderId'],
      );
}

@immutable
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.tags = const [],
    this.prepTime = 15,
    this.available = true,
    this.promo = false,
    this.composition = '',
    this.allergens = const [],
    this.station = FeedType.kitchen,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final List<String> tags;
  final int prepTime;
  final bool available;
  final bool promo;
  final String composition;
  final List<String> allergens;
  final FeedType station;

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    List<String>? tags,
    int? prepTime,
    bool? available,
    bool? promo,
    String? composition,
    List<String>? allergens,
    FeedType? station,
  }) =>
      MenuItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        tags: tags ?? this.tags,
        prepTime: prepTime ?? this.prepTime,
        available: available ?? this.available,
        promo: promo ?? this.promo,
        composition: composition ?? this.composition,
        allergens: allergens ?? this.allergens,
        station: station ?? this.station,
      );

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
        'station': station.index,
      };

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'],
        name: j['name'],
        description: j['description'] ?? '',
        price: (j['price'] as num).toDouble(),
        category: j['category'],
        imageUrl: j['imageUrl'] ?? '',
        tags: List<String>.from(j['tags'] ?? []),
        prepTime: j['prepTime'] ?? 15,
        available: j['available'] ?? true,
        promo: j['promo'] ?? false,
        composition: j['composition'] ?? '',
        allergens: List<String>.from(j['allergens'] ?? []),
        station: FeedType.values[j['station'] as int? ?? 0],
      );
}

@immutable
class CartLine {
  const CartLine({
    required this.id,
    required this.item,
    this.quantity = 1,
    this.notes = const [],
    this.ready = false,
    this.done = false,
    required this.lockedPrice,
  });

  final String id;
  final MenuItem item;
  final int quantity;
  final List<String> notes;
  final bool ready;
  final bool done;
  final double lockedPrice;

  double get total => lockedPrice * quantity;

  CartLine copyWith({
    int? quantity,
    List<String>? notes,
    bool? ready,
    bool? done,
  }) =>
      CartLine(
        id: id,
        item: item,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        ready: ready ?? this.ready,
        done: done ?? this.done,
        lockedPrice: lockedPrice,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': item.id,
        'quantity': quantity,
        'notes': notes,
        'ready': ready,
        'done': done,
        'lockedPrice': lockedPrice,
      };

  factory CartLine.fromJson(Map<String, dynamic> j, List<MenuItem> menu) {
    final item = menu.firstWhere((m) => m.id == j['itemId']);
    return CartLine(
      id: j['id'],
      item: item,
      quantity: j['quantity'],
      notes: List<String>.from(j['notes'] ?? []),
      ready: j['ready'] ?? false,
      done: j['done'] ?? false,
      lockedPrice: (j['lockedPrice'] as num).toDouble(),
    );
  }
}

@immutable
class CafeOrder {
  const CafeOrder({
    required this.id,
    required this.tableId,
    required this.items,
    this.status = OrderStatus.accepted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tableId;
  final List<CartLine> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get total => items.fold(0, (sum, item) => sum + item.total);

  CafeOrder copyWith({
    List<CartLine>? items,
    OrderStatus? status,
    DateTime? updatedAt,
  }) =>
      CafeOrder(
        id: id,
        tableId: tableId,
        items: items ?? this.items,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.index,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory CafeOrder.fromJson(Map<String, dynamic> j, List<MenuItem> menu) => CafeOrder(
        id: j['id'],
        tableId: j['tableId'],
        items: (j['items'] as List).map((i) => CartLine.fromJson(i, menu)).toList(),
        status: OrderStatus.values[j['status'] as int],
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
      );
}

@immutable
class AttentionSignal {
  const AttentionSignal({
    required this.tableId,
    required this.type,
    this.reason,
    required this.createdAt,
  });

  final String tableId;
  final AttentionType type;
  final String? reason;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'type': type.index,
        'reason': reason,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

@immutable
class AppPrefs {
  const AppPrefs({
    this.soundArrival = true,
    this.soundCall = true,
    this.soundBill = true,
    this.haptics = true,
    this.volume = 0.6,
    this.sortUndelivered = true,
    this.showReady = true,
    this.confirmClear = true,
    this.theme = 'system',
    this.textSize = 'M',
    this.highContrast = false,
  });

  final bool soundArrival;
  final bool soundCall;
  final bool soundBill;
  final bool haptics;
  final double volume;
  final bool sortUndelivered;
  final bool showReady;
  final bool confirmClear;
  final String theme;
  final String textSize;
  final bool highContrast;

  AppPrefs copyWith({
    bool? soundArrival,
    bool? soundCall,
    bool? soundBill,
    bool? haptics,
    double? volume,
    bool? sortUndelivered,
    bool? showReady,
    bool? confirmClear,
    String? theme,
    String? textSize,
    bool? highContrast,
  }) =>
      AppPrefs(
        soundArrival: soundArrival ?? this.soundArrival,
        soundCall: soundCall ?? this.soundCall,
        soundBill: soundBill ?? this.soundBill,
        haptics: haptics ?? this.haptics,
        volume: volume ?? this.volume,
        sortUndelivered: sortUndelivered ?? this.sortUndelivered,
        showReady: showReady ?? this.showReady,
        confirmClear: confirmClear ?? this.confirmClear,
        theme: theme ?? this.theme,
        textSize: textSize ?? this.textSize,
        highContrast: highContrast ?? this.highContrast,
      );

  Map<String, dynamic> toJson() => {
        'soundArrival': soundArrival,
        'soundCall': soundCall,
        'soundBill': soundBill,
        'haptics': haptics,
        'volume': volume,
        'sortUndelivered': sortUndelivered,
        'showReady': showReady,
        'confirmClear': confirmClear,
        'theme': theme,
        'textSize': textSize,
        'highContrast': highContrast,
      };

  factory AppPrefs.fromJson(Map<String, dynamic> j) => AppPrefs(
        soundArrival: j['soundArrival'] ?? true,
        soundCall: j['soundCall'] ?? true,
        soundBill: j['soundBill'] ?? true,
        haptics: j['haptics'] ?? true,
        volume: (j['volume'] as num?)?.toDouble() ?? 0.6,
        sortUndelivered: j['sortUndelivered'] ?? true,
        showReady: j['showReady'] ?? true,
        confirmClear: j['confirmClear'] ?? true,
        theme: j['theme'] ?? 'system',
        textSize: j['textSize'] ?? 'M',
        highContrast: j['highContrast'] ?? false,
      );
}

@immutable
class ChatGroup {
  const ChatGroup({
    required this.id,
    required this.name,
    this.type,
    this.members = const [],
    this.pinned = false,
    this.muted = false,
  });

  final String id;
  final String name;
  final FeedType? type;
  final List<String> members;
  final bool pinned;
  final bool muted;

  ChatGroup copyWith({
    String? name,
    FeedType? type,
    List<String>? members,
    bool? pinned,
    bool? muted,
  }) =>
      ChatGroup(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        members: members ?? this.members,
        pinned: pinned ?? this.pinned,
        muted: muted ?? this.muted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type?.index,
        'members': members,
        'pinned': pinned,
        'muted': muted,
      };

  factory ChatGroup.fromJson(Map<String, dynamic> j) => ChatGroup(
        id: j['id'],
        name: j['name'],
        type: j['type'] != null ? FeedType.values[j['type'] as int] : null,
        members: List<String>.from(j['members'] ?? []),
        pinned: j['pinned'] ?? false,
        muted: j['muted'] ?? false,
      );
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    this.tags = const [],
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
  final List<String> reactions;
  final MessageKind kind;
  final String? refId;

  ChatMessage copyWith({
    String? text,
    List<String>? tags,
    List<String>? reactions,
  }) =>
      ChatMessage(
        id: id,
        groupId: groupId,
        senderId: senderId,
        text: text ?? this.text,
        tags: tags ?? this.tags,
        timestamp: timestamp,
        own: own,
        voice: voice,
        reactions: reactions ?? this.reactions,
        kind: kind,
        refId: refId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'senderId': senderId,
        'text': text,
        'tags': tags,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'own': own,
        'voice': voice,
        'reactions': reactions,
        'kind': kind.index,
        'refId': refId,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        groupId: j['groupId'],
        senderId: j['senderId'],
        text: j['text'],
        tags: List<String>.from(j['tags'] ?? []),
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
        own: j['own'] ?? false,
        voice: j['voice'] ?? false,
        reactions: List<String>.from(j['reactions'] ?? []),
        kind: MessageKind.values[j['kind'] as int],
        refId: j['refId'],
      );
}
