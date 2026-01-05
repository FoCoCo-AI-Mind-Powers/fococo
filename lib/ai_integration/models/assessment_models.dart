import 'package:cloud_firestore/cloud_firestore.dart';

/// Models for AI-generated VARK assessment

class AssessmentQuestion {
  final String id;
  final String question;
  final String? imageUrl;
  final String? imageDescription;
  final List<AssessmentAnswer> answers;
  final String category; // 'focus', 'confidence', 'control', 'general'
  final int order;

  AssessmentQuestion({
    required this.id,
    required this.question,
    this.imageUrl,
    this.imageDescription,
    required this.answers,
    required this.category,
    required this.order,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      imageDescription: json['imageDescription'] as String?,
      answers: (json['answers'] as List?)
              ?.map((a) => AssessmentAnswer.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      category: json['category'] as String? ?? 'general',
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'imageUrl': imageUrl,
      'imageDescription': imageDescription,
      'answers': answers.map((a) => a.toJson()).toList(),
      'category': category,
      'order': order,
    };
  }
}

class AssessmentAnswer {
  final String id;
  final String text;
  final String varkType; // 'visual', 'aural', 'readWrite', 'kinesthetic'
  final int score; // Weight for this answer (typically 1)

  AssessmentAnswer({
    required this.id,
    required this.text,
    required this.varkType,
    this.score = 1,
  });

  factory AssessmentAnswer.fromJson(Map<String, dynamic> json) {
    return AssessmentAnswer(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      varkType: json['varkType'] as String? ?? 'visual',
      score: json['score'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'varkType': varkType,
      'score': score,
    };
  }
}

class AssessmentResult {
  final String userId;
  final DateTime completedAt;
  final List<QuestionResponse> responses;
  final VarkScores scores;
  final String dominantStyle;
  final String? secondaryStyle;
  final bool isMultiModal;
  final Map<String, dynamic> metadata;

  AssessmentResult({
    required this.userId,
    required this.completedAt,
    required this.responses,
    required this.scores,
    required this.dominantStyle,
    this.secondaryStyle,
    required this.isMultiModal,
    this.metadata = const {},
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      userId: json['userId'] as String? ?? '',
      completedAt:
          (json['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responses: (json['responses'] as List?)
              ?.map((r) => QuestionResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      scores:
          VarkScores.fromJson(json['scores'] as Map<String, dynamic>? ?? {}),
      dominantStyle: json['dominantStyle'] as String? ?? 'visual',
      secondaryStyle: json['secondaryStyle'] as String?,
      isMultiModal: json['isMultiModal'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'completedAt': Timestamp.fromDate(completedAt),
      'responses': responses.map((r) => r.toJson()).toList(),
      'scores': scores.toJson(),
      'dominantStyle': dominantStyle,
      'secondaryStyle': secondaryStyle,
      'isMultiModal': isMultiModal,
      'metadata': metadata,
    };
  }
}

class QuestionResponse {
  final String questionId;
  final String answerId;
  final String selectedVarkType;
  final DateTime answeredAt;

  QuestionResponse({
    required this.questionId,
    required this.answerId,
    required this.selectedVarkType,
    required this.answeredAt,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      questionId: json['questionId'] as String? ?? '',
      answerId: json['answerId'] as String? ?? '',
      selectedVarkType: json['selectedVarkType'] as String? ?? 'visual',
      answeredAt:
          (json['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answerId': answerId,
      'selectedVarkType': selectedVarkType,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };
  }
}

class VarkScores {
  final double visual;
  final double aural;
  final double readWrite;
  final double kinesthetic;

  VarkScores({
    required this.visual,
    required this.aural,
    required this.readWrite,
    required this.kinesthetic,
  });

  factory VarkScores.fromJson(Map<String, dynamic> json) {
    return VarkScores(
      visual: (json['visual'] as num?)?.toDouble() ?? 0.0,
      aural: (json['aural'] as num?)?.toDouble() ?? 0.0,
      readWrite: (json['readWrite'] as num?)?.toDouble() ?? 0.0,
      kinesthetic: (json['kinesthetic'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visual': visual,
      'aural': aural,
      'readWrite': readWrite,
      'kinesthetic': kinesthetic,
    };
  }

  String getDominantStyle() {
    final scores = {
      'visual': visual,
      'aural': aural,
      'readWrite': readWrite,
      'kinesthetic': kinesthetic,
    };
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String? getSecondaryStyle() {
    final scores = {
      'visual': visual,
      'aural': aural,
      'readWrite': readWrite,
      'kinesthetic': kinesthetic,
    };
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length > 1 && sorted[1].value > 0) {
      return sorted[1].key;
    }
    return null;
  }

  bool get isMultiModal {
    final scores = [visual, aural, readWrite, kinesthetic];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final highScores = scores.where((s) => s >= maxScore * 0.8).length;
    return highScores > 1;
  }
}

class AssessmentData {
  final String title;
  final String description;
  final List<AssessmentQuestion> questions;
  final List<String> imageDescriptions;
  final DateTime generatedAt;

  AssessmentData({
    required this.title,
    required this.description,
    required this.questions,
    required this.imageDescriptions,
    required this.generatedAt,
  });

  factory AssessmentData.fromJson(Map<String, dynamic> json) {
    return AssessmentData(
      title: json['title'] as String? ?? 'VARK Assessment',
      description: json['description'] as String? ?? '',
      questions: (json['questions'] as List?)
              ?.map(
                  (q) => AssessmentQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      imageDescriptions:
          List<String>.from(json['imageDescriptions'] as List? ?? []),
      generatedAt:
          (json['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'imageDescriptions': imageDescriptions,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}

