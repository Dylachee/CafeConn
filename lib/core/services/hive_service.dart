import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveService {
  static const String boxName = 'cafeconnect';

  static Box get _box => Hive.box(boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  // --- Generic Persistence Helpers ---

  static void save(String key, dynamic value) {
    _box.put(key, value);
  }

  static dynamic load(String key) {
    return _box.get(key);
  }

  // --- Model Persistence ---

  static void saveMenu(List<MenuItem> menu) {
    final raw = jsonEncode(menu.map((e) => e.toJson()).toList());
    _box.put('menu', raw);
  }

  static List<MenuItem> loadMenu() {
    final raw = _box.get('menu') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static void saveTables(List<CafeTable> tables) {
    final raw = jsonEncode(tables.map((e) => e.toJson()).toList());
    _box.put('tables', raw);
  }

  static List<CafeTable> loadTables() {
    final raw = _box.get('tables') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CafeTable.fromJson(e as Map<String, dynamic>)).toList();
  }

  static void saveOrders(List<CafeOrder> orders) {
    final raw = jsonEncode(orders.map((e) => e.toJson()).toList());
    _box.put('orders', raw);
  }

  static List<CafeOrder> loadOrders(List<MenuItem> menu) {
    final raw = _box.get('orders') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CafeOrder.fromJson(e as Map<String, dynamic>, menu)).toList();
  }

  static void savePrefs(AppPrefs prefs) {
    _box.put('prefs', jsonEncode(prefs.toJson()));
  }

  static AppPrefs loadPrefs() {
    final raw = _box.get('prefs') as String?;
    if (raw == null) return const AppPrefs();
    return AppPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static void saveStaff(List<AppUser> staff) {
    final raw = jsonEncode(staff.map((e) => e.toJson()).toList());
    _box.put('staff', raw);
  }

  static List<AppUser> loadStaff() {
    final raw = _box.get('staff') as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static void resetAll() {
    _box.clear();
  }
}
