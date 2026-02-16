import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/pages/golf_chat/golfchat_widget.dart';

void main() {
  test('golf_chat route contract is defined', () {
    expect(GolfChatWidget.routeName, 'golf_chat');
    expect(GolfChatWidget.routePath, '/golf_chat');
  });
}
