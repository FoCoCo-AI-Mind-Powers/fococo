import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/pages/golf_rounds/caddyplay_widget.dart';
import 'package:fo_co_co/pages/golf_rounds/golf_sync_widget.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('golf_sync wrapper renders CaddyPlayWidget', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GolfSyncWidget()));

    expect(find.byType(GolfSyncWidget), findsOneWidget);
    expect(find.byType(CaddyPlayWidget), findsOneWidget);
  });

  test('golf_sync route contract remains compatible', () {
    expect(GolfSyncWidget.routeName, 'golf_sync');
    expect(GolfSyncWidget.routePath, '/golf_sync');
  });
}
