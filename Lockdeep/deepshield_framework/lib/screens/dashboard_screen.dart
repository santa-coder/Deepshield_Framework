import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/auth_session.dart';
import '../models/risk_result.dart';
import '../services/risk_engine.dart';
import '../utils/app_theme.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/score_card.dart';
import '../widgets/cyber_scaffold.dart';
import '../widgets/neon_button.dart';
import 'landing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.session});

  final AuthSession session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late Animation<double> _entranceAnim;
  late AnimationController _entranceController;
  late List<_LoginEntry> _mockHistory;
  late RiskResult _riskResult;

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _riskResult = RiskEngine.calculate(widget.session);
    // Update session with final result
    widget.session.finalRiskScore = _riskResult.finalScore;
    widget.session.decision = _riskResult.decisionLabel;

    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _entranceAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _entranceController.forward();

    _mockHistory = _generateMockHistory();
  }

  List<_LoginEntry> _generateMockHistory() {
    final rng = Random();
    final now = DateTime.now();
    return List.generate(8, (i) {
      final daysAgo = rng.nextInt(30);
      final hoursAgo = rng.nextInt(24);
      final date = now.subtract(Duration(days: daysAgo, hours: hoursAgo));
      final score = rng.nextInt(80).toDouble();
      final decisions = ['Granted', 'OTP Required', 'Denied'];
      final weights = [0.6, 0.3, 0.1];
      final rand = rng.nextDouble();
     String decision;

if (rand < weights[0]) {
  decision = decisions[0];
} else if (rand < weights[0] + weights[1]) {
  decision = decisions[1];
} else {
  decision = decisions[2];
}

      final locations = ['New York, US', 'London, UK', 'Mumbai, IN', 'Singapore', 'Toronto, CA', 'Sydney, AU'];
      return _LoginEntry(
        date: date,
        riskScore: score,
        decision: decision,
        location: locations[rng.nextInt(locations.length)],
        device: i == 0 ? widget.session.deviceModel : 'Recognized Device',
      );
    })
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Color get _decisionColor {
    switch (_riskResult.decision) {
      case RiskDecision.granted: return AppTheme.neonGreen;
      case RiskDecision.otpRequired: return AppTheme.neonOrange;
      case RiskDecision.denied: return AppTheme.neonRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberScaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.neonBlue, size: 18),
            SizedBox(width: 8),
            Text('DEEPSHIELD', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonBlue),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const LandingScreen(),
                  transitionDuration: const Duration(milliseconds: 500),
                  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                ),
                (r) => false,
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      child: FadeTransition(
        opacity: _entranceAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decision banner
              _DecisionBanner(result: _riskResult, color: _decisionColor, session: widget.session),
              const SizedBox(height: 24),
              // Risk gauge
              RiskGauge(
                riskScore: _riskResult.finalScore,
                decision: _riskResult.decisionLabel,
              ),
              const SizedBox(height: 24),
              // Score cards grid
              const _SectionHeader(title: 'Biometric Signal Breakdown'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  ScoreCard(
                    title: 'FACE LIVENESS',
                    value: '${widget.session.livenessScore.toStringAsFixed(0)}%',
                    subtitle: widget.session.livenessPass ? 'Pass – Live human confirmed' : 'Suspicious',
                    statusColor: widget.session.livenessScore > 70 ? AppTheme.neonGreen : AppTheme.neonRed,
                    icon: Icons.face_retouching_natural,
                  ),
                  ScoreCard(
                    title: 'BEHAVIORAL',
                    value: '${widget.session.behaviorScore.toStringAsFixed(0)}%',
                    subtitle: 'Keystroke rhythm score',
                    statusColor: widget.session.behaviorScore > 60 ? AppTheme.neonGreen : AppTheme.neonOrange,
                    icon: Icons.keyboard,
                  ),
                  ScoreCard(
                    title: 'VOICE SPOOF',
                    value: widget.session.voiceScore.toStringAsFixed(0),
                    subtitle: widget.session.voiceResult.isEmpty ? 'Not analyzed' : widget.session.voiceResult,
                    statusColor: widget.session.voiceScore < 35 ? AppTheme.neonGreen : widget.session.voiceScore < 65 ? AppTheme.neonOrange : AppTheme.neonRed,
                    icon: Icons.mic,
                  ),
                  ScoreCard(
                    title: 'DEVICE TRUST',
                    value: widget.session.isNewDevice ? 'NEW' : 'OK',
                    subtitle: widget.session.deviceModel.isEmpty ? 'Unknown' : widget.session.deviceModel,
                    statusColor: widget.session.isNewDevice ? AppTheme.neonOrange : AppTheme.neonGreen,
                    icon: Icons.phone_android,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Location card
              const _SectionHeader(title: 'Location Analysis'),
              const SizedBox(height: 12),
              _LocationCard(session: widget.session),
              const SizedBox(height: 24),
              // Risk breakdown bar chart
              const _SectionHeader(title: 'Risk Component Weights'),
              const SizedBox(height: 12),
              _RiskBreakdownBars(breakdown: _riskResult.breakdown),
              const SizedBox(height: 24),
              // Login history
              const _SectionHeader(title: 'Login History'),
              const SizedBox(height: 12),
              _LoginHistoryList(entries: _mockHistory),
              const SizedBox(height: 32),
              // Re-authenticate button
              NeonButton(
                label: 'START NEW AUTH SESSION',
                color: AppTheme.neonBlue,
                icon: Icons.lock_reset,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LandingScreen(),
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                    ),
                    (r) => false,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionBanner extends StatelessWidget {
  const _DecisionBanner({required this.result, required this.color, required this.session});

  final Color color;
  final RiskResult result;
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  result.decision == RiskDecision.granted
                      ? Icons.check_circle
                      : result.decision == RiskDecision.otpRequired
                          ? Icons.sms
                          : Icons.block,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.decisionLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.decisionDescription,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BannerMeta(
                  label: 'Session ID',
                  value: '#DS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                ),
              ),
              Expanded(
                child: _BannerMeta(
                  label: 'Auth Time',
                  value: DateFormat('HH:mm:ss').format(session.timestamp),
                ),
              ),
              Expanded(
                child: _BannerMeta(
                  label: 'Duration',
                  value: '${(session.loginDurationMs / 1000).toStringAsFixed(1)}s',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerMeta extends StatelessWidget {
  const _BannerMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Courier')),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.neonBlue),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.session});

  final AuthSession session;

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnomaly ? 'LOCATION ANOMALY DETECTED' : 'LOCATION NORMAL',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.latitude.toStringAsFixed(3)}, ${session.longitude.toStringAsFixed(3)}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontFamily: 'Courier'),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.distanceFromPrevKm.toStringAsFixed(0)} km from last login',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                session.locationRisk.toStringAsFixed(0),
                style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
              ),
              const Text('risk', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskBreakdownBars extends StatelessWidget {
  const _RiskBreakdownBars({required this.breakdown});

  final Map<String, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final labels = {
      'liveness': 'Liveness (25%)',
      'behavior': 'Behavior (20%)',
      'voice': 'Voice (20%)',
      'device': 'Device (15%)',
      'location': 'Location (20%)',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: breakdown.entries.map((entry) {
          final maxVal = entry.key == 'liveness' || entry.key == 'behavior' ? 25.0 : 20.0;
          final pct = (entry.value / maxVal).clamp(0.0, 1.0);
          final color = pct < 0.4 ? AppTheme.neonGreen : pct < 0.7 ? AppTheme.neonOrange : AppTheme.neonRed;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(labels[entry.key] ?? entry.key, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(entry.value.toStringAsFixed(1), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LoginHistoryList extends StatelessWidget {
  const _LoginHistoryList({required this.entries});

  final List<_LoginEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          return Column(
            children: [
              _LoginHistoryItem(entry: entry, isFirst: i == 0),
              if (i < entries.length - 1)
                const Divider(color: AppTheme.divider, height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _LoginHistoryItem extends StatelessWidget {
  const _LoginHistoryItem({required this.entry, required this.isFirst});

  final _LoginEntry entry;
  final bool isFirst;

  Color get _decisionColor {
    switch (entry.decision) {
      case 'Granted': return AppTheme.neonGreen;
      case 'OTP Required': return AppTheme.neonOrange;
      default: return AppTheme.neonRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _decisionColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.decision == 'Granted' ? Icons.check : entry.decision == 'OTP Required' ? Icons.sms : Icons.block,
              color: _decisionColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.decision,
                      style: TextStyle(color: _decisionColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.neonBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('CURRENT', style: TextStyle(color: AppTheme.neonBlue, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.location} · ${entry.device}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM d, HH:mm').format(entry.date),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                'Score: ${entry.riskScore.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Courier'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginEntry {
  _LoginEntry({
    required this.date,
    required this.riskScore,
    required this.decision,
    required this.location,
    required this.device,
  });

  final DateTime date;
  final String decision;
  final String device;
  final String location;
  final double riskScore;
}
