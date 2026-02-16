import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/pages/just_talk/just_talk_widget.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  test('just_talk route contract is unchanged', () {
    expect(JustTalkWidget.routeName, 'just_talk');
    expect(JustTalkWidget.routePath, '/just_talk');
  });

  testWidgets('just_talk renders voice-first UI without text composer',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: JustTalkWidget(autoInitialize: false),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Tap the mic'), findsOneWidget);
  });
}
