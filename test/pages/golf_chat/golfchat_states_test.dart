import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/ai_integration/models/gemini_models.dart';

void main() {
  test('GeminiConversationResponse carries mindCoachRecommendation', () {
    final response = GeminiConversationResponse(
      response: 'One observation. One question?',
      conversationType: 'coaching_conversation',
      sessionId: 'sess',
      context: const {},
      timestamp: DateTime(2026, 6, 8),
      model: 'gemini-2.5-flash',
      userId: 'user_1',
      mindCoachRecommendation: const {
        'pillar': 'focus',
        'title': 'Pre-shot reset',
        'subtitle': 'Based on your recent rounds',
      },
    );

    expect(response.mindCoachRecommendation?['pillar'], 'focus');
    expect(response.mindCoachRecommendation?['title'], 'Pre-shot reset');
  });
}
