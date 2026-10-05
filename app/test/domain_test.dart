import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';

void main() {
  Map<String, dynamic> json(String type, {String risk = 'low', bool diy = true}) => {
        'risk_level': risk,
        'diy_allowed': diy,
        'next_action': {'type': type, 'message': 'msg'},
      };

  test('tous les types d\'action du contrat backend sont reconnus', () {
    const wire = {
      'ASK_QUESTION': NextActionType.askQuestion,
      'REQUEST_PHOTO': NextActionType.requestPhoto,
      'INSTRUCTION': NextActionType.instruction,
      'VERIFICATION': NextActionType.verification,
      'SAFETY_STOP': NextActionType.safetyStop,
      'RECOMMEND_PROFESSIONAL': NextActionType.recommendProfessional,
      'RESOLVED': NextActionType.resolved,
    };
    wire.forEach((k, v) => expect(DiagnosticAnalysis.fromJson(json(k)).nextAction.type, v));
  });

  test('SAFETY_STOP est détecté', () {
    final a = DiagnosticAnalysis.fromJson(json('SAFETY_STOP', risk: 'emergency', diy: false));
    expect(a.isSafetyStop, isTrue);
    expect(a.riskLevel, RiskLevel.emergency);
    expect(a.diyAllowed, isFalse);
  });

  test('type d\'action inconnu rejeté', () {
    expect(() => DiagnosticAnalysis.fromJson(json('NOPE')), throwsFormatException);
  });
}
