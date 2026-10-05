/// Modèles du domaine pour le futur diagnostic guidé (miroir du contrat backend).
enum RiskLevel { low, moderate, high, emergency }

enum Urgency { canWait, soon, now }

enum NextActionType {
  askQuestion,
  requestPhoto,
  instruction,
  verification,
  safetyStop,
  recommendProfessional,
  resolved;

  static NextActionType fromWire(String value) => switch (value) {
        'ASK_QUESTION' => askQuestion,
        'REQUEST_PHOTO' => requestPhoto,
        'INSTRUCTION' => instruction,
        'VERIFICATION' => verification,
        'SAFETY_STOP' => safetyStop,
        'RECOMMEND_PROFESSIONAL' => recommendProfessional,
        'RESOLVED' => resolved,
        _ => throw FormatException('NextActionType inconnu: $value'),
      };
}

enum VerificationOutcome { resolved, improved, unchanged, worsened, cannotDetermine }

class NextAction {
  const NextAction({required this.type, required this.message, this.choices = const []});

  final NextActionType type;
  final String message;
  final List<String> choices;

  factory NextAction.fromJson(Map<String, dynamic> json) => NextAction(
        type: NextActionType.fromWire(json['type'] as String),
        message: json['message'] as String,
        choices: List<String>.from(json['choices'] as List? ?? const []),
      );
}

class DiagnosticAnalysis {
  const DiagnosticAnalysis({
    required this.riskLevel,
    required this.diyAllowed,
    required this.nextAction,
    this.observations = const [],
    this.missingInformation = const [],
    this.requiredItems = const [],
  });

  final RiskLevel riskLevel;
  final bool diyAllowed;
  final NextAction nextAction;
  final List<String> observations;
  final List<String> missingInformation;
  final List<String> requiredItems;

  /// Un STOP interdit tout guidage DIY, quoi que dise le reste de la réponse.
  bool get isSafetyStop => nextAction.type == NextActionType.safetyStop;

  factory DiagnosticAnalysis.fromJson(Map<String, dynamic> json) => DiagnosticAnalysis(
        riskLevel: RiskLevel.values.byName(json['risk_level'] as String),
        diyAllowed: json['diy_allowed'] as bool,
        nextAction: NextAction.fromJson(json['next_action'] as Map<String, dynamic>),
        observations: List<String>.from(json['observations'] as List? ?? const []),
        missingInformation: List<String>.from(json['missing_information'] as List? ?? const []),
        requiredItems: List<String>.from(json['required_items'] as List? ?? const []),
      );
}

class DiagnosticRequest {
  const DiagnosticRequest({
    required this.sessionId,
    this.photoPaths = const [],
    this.description,
    this.conversation = const [],
    this.completedActions = const [],
    this.previousOutcomes = const [],
  });

  final String sessionId;
  final List<String> photoPaths;
  final String? description;
  final List<String> conversation;
  final List<String> completedActions;
  final List<VerificationOutcome> previousOutcomes;
}

/// Contrat d'accès au moteur de diagnostic (implémentation HTTP en phase 2).
abstract interface class DiagnosticRepository {
  Future<DiagnosticAnalysis> analyze(DiagnosticRequest request);
}
