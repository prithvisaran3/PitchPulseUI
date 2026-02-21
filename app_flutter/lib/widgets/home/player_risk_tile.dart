import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/player_model.dart';
import '../common/gradient_badge.dart';

class PlayerRiskTile extends StatefulWidget {
  final PlayerModel player;
  final VoidCallback onTap;
  final int animationIndex;

  const PlayerRiskTile({
    super.key,
    required this.player,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  State<PlayerRiskTile> createState() => _PlayerRiskTileState();
}

class _PlayerRiskTileState extends State<PlayerRiskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;
  late Animation<double> _tiltX;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _tiltX = Tween<double>(begin: 0, end: 0.03).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.player.riskBand.toUpperCase()) {
      case 'HIGH':
        return AppColors.riskHigh.withValues(alpha: 0.5);
      case 'MED':
        return AppColors.riskMed.withValues(alpha: 0.4);
      default:
        return AppColors.surfaceBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final isHigh = p.riskBand.toUpperCase() == 'HIGH';

    return AnimatedBuilder(
      animation: _pressController,
      builder: (_, child) => Transform.scale(
        scale: _pressScale.value,
        child: Transform(
          transform: Matrix4.identity()..rotateX(_tiltX.value),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: isHigh
                ? [
                    BoxShadow(
                      color: AppColors.riskHigh.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: jersey + position
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientForRisk(p.riskBand),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        p.jerseyNumber?.toString() ?? '?',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    p.position,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Name
              Text(
                p.name,
                style: AppTextStyles.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Sparkline
              if (p.riskSparkline.isNotEmpty)
                SizedBox(
                  height: 28,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      data: p.riskSparkline,
                      color: AppColors.colorForRisk(p.riskBand),
                    ),
                    size: const Size(double.infinity, 28),
                  ),
                ),

              const Spacer(),
              const SizedBox(height: 8),

              // Readiness (Prioritized)
              ReadinessBadge(score: p.readinessScore, small: true),

              const SizedBox(height: 5),

              // Risk badge
              RiskBadge(
                band: p.riskBand,
                score: p.riskScore,
                pulse: isHigh,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.animationIndex * 60))
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.elasticOut);
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).clamp(1.0, double.infinity);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final step = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((data[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Last dot
    final lastX = (data.length - 1) * step;
    final lastY = size.height - ((data.last - min) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}
