import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/ai_integration/models/mind_coach_models.dart';

/// Service for detecting scenarios from user input and context
/// Uses scenario tags CSV to identify relevant scenarios
class MindCoachScenarioDetector {
  static MindCoachScenarioDetector? _instance;
  static MindCoachScenarioDetector get instance {
    _instance ??= MindCoachScenarioDetector._();
    return _instance!;
  }

  MindCoachScenarioDetector._();

  List<ScenarioTag>? _scenarioTags;
  bool _isLoading = false;

  /// Load scenario tags from CSV asset or Firestore
  Future<void> loadScenarioTags() async {
    if (_scenarioTags != null) return;
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isLoading = true;
    try {
      // Try loading from Firestore first
      await _loadFromFirestore();
      
      // If Firestore load failed, try CSV asset
      if (_scenarioTags == null || _scenarioTags!.isEmpty) {
        try {
          final String csvContent = await rootBundle.loadString(
            'assets/csvs/mindcoach_scenario_tags.csv',
          );
          _parseCsvContent(csvContent);
        } catch (e) {
          if (_scenarioTags == null) {
            _scenarioTags = [];
          }
        }
      }
    } catch (e) {
      _scenarioTags = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Load scenario tags from Firestore
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mindcoach_scenario_tags')
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final tags = <ScenarioTag>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          tags.add(ScenarioTag(
            tagId: data['tag_id'] ?? doc.id,
            tagName: data['tag_name'] ?? data['scenario_tag'] ?? '',
            description: data['description'] ?? '',
            detectionPhrases: data['detection_phrases'] is List
                ? List<String>.from(data['detection_phrases'])
                : (data['detection_phrases'] ?? '').toString().split(',').where((p) => p.isNotEmpty).toList(),
            templateAffinity: data['template_affinity'] is List
                ? List<String>.from(data['template_affinity'])
                : (data['template_affinity'] ?? '').toString().split(',').where((t) => t.isNotEmpty).toList(),
            contextSignals: data['context_signals'] is List
                ? List<String>.from(data['context_signals'])
                : (data['context_signals'] ?? '').toString().split(',').where((s) => s.isNotEmpty).toList(),
          ));
        } catch (e) {
          continue;
        }
      }

      _scenarioTags = tags;
    } catch (e) {
      _scenarioTags = null;
    }
  }

  /// Parse CSV content string
  void _parseCsvContent(String csvContent) {
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty) {
        _scenarioTags = [];
        return;
      }

      // Parse header
      final headers = lines[0].split(',').map((h) => h.trim()).toList();

      // Parse rows
      final tags = <ScenarioTag>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final row = line.split(',');
        if (row.length < headers.length) continue;

        final rowMap = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowMap[headers[j]] = row[j].trim();
        }

        try {
          tags.add(ScenarioTag.fromCsvRow(rowMap));
        } catch (e) {
          continue;
        }
      }

      _scenarioTags = tags;
    } catch (e) {
      _scenarioTags = [];
    }
  }

  /// Detect scenarios from user input and context
  /// Returns list of detected scenario tag names
  Future<List<String>> detectScenarios({
    String? userMessage,
    Map<String, dynamic>? context,
    int? mindsetRating,
    List<Map<String, dynamic>>? recentShots,
  }) async {
    await loadScenarioTags();

    if (_scenarioTags == null || _scenarioTags!.isEmpty) {
      return [];
    }

    final detectedTags = <String>[];

    // Text-based detection
    if (userMessage != null && userMessage.isNotEmpty) {
      final lowerMessage = userMessage.toLowerCase();

      for (final tag in _scenarioTags!) {
        // Check if any detection phrase matches
        final matched = tag.detectionPhrases.any((phrase) {
          return lowerMessage.contains(phrase.toLowerCase());
        });

        if (matched) {
          detectedTags.add(tag.tagName);
        }
      }
    }

    // Context-based detection
    if (context != null) {
      // High pressure scenario
      if (context['pressure_level'] == 'high') {
        detectedTags.add('high_pressure');
      }

      // Slow play scenario
      if (context['pace_flag'] == true || context['pace_flag'] == 'slow_play') {
        detectedTags.add('slow_play_rumination');
      }

      // Fast group behind
      if (context['pace_flag'] == 'fast_group_behind') {
        detectedTags.add('fast_group_behind');
      }

      // Wind adjustment
      if (context['weather'] != null && context['weather'].toString().toLowerCase().contains('wind')) {
        detectedTags.add('wind_adjustment');
      }

      // Tight lie
      if (context['lie_type'] == 'tight' || context['lie_type'] == 'difficult') {
        detectedTags.add('tight_lie');
      }
    }

    // Mindset rating detection
    if (mindsetRating != null && mindsetRating <= 2) {
      detectedTags.add('struggling');
    }

    // Recent performance detection
    if (recentShots != null && recentShots.length >= 3) {
      final lastThree = recentShots.sublist(recentShots.length - 3);
      final allPoor = lastThree.every((shot) {
        final result = shot['result']?.toString().toLowerCase();
        return result == 'poor' || result == 'bad' || result == 'missed';
      });

      if (allPoor) {
        detectedTags.add('spiral');
      }
    }

    // Return unique tags
    return detectedTags.toSet().toList();
  }

  /// Get scenario tag by name
  Future<ScenarioTag?> getScenarioTag(String tagName) async {
    await loadScenarioTags();
    if (_scenarioTags == null) return null;

    try {
      return _scenarioTags!.firstWhere((tag) => tag.tagName == tagName);
    } catch (e) {
      return null;
    }
  }

  /// Get all scenario tags (for debugging/testing)
  Future<List<ScenarioTag>> getAllScenarioTags() async {
    await loadScenarioTags();
    return _scenarioTags ?? [];
  }
}
