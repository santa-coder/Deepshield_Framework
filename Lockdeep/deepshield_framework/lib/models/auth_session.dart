class AuthSession {
  // Behavioral biometrics
  double behaviorScore;
  int loginDurationMs;
  double typingSpeed; // chars per second

  // Liveness
  double livenessScore;
  String livenessChallenge;
  bool livenessPass;

  // Voice
  double voiceScore;
  String voiceResult;

  // Device & location
  String deviceModel;
  String deviceId;
  bool isNewDevice;
  double deviceRisk;
  double latitude;
  double longitude;
  double locationRisk;
  double distanceFromPrevKm;

  // Final
  double finalRiskScore;
  String decision;
  DateTime timestamp;

  AuthSession({
    this.behaviorScore = 0,
    this.loginDurationMs = 0,
    this.typingSpeed = 0,
    this.livenessScore = 0,
    this.livenessChallenge = '',
    this.livenessPass = false,
    this.voiceScore = 0,
    this.voiceResult = '',
    this.deviceModel = '',
    this.deviceId = '',
    this.isNewDevice = false,
    this.deviceRisk = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.locationRisk = 0,
    this.distanceFromPrevKm = 0,
    this.finalRiskScore = 0,
    this.decision = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
