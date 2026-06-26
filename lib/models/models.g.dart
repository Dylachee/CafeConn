// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 1;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItem(
      name: fields[0] as String,
      qty: fields[1] as int,
      price: fields[2] as double,
      note: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.qty)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CafeTableAdapter extends TypeAdapter<CafeTable> {
  @override
  final int typeId = 2;

  @override
  CafeTable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CafeTable(
      number: fields[0] as int,
      displayName: fields[1] as String?,
      seats: fields[2] as int,
      status: fields[3] as TableStatus,
      colorTag: fields[4] as String?,
      waiter: fields[5] as String,
      openedAt: fields[6] as DateTime?,
      notes: (fields[7] as List).cast<String>(),
      order: (fields[8] as List).cast<OrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, CafeTable obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.seats)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.colorTag)
      ..writeByte(5)
      ..write(obj.waiter)
      ..writeByte(6)
      ..write(obj.openedAt)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CafeTableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 4;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      station: fields[3] as Station,
      price: fields[4] as double,
      prepMinutes: fields[5] as int,
      available: fields[6] as bool,
      composition: fields[7] as String,
      allergens: (fields[8] as List).cast<String>(),
      imageUrl: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.station)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.prepMinutes)
      ..writeByte(6)
      ..write(obj.available)
      ..writeByte(7)
      ..write(obj.composition)
      ..writeByte(8)
      ..write(obj.allergens)
      ..writeByte(9)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StationTicketAdapter extends TypeAdapter<StationTicket> {
  @override
  final int typeId = 5;

  @override
  StationTicket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StationTicket(
      id: fields[0] as String,
      station: fields[1] as Station,
      tableNumber: fields[2] as int,
      items: (fields[3] as List).cast<OrderItem>(),
      createdAt: fields[4] as DateTime,
      ready: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StationTicket obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.station)
      ..writeByte(2)
      ..write(obj.tableNumber)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.ready);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationTicketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StaffMemberAdapter extends TypeAdapter<StaffMember> {
  @override
  final int typeId = 7;

  @override
  StaffMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StaffMember(
      name: fields[0] as String,
      role: fields[1] as StaffRole,
      status: fields[2] as String,
      online: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StaffMember obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.online);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatGroupAdapter extends TypeAdapter<ChatGroup> {
  @override
  final int typeId = 8;

  @override
  ChatGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      lastText: fields[2] as String,
      time: fields[3] as String,
      pinned: fields[4] as bool,
      unread: fields[5] as int,
      initials: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatGroup obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lastText)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.pinned)
      ..writeByte(5)
      ..write(obj.unread)
      ..writeByte(6)
      ..write(obj.initials);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TableSnapshotAdapter extends TypeAdapter<TableSnapshot> {
  @override
  final int typeId = 10;

  @override
  TableSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TableSnapshot(
      number: fields[0] as int,
      items: (fields[1] as List).cast<OrderItem>(),
      total: fields[2] as double,
      zoneHint: fields[3] as Station?,
    );
  }

  @override
  void write(BinaryWriter writer, TableSnapshot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.total)
      ..writeByte(3)
      ..write(obj.zoneHint);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 11;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,
      kind: fields[1] as MessageKind,
      own: fields[2] as bool,
      who: fields[3] as String,
      text: fields[4] as String,
      time: fields[5] as String,
      tableNumber: fields[6] as int?,
      snapshot: fields[7] as TableSnapshot?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kind)
      ..writeByte(2)
      ..write(obj.own)
      ..writeByte(3)
      ..write(obj.who)
      ..writeByte(4)
      ..write(obj.text)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.tableNumber)
      ..writeByte(7)
      ..write(obj.snapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 12;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      currentStaffName: fields[0] as String,
      themeModeIndex: fields[1] as int,
      textScaleFactor: fields[2] as double,
      tablesPerRow: fields[3] as int,
      showGestureHints: fields[4] as bool,
      defaultOrdersZoneIndex: fields[5] as int,
      currencySymbol: fields[6] as String,
      currencyIsPrefix: fields[7] as bool,
      is24HourClock: fields[8] as bool,
      hapticsEnabled: fields[9] as bool,
      soundsEnabled: fields[10] as bool,
      volume: fields[11] as double,
      lateThresholdMinutes: fields[12] as int,
      newOrderBannerEnabled: fields[13] as bool,
      syncCompleteToastEnabled: fields[14] as bool,
      shiftStartTime: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.currentStaffName)
      ..writeByte(1)
      ..write(obj.themeModeIndex)
      ..writeByte(2)
      ..write(obj.textScaleFactor)
      ..writeByte(3)
      ..write(obj.tablesPerRow)
      ..writeByte(4)
      ..write(obj.showGestureHints)
      ..writeByte(5)
      ..write(obj.defaultOrdersZoneIndex)
      ..writeByte(6)
      ..write(obj.currencySymbol)
      ..writeByte(7)
      ..write(obj.currencyIsPrefix)
      ..writeByte(8)
      ..write(obj.is24HourClock)
      ..writeByte(9)
      ..write(obj.hapticsEnabled)
      ..writeByte(10)
      ..write(obj.soundsEnabled)
      ..writeByte(11)
      ..write(obj.volume)
      ..writeByte(12)
      ..write(obj.lateThresholdMinutes)
      ..writeByte(13)
      ..write(obj.newOrderBannerEnabled)
      ..writeByte(14)
      ..write(obj.syncCompleteToastEnabled)
      ..writeByte(15)
      ..write(obj.shiftStartTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TableStatusAdapter extends TypeAdapter<TableStatus> {
  @override
  final int typeId = 0;

  @override
  TableStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TableStatus.free;
      case 1:
        return TableStatus.occupied;
      case 2:
        return TableStatus.newOrder;
      case 3:
        return TableStatus.ready;
      case 4:
        return TableStatus.late;
      default:
        return TableStatus.free;
    }
  }

  @override
  void write(BinaryWriter writer, TableStatus obj) {
    switch (obj) {
      case TableStatus.free:
        writer.writeByte(0);
        break;
      case TableStatus.occupied:
        writer.writeByte(1);
        break;
      case TableStatus.newOrder:
        writer.writeByte(2);
        break;
      case TableStatus.ready:
        writer.writeByte(3);
        break;
      case TableStatus.late:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StationAdapter extends TypeAdapter<Station> {
  @override
  final int typeId = 3;

  @override
  Station read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Station.kitchen;
      case 1:
        return Station.bar;
      default:
        return Station.kitchen;
    }
  }

  @override
  void write(BinaryWriter writer, Station obj) {
    switch (obj) {
      case Station.kitchen:
        writer.writeByte(0);
        break;
      case Station.bar:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StaffRoleAdapter extends TypeAdapter<StaffRole> {
  @override
  final int typeId = 6;

  @override
  StaffRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StaffRole.waiter;
      case 1:
        return StaffRole.cook;
      case 2:
        return StaffRole.bar;
      case 3:
        return StaffRole.manager;
      case 4:
        return StaffRole.admin;
      default:
        return StaffRole.waiter;
    }
  }

  @override
  void write(BinaryWriter writer, StaffRole obj) {
    switch (obj) {
      case StaffRole.waiter:
        writer.writeByte(0);
        break;
      case StaffRole.cook:
        writer.writeByte(1);
        break;
      case StaffRole.bar:
        writer.writeByte(2);
        break;
      case StaffRole.manager:
        writer.writeByte(3);
        break;
      case StaffRole.admin:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageKindAdapter extends TypeAdapter<MessageKind> {
  @override
  final int typeId = 9;

  @override
  MessageKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageKind.text;
      case 1:
        return MessageKind.orderCard;
      case 2:
        return MessageKind.tableCard;
      default:
        return MessageKind.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageKind obj) {
    switch (obj) {
      case MessageKind.text:
        writer.writeByte(0);
        break;
      case MessageKind.orderCard:
        writer.writeByte(1);
        break;
      case MessageKind.tableCard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
