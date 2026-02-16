import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/ai_integration/models/mind_coach_models.dart';

/// Service for selecting content from the MindCoach Content Library CSV
/// Implements the selection algorithm from FoCoCo - AI Content Selection Rules.md
class MindCoachContentSelector {
  static MindCoachContentSelector? _instance;
  static MindCoachContentSelector get instance {
    _instance ??= MindCoachContentSelector._();
    return _instance!;
  }

  MindCoachContentSelector._();

  List<ContentLibraryEntry>? _contentLibrary;
  bool _isLoading = false;

  /// Load content library from CSV asset or Firestore
  /// Note: CSV files should be added to assets/ folder in pubspec.yaml
  /// or loaded from Firestore mindcoach_content_library collection
  Future<void> loadContentLibrary() async {
    if (_contentLibrary != null) return;
    if (_isLoading) {
      // Wait for ongoing load
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isLoading = true;
    try {
      // Try loading from Firestore first (recommended for production)
      await _loadFromFirestore();
      
      // If Firestore load failed or returned empty, try CSV asset
      if (_contentLibrary == null || _contentLibrary!.isEmpty) {
        try {
          // Note: Add CSV to assets/ folder and update pubspec.yaml to include it
          // For now, this will fail gracefully and use Firestore
          final String csvContent = await rootBundle.loadString(
            'assets/csvs/mindcoach_content_library.csv',
          );
          _parseCsvContent(csvContent);
        } catch (e) {
          // CSV asset not available, will use Firestore data or empty list
          if (_contentLibrary == null) {
            _contentLibrary = [];
          }
        }
      }
    } catch (e) {
      _contentLibrary = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Load content library from Firestore
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mindcoach_content_library')
          .get();

      if (snapshot.docs.isEmpty) {
        return; // No data in Firestore
      }

      final entries = <ContentLibraryEntry>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          // Convert Firestore document to ContentLibraryEntry
          entries.add(ContentLibraryEntry(
            contentId: data['content_id'] ?? doc.id,
            templateId: data['template_id'] ?? '',
            templateName: data['template_name'] ?? '',
            pillar: data['pillar'] ?? '',
            varkMode: data['vark_mode'] ?? 'ReadWrite',
            level: data['level'] ?? 'Foundation',
            length: data['length'] ?? 'standard',
            scenarioTags: data['scenario_tags'] is List
                ? List<String>.from(data['scenario_tags'])
                : (data['scenario_tags'] ?? '').toString().split(';').where((t) => t.isNotEmpty).toList(),
            pressureLevel: data['pressure_level'],
            lieType: data['lie_type'],
            windCondition: data['wind_condition'],
            regionVariant: data['region_variant'],
            scriptText: data['script_text'] ?? '',
            ctaQuestion: data['cta_question'],
            followUpPrompt: data['follow_up_prompt'],
            confidenceRatingHint: data['confidence_rating_hint'],
            doNotSayFlags: data['do_not_say_flags'] is List
                ? List<String>.from(data['do_not_say_flags'])
                : (data['do_not_say_flags'] ?? '').toString().split(',').where((f) => f.isNotEmpty).toList(),
          ));
        } catch (e) {
          continue; // Skip invalid entries
        }
      }

      _contentLibrary = entries;
    } catch (e) {
      // Firestore load failed, will try CSV or use empty list
      _contentLibrary = null;
    }
  }

  /// Parse CSV content string
  void _parseCsvContent(String csvContent) {
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty) {
        _contentLibrary = [];
        return;
      }

      // Parse header
      final headers = lines[0].split(',').map((h) => h.trim()).toList();

      // Parse rows
      final entries = <ContentLibraryEntry>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Handle CSV with quoted fields containing commas
        final row = _parseCsvLine(line);
        if (row.length < headers.length) continue;

        final rowMap = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowMap[headers[j]] = row[j].trim();
        }

        try {
          entries.add(ContentLibraryEntry.fromCsvRow(rowMap));
        } catch (e) {
          // Skip invalid rows
          continue;
        }
      }

      _contentLibrary = entries;
    } catch (e) {
      // Parsing failed
      _contentLibrary = [];
    }
  }

  /// Parse CSV line handling quoted fields
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }
    result.add(currentField); // Add last field

    return result;
  }


  /// Select content using the deterministic algorithm
  /// Returns the best-fit ContentLibraryEntry or null if none found
  Future<ContentLibraryEntry?> selectContent({
    required String templateId,
    String? varkMode,
    String? level,
    String? length,
    List<String>? scenarioTags,
  }) async {
    await loadContentLibrary();

    if (_contentLibrary == null || _contentLibrary!.isEmpty) {
      return null;
    }

    List<ContentLibraryEntry> candidates = List.from(_contentLibrary!);

    // Step 1: Filter by template_id (required)
    candidates = candidates.where((c) => c.templateId == templateId).toList();
    if (candidates.isEmpty) return null;

    // Step 2: Prioritize scenario tags if provided
    if (scenarioTags != null && scenarioTags.isNotEmpty) {
      final taggedCandidates = candidates.where((c) {
        return scenarioTags.any((tag) => c.scenarioTags.contains(tag));
      }).toList();

      if (taggedCandidates.isNotEmpty) {
        candidates = taggedCandidates;
      }
    }

    // Step 3: Filter by VARK mode
    final selectedVarkMode = varkMode ?? 'ReadWrite';
    final varkCandidates = candidates.where((c) => c.varkMode == selectedVarkMode).toList();
    if (varkCandidates.isNotEmpty) {
      candidates = varkCandidates;
    }

    // Step 4: Filter by level
    final selectedLevel = level ?? 'Foundation';
    final levelCandidates = candidates.where((c) => c.level == selectedLevel).toList();
    if (levelCandidates.isNotEmpty) {
      candidates = levelCandidates;
    }

    // Step 5: Filter by length
    final selectedLength = length ?? 'standard';
    final lengthCandidates = candidates.where((c) => c.length == selectedLength).toList();
    if (lengthCandidates.isNotEmpty) {
      candidates = lengthCandidates;
    }

    // Step 6: If multiple remain, pick the lowest content_id (stable)
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => a.contentId.compareTo(b.contentId));
      return candidates.first;
    }

    // Step 7: Relaxation fallback logic
    // Reset to template_id matches
    candidates = _contentLibrary!.where((c) => c.templateId == templateId).toList();

    // Relax scenario_tag
    if (scenarioTags != null && scenarioTags.isNotEmpty) {
      final relaxedCandidates = candidates.where((c) {
        return scenarioTags.any((tag) => c.scenarioTags.contains(tag));
      }).toList();
      if (relaxedCandidates.isNotEmpty) {
        candidates = relaxedCandidates;
      }
    }

    // Relax level
    final levelCandidatesRelaxed = candidates.where((c) => c.level == selectedLevel).toList();
    if (levelCandidatesRelaxed.isNotEmpty) {
      candidates = levelCandidatesRelaxed;
    }

    // Relax VARK mode
    final varkCandidatesRelaxed = candidates.where((c) => c.varkMode == selectedVarkMode).toList();
    if (varkCandidatesRelaxed.isNotEmpty) {
      candidates = varkCandidatesRelaxed;
    }

    // Relax length (standard fallback)
    final lengthCandidatesRelaxed = candidates.where((c) => c.length == 'standard').toList();
    if (lengthCandidatesRelaxed.isNotEmpty) {
      candidates = lengthCandidatesRelaxed;
    }

    // Return lowest content_id if any remain
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => a.contentId.compareTo(b.contentId));
      return candidates.first;
    }

    return null;
  }

  /// Get all content entries for a template (for debugging/testing)
  Future<List<ContentLibraryEntry>> getContentForTemplate(String templateId) async {
    await loadContentLibrary();
    if (_contentLibrary == null) return [];
    return _contentLibrary!.where((c) => c.templateId == templateId).toList();
  }
}
