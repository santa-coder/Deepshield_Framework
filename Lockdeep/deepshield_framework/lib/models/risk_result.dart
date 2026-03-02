enum RiskDecision { granted, otpRequired, denied }

class RiskResult {
  final double finalScore;
  final RiskDecision decision;
  final Map<String, double> breakdown;

  const RiskResult({
    required this.finalScore,
    required this.decision,
    required this.breakdown,
  });

  String get decisionLabel {
    switch (decision) {
      case RiskDecision.granted:
        return 'ACCESS GRANTED';
      case RiskDecision.otpRequired:
        return 'OTP REQUIRED';
      case RiskDecision.denied:
        return 'ACCESS DENIED';
    }
  }

  String get decisionDescription {
    switch (decision) {
      case RiskDecision.granted:
        return 'All biometric signals verified. Identity confirmed.';
      case RiskDecision.otpRequired:
        return 'Moderate risk detected. Additional verification needed.';
      case RiskDecision.denied:
        return 'High risk signals detected. Authentication blocked.';
    }
  }
}