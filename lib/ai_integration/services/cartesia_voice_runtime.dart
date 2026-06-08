import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../config/cartesia_config.dart';

/// Cached Cartesia Line / pronunciation runtime config from Cloud Functions.
class CartesiaVoiceRuntime {
  CartesiaVoiceRuntime._();

  static CartesiaVoiceRuntimeConfig? _cached;

  static Future<CartesiaVoiceRuntimeConfig> load({
    FirebaseFunctions? functions,
    bool forceRefresh = false,
  }) async {
    if (_cached != null && !forceRefresh) {
      return _cached!;
    }

    final fns = functions ?? FirebaseFunctions.instance;
    try {
      final result = await fns
          .httpsCallable(CartesiaConfig.runtimeConfigFunctionName)
          .call<Map<String, dynamic>>();
      final data = Map<String, dynamic>.from(result.data as Map);
      _cached = CartesiaVoiceRuntimeConfig(
        lineAgentId: (data['line_agent_id'] ?? '').toString().trim(),
        pronunciationDictId:
            (data['pronunciation_dict_id'] ?? '').toString().trim(),
        cartesiaVersion:
            (data['cartesia_version'] ?? CartesiaConfig.version).toString(),
      );
      CartesiaConfig.lineAgentId = _cached!.lineAgentId;
      CartesiaConfig.pronunciationDictId = _cached!.pronunciationDictId;
      if (kDebugMode) {
        debugPrint(
          '🎙 Cartesia runtime: agent=${_cached!.lineAgentId.isEmpty ? "(none)" : _cached!.lineAgentId}',
        );
      }
      return _cached!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ getCartesiaVoiceRuntimeConfig failed: $e');
      }
      _cached = const CartesiaVoiceRuntimeConfig();
      return _cached!;
    }
  }

  static void clearCache() => _cached = null;
}

class CartesiaVoiceRuntimeConfig {
  const CartesiaVoiceRuntimeConfig({
    this.lineAgentId = '',
    this.pronunciationDictId = '',
    this.cartesiaVersion = CartesiaConfig.version,
  });

  final String lineAgentId;
  final String pronunciationDictId;
  final String cartesiaVersion;

  bool get hasLineAgent => lineAgentId.isNotEmpty;
}
