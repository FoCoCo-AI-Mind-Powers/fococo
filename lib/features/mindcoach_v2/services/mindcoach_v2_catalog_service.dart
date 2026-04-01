import 'dart:convert';

import 'package:flutter/services.dart';

import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachV2CatalogSession {
  const MindCoachV2CatalogSession({
    required this.key,
    required this.name,
    required this.descriptor,
    required this.durationSec,
    required this.templateId,
    required this.pillar,
    required this.contextMode,
    this.overlayPhase,
  });

  final String key;
  final String name;
  final String descriptor;
  final int durationSec;
  final String templateId;
  final MindCoachV2Pillar pillar;
  final MindCoachV2ContextMode contextMode;
  final String? overlayPhase;
}

class MindCoachV2CatalogContext {
  const MindCoachV2CatalogContext({
    required this.mode,
    required this.label,
    this.durationHint,
    this.overlay = false,
    this.sessions = const <MindCoachV2CatalogSession>[],
  });

  final MindCoachV2ContextMode mode;
  final String label;
  final String? durationHint;
  final bool overlay;
  final List<MindCoachV2CatalogSession> sessions;
}

class MindCoachV2CatalogPillar {
  const MindCoachV2CatalogPillar({
    required this.key,
    required this.label,
    required this.descriptor,
    required this.colorHex,
    required this.rowDescriptors,
    required this.contexts,
  });

  final MindCoachV2Pillar key;
  final String label;
  final String descriptor;
  final String colorHex;
  final Map<MindCoachV2ContextMode, String> rowDescriptors;
  final Map<MindCoachV2ContextMode, MindCoachV2CatalogContext> contexts;

  MindCoachV2CatalogContext context(MindCoachV2ContextMode mode) =>
      contexts[mode]!;
}

class MindCoachV2Catalog {
  const MindCoachV2Catalog({
    required this.version,
    required this.homeSubtitle,
    required this.contextsOrder,
    required this.pillars,
    required this.sessionByKey,
  });

  final String version;
  final String homeSubtitle;
  final List<MindCoachV2ContextMode> contextsOrder;
  final List<MindCoachV2CatalogPillar> pillars;
  final Map<String, MindCoachV2CatalogSession> sessionByKey;

  MindCoachV2CatalogPillar pillar(MindCoachV2Pillar pillar) =>
      pillars.firstWhere((item) => item.key == pillar);

  MindCoachV2CatalogSession session(String key) => sessionByKey[key]!;
}

class MindCoachV2CatalogService {
  MindCoachV2CatalogService._();

  static const String _assetPath = 'assets/jsons/mindcoach_session_catalog_v1.json';
  static MindCoachV2CatalogService? _instance;
  static MindCoachV2CatalogService get instance =>
      _instance ??= MindCoachV2CatalogService._();

  Future<MindCoachV2Catalog>? _pendingLoad;
  MindCoachV2Catalog? _catalog;

  Future<MindCoachV2Catalog> load() {
    if (_catalog != null) {
      return Future<MindCoachV2Catalog>.value(_catalog);
    }
    if (_pendingLoad != null) {
      return _pendingLoad!;
    }
    _pendingLoad = _loadImpl();
    return _pendingLoad!;
  }

  MindCoachV2Catalog get requireLoaded {
    final catalog = _catalog;
    if (catalog == null) {
      throw StateError('MindCoach catalog has not been loaded yet.');
    }
    return catalog;
  }

  Future<MindCoachV2Catalog> _loadImpl() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final pillars = <MindCoachV2CatalogPillar>[];
      final sessionByKey = <String, MindCoachV2CatalogSession>{};

      for (final pillarRaw
          in (decoded['pillars'] as List<dynamic>? ?? const [])) {
        final pillarMap = Map<String, dynamic>.from(pillarRaw as Map);
        final pillar =
            MindCoachV2PillarX.fromWire(pillarMap['key']?.toString());
        final rowDescriptors = <MindCoachV2ContextMode, String>{};
        final rowMap = Map<String, dynamic>.from(
          pillarMap['row_descriptors'] as Map? ?? const <String, dynamic>{},
        );
        for (final entry in rowMap.entries) {
          rowDescriptors[MindCoachV2ContextModeX.fromWire(entry.key)] =
              entry.value.toString();
        }

        final contexts = <MindCoachV2ContextMode, MindCoachV2CatalogContext>{};
        final contextsMap = Map<String, dynamic>.from(
          pillarMap['contexts'] as Map? ?? const <String, dynamic>{},
        );
        for (final entry in contextsMap.entries) {
          final mode = MindCoachV2ContextModeX.fromWire(entry.key);
          final contextMap = Map<String, dynamic>.from(entry.value as Map);
          final sessions = <MindCoachV2CatalogSession>[];
          for (final sessionRaw
              in (contextMap['sessions'] as List<dynamic>? ?? const [])) {
            final sessionMap = Map<String, dynamic>.from(sessionRaw as Map);
            final session = MindCoachV2CatalogSession(
              key: sessionMap['key'].toString(),
              name: sessionMap['name'].toString(),
              descriptor: sessionMap['descriptor'].toString(),
              durationSec: (sessionMap['duration_sec'] as num).toInt(),
              templateId: sessionMap['template_id'].toString(),
              pillar: pillar,
              contextMode: mode,
              overlayPhase: sessionMap['overlay_phase']?.toString(),
            );
            sessions.add(session);
            sessionByKey[session.key] = session;
          }
          contexts[mode] = MindCoachV2CatalogContext(
            mode: mode,
            label: contextMap['label'].toString(),
            durationHint: contextMap['duration_hint']?.toString(),
            overlay: contextMap['overlay'] == true,
            sessions: sessions,
          );
        }

        pillars.add(
          MindCoachV2CatalogPillar(
            key: pillar,
            label: pillarMap['label'].toString(),
            descriptor: pillarMap['descriptor'].toString(),
            colorHex: pillarMap['color_hex'].toString(),
            rowDescriptors: rowDescriptors,
            contexts: contexts,
          ),
        );
      }

      final catalog = MindCoachV2Catalog(
        version: decoded['version'].toString(),
        homeSubtitle: decoded['home_subtitle'].toString(),
        contextsOrder: (decoded['contexts_order'] as List<dynamic>? ?? const [])
            .map((value) => MindCoachV2ContextModeX.fromWire(value.toString()))
            .toList(growable: false),
        pillars: pillars,
        sessionByKey: sessionByKey,
      );

      _catalog = catalog;
      return catalog;
    } finally {
      _pendingLoad = null;
    }
  }
}
