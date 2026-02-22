import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
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
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final isHigh = p.riskBand.toUpperCase() == 'HIGH';
    final riskColor = AppColors.colorForRisk(p.riskBand);

    return AnimatedBuilder(
      animation: _pressController,
      builder: (_, child) => Transform.scale(
        scale: _pressScale.value,
        child: child,
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
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.8),
                AppColors.surface.withValues(alpha: 0.4),
              ],
            ),
            border: Border.all(
              color: riskColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              if (isHigh)
                BoxShadow(
                  color: riskColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Stack(
                children: [
                  // Subtle glow in the background of the card
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: riskColor.withValues(alpha: 0.15),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top: position & readiness
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.position,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: riskColor,
                                  letterSpacing: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.surfaceBorder
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      size: 12, color: AppColors.textPrimary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p.readinessScore}%',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Name
                        Text(
                          p.name,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),

                        // Sparkline
                        if (p.riskSparkline.isNotEmpty)
                          SizedBox(
                            height: 36,
                            child: CustomPaint(
                              painter: _SparklinePainter(
                                data: p.riskSparkline,
                                color: riskColor,
                              ),
                              size: const Size(double.infinity, 36),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Bottom row: Risk Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Risk Level', style: AppTextStyles.caption),
                            RiskBadge(
                              band: p.riskBand,
                              score: p.riskScore,
                              pulse: isHigh,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.animationIndex * 60))
        .fadeIn(duration: 600.ms, curve: Curves.easeOutExpo)
        .slideY(
            begin: 0.15, end: 0, duration: 600.ms, curve: Curves.easeOutExpo);
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
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final step = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      // Invert Y so higher risk is higher up
      final y = size.height - ((data[i] - min) / range) * size.height;

      // Add slight curve smoothing
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

    // Last dot indicator
    final lastX = (data.length - 1) * step;
    final lastY = size.height - ((data.last - min) / range) * size.height;

    canvas.drawCircle(
        Offset(lastX, lastY),
        4,
        Paint()
          ..color = AppColors.surface
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(lastX, lastY),
        3.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}
