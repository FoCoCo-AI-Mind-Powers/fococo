/// Voice Session Models
/// Data structures for voice coaching sessions and interactions

import 'dart:convert';
import 'dart:typed_data';

/// Voice event types
enum VoiceEventType {
  userSpeaking,
  assistantResponse,
  navigationGuidance,
  pointOfInterest,
  sessionStart,
  sessionEnd,
}

/// Voice session model
class VoiceSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<VoiceInteraction> interactions;
  final List<({double lat, double lng})> path;
  final Map<String, dynamic> metadata;

  VoiceSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.interactions,
    required this.path,
    required this.metadata,
  });

  VoiceSession copyWith({
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    List<VoiceInteraction>? interactions,
    List<({double lat, double lng})>? path,
    Map<String, dynamic>? metadata,
  }) {
    return VoiceSession(
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      interactions: interactions ?? this.interactions,
      path: path ?? this.path,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'interactions': interactions.map((i) => i.toJson()).toList(),
        'path': path.map((p) => {'lat': p.lat, 'lng': p.lng}).toList(),
        'metadata': metadata,
        'duration': duration.inSeconds,
      };

  factory VoiceSession.fromJson(Map<String, dynamic> json) {
    return VoiceSession(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      interactions: (json['interactions'] as List)
          .map((i) => VoiceInteraction.fromJson(i as Map<String, dynamic>))
          .toList(),
      path: (json['path'] as List)
          .map((p) => (
                lat: (p['lat'] as num).toDouble(),
                lng: (p['lng'] as num).toDouble(),
              ))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}

/// Voice interaction model
class VoiceInteraction {
  final DateTime timestamp;
  final String speaker; // 'user' or 'assistant'
  final String? text;
  final Uint8List? audio;
  final ({double lat, double lng}) location;
  final Map<String, dynamic>? context;

  VoiceInteraction({
    required this.timestamp,
    required this.speaker,
    this.text,
    this.audio,
    required this.location,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'speaker': speaker,
        'text': text,
        'audio': audio != null ? base64Encode(audio!) : null,
        'location': {'lat': location.lat, 'lng': location.lng},
        'context': context,
      };

  factory VoiceInteraction.fromJson(Map<String, dynamic> json) {
    return VoiceInteraction(
      timestamp: DateTime.parse(json['timestamp'] as String),
      speaker: json['speaker'] as String,
      text: json['text'] as String?,
      audio: json['audio'] != null
          ? base64Decode(json['audio'] as String)
          : null,
      location: (
        lat: (json['location']['lat'] as num).toDouble(),
        lng: (json['location']['lng'] as num).toDouble(),
      ),
      context: json['context'] as Map<String, dynamic>?,
    );
  }
}

/// Voice event model
class VoiceEvent {
  final VoiceEventType type;
  final DateTime timestamp;
  final ({double lat, double lng})? location;
  final String? content;
  final Map<String, dynamic>? data;

  VoiceEvent({
    required this.type,
    required this.timestamp,
    this.location,
    this.content,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'location': location != null
            ? {'lat': location!.lat, 'lng': location!.lng}
            : null,
        'content': content,
        'data': data,
      };
}