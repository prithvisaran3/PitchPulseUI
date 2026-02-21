import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class RiskBadge extends StatelessWidget {
  final String band; // LOW | MED | HIGH
  final double? score;
  final bool large;
  final bool pulse;

  const RiskBadge({
    super.key,
    required this.band,
    this.score,
    this.large = false,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.gradientForRisk(band);
    final isHigh = band.toUpperCase() == 'HIGH';
    final label = score != null ? score!.toInt().toString() : band;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        boxShadow: isHigh
            ? [
                BoxShadow(
                  color: AppColors.riskHigh.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        score != null ? '$label  $band' : band,
        style: (large ? AppTextStyles.labelLarge : AppTextStyles.labelSmall).copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (pulse && isHigh) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.05, duration: 800.ms, curve: Curves.easeInOut);
    }

    return badge;
  }
}

class ReadinessBadge extends StatelessWidget {
  final double score; // 0-100
  final String? band;
  final bool small;

  const ReadinessBadge({
    super.key,
    required this.score,
    this.band,
    this.small = false,
  });

  LinearGradient get _gradient {
    if (score >= 70) return AppColors.gradientLow;
    if (score >= 45) return AppColors.gradientMed;
    return AppColors.gradientHigh;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      ),
      child: Text(
        '${score.toInt()}% ready',
        style: (small ? AppTextStyles.caption : AppTextStyles.labelSmall).copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status; // NS | LIVE | FT
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'LIVE': return AppColors.live;
      case 'FT': return AppColors.finished;
      case 'NS': return AppColors.notStarted;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = status == 'LIVE';
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: AppTextStyles.labelSmall.copyWith(color: _color),
          ),
        ],
      ),
    );

    if (isLive) {
      chip = chip
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 600.ms);
    }

    return chip;
  }
}
