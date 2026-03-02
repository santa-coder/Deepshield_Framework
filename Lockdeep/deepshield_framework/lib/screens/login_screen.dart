import 'package:flutter/material.dart';
import '../models/auth_session.dart';
import '../services/risk_engine.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/cyber_scaffold.dart';
import 'liveness_screen.dart';
import '../widgets/step_indicator.dart';

class LoginScreen extends StatefulWidget {
  final AuthSession session;
  const LoginScreen({super.key, required this.session});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _loginStartTime;
  DateTime? _firstKeystrokeTime;
  final List<int> _interKeystrokeIntervals = [];
  DateTime? _lastKeyTime;
  int _totalKeystrokes = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _loginStartTime = DateTime.now();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyEvent() {
    final now = DateTime.now();
    _firstKeystrokeTime ??= now;

    if (_lastKeyTime != null) {
      _interKeystrokeIntervals.add(now.difference(_lastKeyTime!).inMilliseconds);
    }
    _lastKeyTime = now;
    _totalKeystrokes++;
  }

  void _proceed() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    final endTime = DateTime.now();
    final durationMs = endTime.difference(_loginStartTime!).inMilliseconds;

    final behaviorScore = RiskEngine.calculateBehaviorScore(
      totalDurationMs: durationMs,
      keystrokes: _totalKeystrokes,
      interKeystrokeIntervals: _interKeystrokeIntervals,
    );

    await Future.delayed(const Duration(milliseconds: 800));

    widget.session.behaviorScore = behaviorScore;
    widget.session.loginDurationMs = durationMs;
    widget.session.typingSpeed = _totalKeystrokes / (durationMs / 1000);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LivenessScreen(session: widget.session),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      title: 'Identity Verification',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Step indicator
              const StepIndicator(currentStep: 1),
              const SizedBox(height: 32),
              const Text(
                'Sign In',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Behavioral biometrics are being captured during login.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Behavior capture indicator
              _BehaviorCaptureBanner(keystrokes: _totalKeystrokes),
              const SizedBox(height: 24),
              // Username field
              
              const SizedBox(height: 8),
              TextFormField(
                controller: _userCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. john.doe@corp.com',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: (_) => _onKeyEvent(),
                validator: (v) => (v == null || v.isEmpty) ? 'Username required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (_) => _onKeyEvent(),
                validator: (v) => (v == null || v.length < 4) ? 'Min 4 characters' : null,
              ),
              const SizedBox(height: 32),
              // Behavioral metrics preview
              _BehaviorMetricsCard(
                keystrokes: _totalKeystrokes,
                duration: _loginStartTime == null ? 0 : DateTime.now().difference(_loginStartTime!).inMilliseconds,
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnimation.value * (_shakeController.value < 0.5 ? 1 : -1), 0),
                  child: child,
                ),
                child: NeonButton(
                  label: 'CONTINUE TO LIVENESS CHECK',
                  onPressed: _proceed,
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '🔐  End-to-end encrypted  ·  Zero knowledge proof',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BehaviorCaptureBanner extends StatelessWidget {
  final int keystrokes;
  const _BehaviorCaptureBanner({required this.keystrokes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neonBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppTheme.neonBlue, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'BEHAVIORAL BIOMETRICS ACTIVE — capturing keystroke dynamics',
              style: TextStyle(color: AppTheme.neonBlue, fontSize: 11, letterSpacing: 0.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$keystrokes keys',
              style: const TextStyle(color: AppTheme.neonBlue, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviorMetricsCard extends StatelessWidget {
  final int keystrokes;
  final int duration;
  const _BehaviorMetricsCard({required this.keystrokes, required this.duration});

  @override
  Widget build(BuildContext context) {
    final durationSec = duration / 1000;
    final speed = durationSec > 0 ? keystrokes / durationSec : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Behavioral Metrics',
           style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
           ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetricItem(label: 'Keystrokes', value: '$keystrokes')),
              Expanded(child: _MetricItem(label: 'Duration', value: '${durationSec.toStringAsFixed(1)}s')),
              Expanded(child: _MetricItem(label: 'Typing Rate', value: '${speed.toStringAsFixed(1)}/s')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.neonBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }
}
