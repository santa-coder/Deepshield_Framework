import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/auth_session.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/cyber_scaffold.dart';
import '../widgets/step_indicator.dart';
import 'voice_screen.dart';

class LivenessScreen extends StatefulWidget {
  final AuthSession session;
  const LivenessScreen({super.key, required this.session});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _cameraPermitted = false;
  bool _cameraInitialized = false;
  bool _isVerifying = false;
  bool _verificationDone = false;
  bool _verificationPassed = false;
  double _livenessScore = 0;

  String _currentChallenge = '';
  int _challengeCountdown = 5;
  Timer? _countdownTimer;
  int _challengeStep = 0;

  late AnimationController _pulseController;
  late AnimationController _resultController;
  late Animation<double> _pulseAnim;
  late Animation<double> _resultAnim;

  final List<String> _challenges = [
    'BLINK TWICE',
    'TURN HEAD LEFT',
    'SMILE NATURALLY',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _resultAnim = CurvedAnimation(parent: _resultController, curve: Curves.elasticOut);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() => _cameraPermitted = status.isGranted);
    if (_cameraPermitted) {
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      // Prefer front camera
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraInitialized = true);
    } catch (e) {
      // Camera not available in simulator — continue with simulation
      if (mounted) setState(() => _cameraInitialized = false);
    }
  }

  void _startLivenessCheck() {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _challengeStep = 0;
      _currentChallenge = _challenges[0];
      _challengeCountdown = 5;
    });
    _runChallenge();
  }

  void _runChallenge() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _challengeCountdown--;
        if (_challengeCountdown <= 0) {
          timer.cancel();
          _nextChallenge();
        }
      });
    });
  }

  void _nextChallenge() {
    _challengeStep++;
    if (_challengeStep >= _challenges.length) {
      _finishVerification();
      return;
    }
    setState(() {
      _currentChallenge = _challenges[_challengeStep];
      _challengeCountdown = 5;
    });
    _runChallenge();
  }

  void _finishVerification() {
    // Simulate ML liveness score: 70–95 (mostly passing)
    final score = 70.0 + Random().nextDouble() * 25;
    final passed = score >= 72;

    widget.session.livenessScore = score;
    widget.session.livenessChallenge = _challenges.join(', ');
    widget.session.livenessPass = passed;

    setState(() {
      _isVerifying = false;
      _verificationDone = true;
      _verificationPassed = passed;
      _livenessScore = score;
    });
    _resultController.forward();
  }

  void _proceed() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => VoiceScreen(session: widget.session),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      title: 'Liveness Detection',
      child:  SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const StepIndicator(currentStep: 2),
            const SizedBox(height: 24),
            const Text(
              'Face Liveness Check',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Anti-spoofing challenge response to confirm live presence.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // Camera viewfinder
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _isVerifying ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 280,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _verificationDone
                            ? (_verificationPassed ? AppTheme.neonGreen : AppTheme.neonRed)
                            : _isVerifying
                                ? AppTheme.neonBlue
                                : AppTheme.cardBorder,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_verificationDone
                                  ? (_verificationPassed ? AppTheme.neonGreen : AppTheme.neonRed)
                                  : AppTheme.neonBlue)
                              .withValues(alpha: _isVerifying ? 0.3 : 0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _buildCameraPreview(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Challenge text
            if (_isVerifying) _ChallengeCard(
              challenge: _currentChallenge,
              countdown: _challengeCountdown,
              step: _challengeStep + 1,
              total: _challenges.length,
            ),
            // Result
            if (_verificationDone)
              ScaleTransition(
                scale: _resultAnim,
                child: _LivenessResultCard(
                  passed: _verificationPassed,
                  score: _livenessScore,
                ),
              ),
            const SizedBox(height: 24),
            if (!_isVerifying && !_verificationDone)
              NeonButton(
                label: 'START LIVENESS VERIFICATION',
                onPressed: _cameraPermitted ? _startLivenessCheck : _requestCameraPermission,
                icon: Icons.face_retouching_natural,
              ),
            if (!_cameraPermitted && !_isVerifying && !_verificationDone)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'Camera permission required. Tap button to grant.',
                    style: TextStyle(color: AppTheme.neonOrange, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (_verificationDone)
              NeonButton(
                label: 'CONTINUE TO VOICE CHECK',
                onPressed: _proceed,
                icon: Icons.arrow_forward,
                color: _verificationPassed ? AppTheme.neonGreen : AppTheme.neonOrange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraInitialized && _cameraController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          // Face oval overlay
          CustomPaint(painter: _FaceOvalPainter(isActive: _isVerifying)),
          // Corner brackets
          const _CornerBrackets(),
        ],
      );
    }
    // Fallback: simulated camera view
    return Container(
      color: const Color(0xFF060E18),
      child: Stack(
        children: [
          CustomPaint(painter: _FaceOvalPainter(isActive: _isVerifying), child: Container()),
          const _CornerBrackets(),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.face_retouching_natural, color: AppTheme.neonBlue, size: 48),
                SizedBox(height: 12),
                Text(
                  'Camera Preview\n(Simulation Mode)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String challenge;
  final int countdown;
  final int step;
  final int total;
  const _ChallengeCard({
    required this.challenge,
    required this.countdown,
    required this.step,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neonBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Challenge $step of $total',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${countdown}s',
                  style: const TextStyle(color: AppTheme.neonBlue, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge,
            style: const TextStyle(
              color: AppTheme.neonBlue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (5 - countdown) / 5,
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonBlue),
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

class _LivenessResultCard extends StatelessWidget {
  final bool passed;
  final double score;
  const _LivenessResultCard({required this.passed, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppTheme.neonGreen : AppTheme.neonRed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(passed ? Icons.check_circle : Icons.cancel, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'LIVENESS CONFIRMED' : 'LIVENESS CHECK FAILED',
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  passed ? 'Live human presence detected.' : 'Possible spoof attempt detected.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }
}

class _FaceOvalPainter extends CustomPainter {
  final bool isActive;
  _FaceOvalPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isActive ? AppTheme.neonBlue : const Color(0xFF1E3A5F)).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 10),
        width: size.width * 0.55,
        height: size.height * 0.65,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter old) => old.isActive != isActive;
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerPainter());
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 20.0;
    // Top-left
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
