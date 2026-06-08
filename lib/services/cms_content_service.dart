import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/app_settings_record.dart';

const String _kLegalBaseUrl = 'https://www.fococo.ai';

/// Firestore-backed CMS: legal URLs, disclosures, and app settings.
class CmsContentService {
  CmsContentService._();

  static final CmsContentService instance = CmsContentService._();

  static const Map<String, String> _fallbackLegalSlugs = {
    'privacy': 'privacy-policy',
    'terms': 'terms',
    'ai': 'ai-disclosure',
    'data_security': 'data-security',
    'non_medical': 'non-medical-disclaimer',
    'cookie': 'cookie-policy',
    'account_deletion': 'delete-account',
    'licenses': 'licenses',
  };

  final Map<String, String> _legalPaths = Map<String, String>.from(_fallbackLegalSlugs);
  final Map<String, Map<String, String>> _disclosures = {};
  bool _maintenanceMode = false;
  String _maintenanceMessage =
      'FoCoCo is currently undergoing maintenance. Please try again later.';
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;

  Future<void> initialize() async {
    if (_loaded) return;
    try {
      await Future.wait([
        _loadLegalDocuments(),
        _loadDisclosures(),
        _loadAppSettings(),
      ]);
      _loaded = true;
      if (kDebugMode) {
        debugPrint('✅ CMS content loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CMS content load failed, using fallbacks: $e');
      }
      _loaded = true;
    }
  }

  String legalUrl(String documentKey) {
    final path = _legalPaths[documentKey] ?? _fallbackLegalSlugs[documentKey];
    if (path == null || path.isEmpty) return _kLegalBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$_kLegalBaseUrl$normalized';
  }

  Map<String, String>? disclosureFields(String topicKey) {
    return _disclosures[topicKey];
  }

  Future<void> _loadLegalDocuments() async {
    final snap = await FirebaseFirestore.instance.collection('legal_documents').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['published'] == false) continue;
      final canonicalPath = data['canonicalPath'] as String?;
      if (canonicalPath == null || canonicalPath.isEmpty) continue;
      final path = canonicalPath.startsWith('/') ? canonicalPath.substring(1) : canonicalPath;
      for (final entry in _fallbackLegalSlugs.entries) {
        if (entry.value == path || doc.id == entry.value || doc.id == path) {
          _legalPaths[entry.key] = path;
        }
      }
      if (doc.id == 'privacy') _legalPaths['privacy'] = path;
      if (doc.id == 'cookies') _legalPaths['cookie'] = path;
      if (doc.id == 'ai-disclosure') _legalPaths['ai'] = path;
      if (doc.id == 'data-security') _legalPaths['data_security'] = path;
      if (doc.id == 'non-medical-disclaimer') _legalPaths['non_medical'] = path;
      if (doc.id == 'delete-account') _legalPaths['account_deletion'] = path;
      if (doc.id == 'licenses') _legalPaths['licenses'] = path;
    }
  }

  Future<void> _loadDisclosures() async {
    final snap = await FirebaseFirestore.instance
        .collection('content_blocks')
        .doc('first_use_disclosures')
        .get();
    if (!snap.exists) return;
    final payload = snap.data()?['payload'];
    if (payload is! Map<String, dynamic>) return;

    for (final key in ['microphone', 'location', 'ai']) {
      final raw = payload[key];
      if (raw is! Map<String, dynamic>) continue;
      final title = raw['title'] as String?;
      final body = raw['body'] as String?;
      if (title == null || body == null) continue;
      _disclosures[key] = {
        'title': title,
        'body': body,
        'policyUrl': (raw['policyUrl'] as String?) ?? legalUrl('privacy'),
        'continueLabel': (raw['continueLabel'] as String?) ?? 'Continue',
      };
    }
  }

  Future<void> _loadAppSettings() async {
    final ref = AppSettingsRecord.collection.doc('default');
    final record = await AppSettingsRecord.getDocumentOnce(ref);
    if (record.hasMaintenanceMode()) {
      _maintenanceMode = record.maintenanceMode;
    }
    if (record.hasMaintenanceMessage() && record.maintenanceMessage.isNotEmpty) {
      _maintenanceMessage = record.maintenanceMessage;
    }
  }
}
