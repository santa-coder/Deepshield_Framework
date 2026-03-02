import '../models/auth_session.dart';
import '../models/risk_result.dart';
import '../utils/constants.dart';

class RiskEngine {
  /// Calculates the final composite risk score from all biometric signals.
  ///
  /// Formula:
  ///   riskScore = (100 - livenessScore) * 0.25
  ///             + (100 - behaviorScore) * 0.20
  ///             + voiceScore           * 0.20
  ///             + deviceRisk           * 0.15
  ///             + locationRisk         * 0.20
  ///
  /// Range: 0–100 (0 = perfectly safe, 100 = maximum risk)
  /// Decision:
  ///   0–40  → Access Granted
  ///   41–70 → OTP Required
  ///   71+   → Access Denied
  static RiskResult calculate(AuthSession session) {
    final double livenessComponent = (100 - session.livenessScore) * AppConstants.livenessWeight;
    final double behaviorComponent = (100 - session.behaviorScore) * AppConstants.behaviorWeight;
    final double voiceComponent = session.voiceScore * AppConstants.voiceWeight;
    final double deviceComponent = session.deviceRisk * AppConstants.deviceWeight;
    final double locationComponent = session.locationRisk * AppConstants.locationWeight;

    final double total = livenessComponent + behaviorComponent + voiceComponent + deviceComponent + locationComponent;
    final double clamped = total.clamp(0, 100);

    RiskDecision decision;
    if (clamped <= AppConstants.grantThreshold) {
      decision = RiskDecision.granted;
    } else if (clamped <= AppConstants.otpThreshold) {
      decision = RiskDecision.otpRequired;
    } else {
      decision = RiskDecision.denied;
    }

    return RiskResult(
      finalScore: clamped,
      decision: decision,
      breakdown: {
        'liveness': livenessComponent,
        'behavior': behaviorComponent,
        'voice': voiceComponent,
        'device': deviceComponent,
        'location': locationComponent,
      },
    );
  }

  /// Generates a behavioral biometrics score from typing metadata.
  /// Higher score = more human-like behavior = lower risk.
  static double calculateBehaviorScore({
    required int totalDurationMs,
    required int keystrokes,
    required List<int> interKeystrokeIntervals,
  }) {
    if (keystrokes == 0) return 40.0;

    // Average typing speed in chars/sec
    final double charsPerSec = keystrokes / (totalDurationMs / 1000);

    // Human average: 3–8 chars/sec → score 75–95
    // Too fast (>12) or too slow (<1) indicates bot or unusual behavior
    double speedScore;
    if (charsPerSec >= 2 && charsPerSec <= 10) {
      speedScore = 80 + (charsPerSec - 2) * 1.5;
      speedScore = speedScore.clamp(75, 95);
    } else if (charsPerSec > 10) {
      speedScore = (95 - (charsPerSec - 10) * 5).clamp(30, 95);
    } else {
      speedScore = (60 + charsPerSec * 10).clamp(30, 75);
    }

    // Rhythm variance — human typing has natural variance
    double rhythmBonus = 0;
    if (interKeystrokeIntervals.length > 2) {
      final avg = interKeystrokeIntervals.reduce((a, b) => a + b) / interKeystrokeIntervals.length;
      final variance = interKeystrokeIntervals.map((i) => (i - avg) * (i - avg)).reduce((a, b) => a + b) / interKeystrokeIntervals.length;
      // Natural human variance: 200–15000 ms²
      if (variance > 100 && variance < 20000) rhythmBonus = 5;
    }

    return (speedScore + rhythmBonus).clamp(0, 100);
  }

  /// Simulates a voice anti-spoof score.
  /// In production this would call an ML model endpoint.
  static double simulateVoiceScore(int durationMs) {
    // Simulate: longer recording with natural pauses = more human
    if (durationMs < 2000) return 72.0; // Too short = suspicious
    if (durationMs >= 4500) return 18.0; // Good recording = likely human
    return 35.0;
  }

  /// Calculates location risk based on distance from known previous location.
  static double calculateLocationRisk(double distanceKm) {
    if (distanceKm < 50) return 5.0;
    if (distanceKm < 200) return 25.0;
    if (distanceKm < 1000) return 55.0;
    return 90.0; // Impossible travel
  }

  /// Haversine formula to compute distance between two coordinates in km.
  static double haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double r = 6371; // Earth radius in km
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = _sin2(dLat / 2) +
        _cos(_deg2rad(lat1)) * _cos(_deg2rad(lat2)) * _sin2(dLon / 2);
    final double c = 2 * _atan2(a.clamp(0, 1));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (3.141592653589793 / 180);
  static double _sin2(double x) {
    final s = _mathSin(x);
    return s * s;
  }
  static double _cos(double x) => _mathCos(x);
  static double _atan2(double x) => x < 0.5 ? 2 * x : 3.141592653589793 - 2 * (1 - x);

  static double _mathSin(double x) {
    // Taylor series approximation for sin
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _mathCos(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
}