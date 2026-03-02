import 'package:flutter/material.dart';
import '../models/auth_session.dart';
import '../services/device_service.dart';
import '../services/risk_engine.dart';
import '../utils/app_theme.dart';
import '../widgets/neon_button.dart';
//import '../widgets/cyber_scaffold.dart';
import '../widgets/step_indicator.dart';
import 'dashboard_screen.dart';

class DeviceRiskScreen extends StatefulWidget {
  final AuthSession session;
  const DeviceRiskScreen({super.key, required this.session});

  @override
  State<DeviceRiskScreen> createState() => _DeviceRiskScreenState();
}

class _DeviceRiskScreenState extends State<DeviceRiskScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _done = false;

  late AnimationController _loadController;
  late AnimationController _resultController;
  late Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();
    _loadController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _resultAnim = CurvedAnimation(parent: _resultController, curve: Curves.easeOut);
    _runScan();
  }

  @override
  void dispose() {
    _loadController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final deviceData = await DeviceService.getDeviceInfo();
    final locationData = await DeviceService.getLocationInfo();

    final tempSession = AuthSession(
      livenessScore: widget.session.livenessScore,
      behaviorScore: widget.session.behaviorScore,
      voiceScore: widget.session.voiceScore,
      deviceRisk: deviceData['deviceRisk'] as double,
      locationRisk: locationData['locationRisk'] as double,
    );

    final result = RiskEngine.calculate(tempSession);

    widget.session.deviceModel = deviceData['model'] as String;
    widget.session.deviceId = deviceData['deviceId'] as String;
    widget.session.isNewDevice = deviceData['isNewDevice'] as bool;
    widget.session.deviceRisk = deviceData['deviceRisk'] as double;
    widget.session.latitude = locationData['latitude'] as double;
    widget.session.longitude = locationData['longitude'] as double;
    widget.session.distanceFromPrevKm = locationData['distanceKm'] as double;
    widget.session.locationRisk = locationData['locationRisk'] as double;
    widget.session.finalRiskScore = result.finalScore;
    widget.session.decision = result.decisionLabel;

    if (mounted) {
      setState(() => _loading = false);
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _done = true);
      _resultController.forward();
    }
  }

  void _proceed() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DashboardScreen(session: widget.session),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Device & Location Risk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const StepIndicator(currentStep: 4),
            const SizedBox(height: 24),
            const Text(
              'Environment Risk Analysis',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Evaluating device fingerprint, network, and geolocation risk signals.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            if (_loading) _ScanningAnimation(controller: _loadController),
            if (_done)
              FadeTransition(
                opacity: _resultAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeviceInfoCard(session: widget.session),
                    const SizedBox(height: 16),
                    _LocationInfoCard(session: widget.session),
                    const SizedBox(height: 16),
                    _RiskSummaryCard(session: widget.session),
                    const SizedBox(height: 32),
                    NeonButton(
                      label: 'VIEW FULL RISK DASHBOARD',
                      onPressed: _proceed,
                      icon: Icons.dashboard,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanningAnimation extends StatelessWidget {
  final AnimationController controller;
  const _ScanningAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3)),
                  ),
                ),
                Transform.rotate(
                  angle: controller.value * 2 * 3.14159,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [AppTheme.neonBlue, Colors.transparent],
                        stops: [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.sensors, color: AppTheme.neonBlue, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('SCANNING ENVIRONMENT',
              style: TextStyle(color: AppTheme.neonBlue, fontSize: 13, letterSpacing: 3)),
          const SizedBox(height: 8),
          const Text('Checking device fingerprint & geolocation...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final AuthSession session;
  const _DeviceInfoCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isNew = session.isNewDevice;
    final color = isNew ? AppTheme.neonOrange : AppTheme.neonGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: color, size: 18),
              const SizedBox(width: 8),
              const Text('DEVICE FINGERPRINT',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(isNew ? 'NEW DEVICE' : 'TRUSTED',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Device Model', value: session.deviceModel.isEmpty ? 'Unknown' : session.deviceModel),
          const SizedBox(height: 6),
          _InfoRow(
              label: 'Device ID',
              value: session.deviceId.length > 20
                  ? '${session.deviceId.substring(0, 20)}...'
                  : session.deviceId),
          const SizedBox(height: 6),
          _InfoRow(label: 'Risk Score', value: '${session.deviceRisk.toStringAsFixed(0)} / 100'),
        ],
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  final AuthSession session;
  const _LocationInfoCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isAnomaly = session.locationRisk > 50;
    final color = isAnomaly ? AppTheme.neonRed : AppTheme.neonGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: color, size: 18),
              const SizedBox(width: 8),
              const Text('GEOLOCATION ANALYSIS',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(isAnomaly ? 'ANOMALY' : 'NORMAL',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Current Location',
              value: '${session.latitude.toStringAsFixed(4)}, ${session.longitude.toStringAsFixed(4)}'),
          const SizedBox(height: 6),
          const _InfoRow(label: 'Previous Location', value: '40.7128, -74.0060 (New York, US)'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Distance Traveled', value: '${session.distanceFromPrevKm.toStringAsFixed(0)} km'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Location Risk', value: '${session.locationRisk.toStringAsFixed(0)} / 100'),
        ],
      ),
    );
  }
}

class _RiskSummaryCard extends StatelessWidget {
  final AuthSession session;
  const _RiskSummaryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.neonBlue.withValues(alpha: 0.1), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.neonBlue, size: 18),
              SizedBox(width: 8),
              Text('COMPOSITE RISK PREVIEW',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _MiniScore(label: 'Liveness', value: session.livenessScore, invert: false)),
              Expanded(child: _MiniScore(label: 'Behavior', value: session.behaviorScore, invert: false)),
              Expanded(child: _MiniScore(label: 'Voice', value: session.voiceScore, invert: true)),
              Expanded(child: _MiniScore(label: 'Device', value: session.deviceRisk, invert: true)),
              Expanded(child: _MiniScore(label: 'Location', value: session.locationRisk, invert: true)),
            ],
          ),
          const Divider(color: AppTheme.divider, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Risk Score',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                session.finalRiskScore.toStringAsFixed(1),
                style: TextStyle(
                  color: session.finalRiskScore <= 40
                      ? AppTheme.neonGreen
                      : session.finalRiskScore <= 70
                          ? AppTheme.neonOrange
                          : AppTheme.neonRed,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final double value;
  final bool invert;
  const _MiniScore({required this.label, required this.value, required this.invert});

  Color get _color {
    final risk = invert ? value : 100 - value;
    if (risk < 40) return AppTheme.neonGreen;
    if (risk < 70) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toStringAsFixed(0),
            style: TextStyle(color: _color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
