import 'diagnosis.dart';

/// État d'une session tel que renvoyé par le backend (source de vérité).
class SessionState {
  const SessionState({
    required this.id,
    required this.status,
    required this.currentState,
    required this.pendingAnalysis,
    required this.messageCount,
    this.title,
    this.category,
    this.riskLevel,
    this.latestMediaId,
    this.next,
  });

  final String id;
  final String status; // active | resolved | stopped | referred
  final String currentState;
  final String? title;
  final String? category;
  final String? riskLevel;
  final bool pendingAnalysis;
  final int messageCount;
  final String? latestMediaId;
  final NextStep? next;

  bool get isActive => status == 'active';

  factory SessionState.fromJson(Map<String, dynamic> j) => SessionState(
        id: j['id'] as String,
        status: j['status'] as String,
        currentState: j['current_state'] as String,
        title: j['title'] as String?,
        category: j['category'] as String?,
        riskLevel: j['risk_level'] as String?,
        pendingAnalysis: j['pending_analysis'] as bool? ?? false,
        messageCount: (j['messages'] as List? ?? const []).length,
        latestMediaId: j['latest_media_id'] as String?,
        next: j['next'] == null ? null : NextStep.fromJson(j['next'] as Map<String, dynamic>),
      );
}

/// La dernière réponse de Nalvium : détermine l'écran.
class NextStep {
  const NextStep({
    required this.actionType,
    required this.message,
    this.choices = const [],
    this.requiredItems = const [],
    this.stepNumber,
    this.diyAllowed,
  });

  final NextActionType actionType;
  final String message;
  final List<String> choices;
  final List<String> requiredItems;
  final int? stepNumber;
  final bool? diyAllowed;

  factory NextStep.fromJson(Map<String, dynamic> j) => NextStep(
        actionType: NextActionType.fromWire(j['action_type'] as String),
        message: j['message'] as String,
        choices: List<String>.from(j['choices'] as List? ?? const []),
        requiredItems: List<String>.from(j['required_items'] as List? ?? const []),
        stepNumber: j['step_number'] as int?,
        diyAllowed: j['diy_allowed'] as bool?,
      );
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.status,
    required this.currentState,
    required this.updatedAt,
    this.title,
    this.category,
    this.firstMediaId,
  });

  final String id;
  final String status;
  final String currentState;
  final String? title;
  final String? category;
  final DateTime updatedAt;
  final String? firstMediaId;

  factory SessionSummary.fromJson(Map<String, dynamic> j) => SessionSummary(
        id: j['id'] as String,
        status: j['status'] as String,
        currentState: j['current_state'] as String,
        title: j['title'] as String?,
        category: j['category'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        firstMediaId: j['first_media_id'] as String?,
      );
}

enum ActionChoice { done, cannot, mismatch }

/// Entrée utilisateur envoyée au backend pour un tour de conversation.
sealed class TurnInput {
  const TurnInput();
  Map<String, dynamic> toJson();
}

class DescriptionTurn extends TurnInput {
  const DescriptionTurn(this.text);
  final String text;
  @override
  Map<String, dynamic> toJson() => {'kind': 'description', 'text': text};
}

class AnswerTurn extends TurnInput {
  const AnswerTurn(this.text);
  final String text;
  @override
  Map<String, dynamic> toJson() => {'kind': 'answer', 'text': text};
}

class PhotoTurn extends TurnInput {
  const PhotoTurn(this.mediaId);
  final String mediaId;
  @override
  Map<String, dynamic> toJson() => {'kind': 'photo', 'media_id': mediaId};
}

class ActionResultTurn extends TurnInput {
  const ActionResultTurn(this.choice);
  final ActionChoice choice;
  @override
  Map<String, dynamic> toJson() => {'kind': 'action_result', 'choice': choice.name};
}
