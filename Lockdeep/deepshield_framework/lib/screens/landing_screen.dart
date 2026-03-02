import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
import 'login_screen.dart';
import '../models/auth_session.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAuth() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(session: AuthSession()),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // Background radial glow
            Positioned(
              top: -100,
              left: size.width / 2 - 200,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.neonBlue.withValues(alpha: 0.08 * _pulse.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
             child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppTheme.neonBlue, AppTheme.neonGreen],
                          ).createShader(b),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'DEEPSHIELD',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ENTERPRISE · FIDO2 · AI-POWERED',
                        style: TextStyle(color: AppTheme.neonBlue, fontSize: 10, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Hero illustration
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(
                            color: AppTheme.neonBlue.withValues(alpha: 0.4 * _pulse.value),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonBlue.withValues(alpha: 0.15 * _pulse.value),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.2), width: 1),
                              ),
                            ),
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.15), width: 1),
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [AppTheme.neonBlue, AppTheme.neonGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(b),
                              child: const Icon(Icons.fingerprint, size: 70, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Title
                    const Text(
                      'Next-Gen Identity\nVerification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AI-based multi-modal authentication combining\nliveness detection, voice analysis, and\nbehavioral biometrics for zero-trust access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Feature chips
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeatureChip(icon: Icons.face_retouching_natural, label: 'Liveness'),
                        _FeatureChip(icon: Icons.mic, label: 'Voice AI'),
                        _FeatureChip(icon: Icons.fingerprint, label: 'Behavior'),
                        _FeatureChip(icon: Icons.location_on, label: 'Geo-Risk'),
                        _FeatureChip(icon: Icons.devices, label: 'Device ID'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: NeonButton(
                       label: 'START SECURE AUTHENTICATION',
                       onPressed: _startAuth,
                       icon: Icons.lock_open_rounded,
                    ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Protected by 256-bit AES encryption',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
             ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.neonBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
