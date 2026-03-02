import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/auth_session.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/cyber_scaffold.dart';
import '../widgets/step_indicator.dart';
import 'device_risk_screen.dart';

class VoiceScreen extends StatefulWidget {
  final AuthSession session;
  const VoiceScreen({super.key, required this.session});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with TickerProviderStateMixin {
  bool _micPermitted = false;
  bool _isRecording = false;
  bool _analysisComplete = false;
  double _recordingProgress = 0;
  double _voiceScore = 0;
  String _voiceResult = '';
  int _recordingSeconds = 0;
  Timer? _recordTimer;

  late AnimationController _waveController;
  late AnimationController _resultController;
  late Animation<double> _waveAnim;
  late Animation<double> _resultAnim;

  final List<double> _waveAmplitudes = List.generate(20, (i) => 0.2);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _waveAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _resultAnim = CurvedAnimation(parent: _resultController, curve: Curves.elasticOut);
    _requestMicPermission();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _resultController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    setState(() => _micPermitted = status.isGranted);
  }

  void _startRecording() {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
      _recordingProgress = 0;
      _recordingSeconds = 0;
    });

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingProgress += 1 / 50; // 5 seconds = 50 ticks
        _recordingSeconds = (_recordingProgress * 5).toInt();

        // Animate wave amplitudes
        final rng = Random();
        _waveAmplitudes.asMap().forEach((i, _) {
          _waveAmplitudes[i] = 0.1 + rng.nextDouble() * 0.9;
        });

        if (_recordingProgress >= 1.0) {
          timer.cancel();
          _analyzeVoice();
        }
      });
    });
  }

  void _analyzeVoice() async {
    setState(() {
      _isRecording = false;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    // Simulate voice anti-spoof scoring
    final rng = Random();
    final scenario = rng.nextDouble();
    double score;
    String result;

    if (scenario < 0.65) {
      // Human voice (most likely)
      score = 5 + rng.nextDouble() * 30;
      result = 'HUMAN VOICE LIKELY';
    } else if (scenario < 0.85) {
      // Suspicious
      score = 35 + rng.nextDouble() * 30;
      result = 'SUSPICIOUS VOICE PATTERN';
    } else {
      // AI-generated
      score = 70 + rng.nextDouble() * 30;
      result = 'AI-GENERATED VOICE LIKELY';
    }

    widget.session.voiceScore = score;
    widget.session.voiceResult = result;

    if (mounted) {
      setState(() {
        _voiceScore = score;
        _voiceResult = result;
        _analysisComplete = true;
      });
      _resultController.forward();
    }
  }

  Color get _scoreColor {
    if (_voiceScore < 35) return AppTheme.neonGreen;
    if (_voiceScore < 65) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  void _proceed() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DeviceRiskScreen(session: widget.session),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      title: 'Voice Anti-Spoof',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const StepIndicator(currentStep: 3),
            const SizedBox(height: 24),
            const Text(
              'Voice Authenticity Check',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI-powered voice analysis to detect synthetic or replayed audio.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            // Instruction card
            _PassphraseCard(),
            const SizedBox(height: 32),
            // Recording visualizer
            Center(
              child: _VoiceVisualizer(
                isRecording: _isRecording,
                amplitudes: _waveAmplitudes,
                waveAnimation: _waveAnim,
                progress: _recordingProgress,
                seconds: _recordingSeconds,
                analysisComplete: _analysisComplete,
              ),
            ),
            const SizedBox(height: 32),
            // Result card
            if (_analysisComplete)
              ScaleTransition(
                scale: _resultAnim,
                child: _VoiceResultCard(
                  score: _voiceScore,
                  result: _voiceResult,
                  color: _scoreColor,
                ),
              ),
            const SizedBox(height: 24),
            if (!_isRecording && !_analysisComplete)
              NeonButton(
                label: _micPermitted ? 'START VOICE RECORDING (5s)' : 'GRANT MICROPHONE PERMISSION',
                onPressed: _micPermitted ? _startRecording : _requestMicPermission,
                icon: Icons.mic,
              ),
            if (!_micPermitted)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'Microphone access required for voice analysis.',
                    style: TextStyle(color: AppTheme.neonOrange, fontSize: 12),
                  ),
                ),
              ),
            if (_analysisComplete)
              NeonButton(
                label: 'CONTINUE TO DEVICE CHECK',
                onPressed: _proceed,
                icon: Icons.arrow_forward,
                color: AppTheme.neonBlue,
              ),
          ],
        ),
      ),
    );
  }
}

class _PassphraseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: AppTheme.neonBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'READ THE PASSPHRASE ALOUD',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.5),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"My voice is my passport,\n verify me."',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Speak clearly at a normal pace. Background noise will be filtered.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VoiceVisualizer extends StatelessWidget {
  final bool isRecording;
  final List<double> amplitudes;
  final Animation<double> waveAnimation;
  final double progress;
  final int seconds;
  final bool analysisComplete;

  const _VoiceVisualizer({
    required this.isRecording,
    required this.amplitudes,
    required this.waveAnimation,
    required this.progress,
    required this.seconds,
    required this.analysisComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecording ? AppTheme.neonBlue.withValues(alpha: 0.5) : AppTheme.cardBorder,
        ),
        boxShadow: isRecording
            ? [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          if (!analysisComplete)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecording) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.neonRed, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'REC  ${seconds}s / 5s',
                    style: const TextStyle(color: AppTheme.neonRed, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ] else
                  const Text(
                    'READY TO RECORD',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1),
                  ),
              ],
            ),
          if (analysisComplete)
            const Text('ANALYZING...', style: TextStyle(color: AppTheme.neonBlue, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(20, (i) {
                final amp = isRecording ? amplitudes[i] : 0.1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 8,
                  height: 80 * amp,
                  decoration: BoxDecoration(
                    color: isRecording
                        ? AppTheme.neonBlue.withValues(alpha: 0.5 + amp * 0.5)
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              isRecording ? AppTheme.neonBlue : AppTheme.cardBorder,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

class _VoiceResultCard extends StatelessWidget {
  final double score;
  final String result;
  final Color color;
  const _VoiceResultCard({required this.score, required this.result, required this.color});

  IconData get _icon {
    if (score < 35) return Icons.verified_user;
    if (score < 65) return Icons.warning_amber;
    return Icons.dangerous;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            child: Icon(_icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  score < 35
                      ? 'Natural speech patterns confirmed.'
                      : score < 65
                          ? 'Unusual phonetic markers detected.'
                          : 'GAN or TTS signatures identified.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
              ),
              const Text('/ 100', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
