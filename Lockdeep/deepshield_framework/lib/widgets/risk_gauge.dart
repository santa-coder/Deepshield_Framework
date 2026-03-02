import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RiskGauge extends StatelessWidget {
  final double riskScore;
  final String decision;

  const RiskGauge({super.key, required this.riskScore, required this.decision});

  Color get _riskColor {
    if (riskScore <= 40) return AppTheme.neonGreen;
    if (riskScore <= 70) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  @override
  Widget build(BuildContext context) {
    final safeScore = riskScore.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _riskColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: _riskColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'RISK ASSESSMENT SCORE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        value: safeScore,
                        color: _riskColor,
                        radius: 30,
                        title: '',
                        borderSide: BorderSide(color: _riskColor.withValues(alpha: 0.5), width: 1),
                      ),
                      PieChartSectionData(
                        value: 100 - safeScore,
                        color: AppTheme.surfaceVariant,
                        radius: 30,
                        title: '',
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      safeScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: _riskColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const Text(
                      'RISK SCORE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _riskColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              decision,
              style: TextStyle(
                color: _riskColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Legend(color: AppTheme.neonGreen, label: '0–40\nGRANTED'),
              _Legend(color: AppTheme.neonOrange, label: '41–70\nOTP REQ.'),
              _Legend(color: AppTheme.neonRed, label: '71+\nDENIED'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
