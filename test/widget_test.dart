<<<<<<< Updated upstream
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cafeconnect/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final hiveDir = Directory.systemTemp.createTempSync('cafeconnect_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox('cafeconnect');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('CafeConnect opens login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CafeConnectApp());
    await tester.pumpAndSettle();

    expect(find.text('CafeConnect'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
=======
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Smoke test', () {
    expect(true, true);
>>>>>>> Stashed changes
  });
}
