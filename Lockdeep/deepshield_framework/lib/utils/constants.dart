class AppConstants {
  static const String appName = 'DeepShield';
  static const String tagline = 'AI-Powered Multi-Modal\nSecure Authentication';
  static const String version = 'v2.4.1';
  
  // Risk weights
  static const double livenessWeight = 0.25;
  static const double behaviorWeight = 0.20;
  static const double voiceWeight = 0.20;
  static const double deviceWeight = 0.15;
  static const double locationWeight = 0.20;

  // Risk thresholds
  static const double grantThreshold = 40;
  static const double otpThreshold = 70;

  // Simulated previous location (New York)
  static const double prevLat = 40.7128;
  static const double prevLng = -74.0060;
}
