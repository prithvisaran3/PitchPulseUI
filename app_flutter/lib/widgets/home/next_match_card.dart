import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fixture_model.dart';
import '../common/gradient_badge.dart';

class NextMatchCard extends StatefulWidget {
  final FixtureModel fixture;

  const NextMatchCard({super.key, required this.fixture});

  @override
  State<NextMatchCard> createState() => _NextMatchCardState();
}

class _NextMatchCardState extends State<NextMatchCard> with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _ringController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ringController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return widget.fixture.isLive ? 'LIVE' : 'FT';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    final countdown = f.timeUntilKickoff;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1A35), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background animated ring
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) => CustomPaint(
                painter: _RingPainter(_ringController.value),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEXT MATCH', style: AppTextStyles.caption.copyWith(
                          letterSpacing: 2,
                          color: AppColors.accent,
                        )),
                        const SizedBox(height: 2),
                        Text(f.competition, style: AppTextStyles.bodySmall),
                      ],
                    ),
                    StatusChip(status: f.status),
                  ],
                ),

                const SizedBox(height: 20),

                // Teams + Score
                Row(
                  children: [
                    Expanded(
                      child: _TeamSection(name: f.homeTeam, isHome: true),
                    ),

                    // Score or VS
                    Container(
                      width: 72,
                      child: f.isLive || f.isFinished
                          ? _ScoreDisplay(
                              home: f.homeScore ?? 0,
                              away: f.awayScore ?? 0,
                              isLive: f.isLive,
                              glowAnim: _glowController,
                            )
                          : Text(
                              'VS',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),

                    Expanded(
                      child: _TeamSection(name: f.awayTeam, isHome: false),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Bottom: venue + countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(f.venue, style: AppTextStyles.bodySmall),
                      ],
                    ),
                    if (!f.isFinished)
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1 + _glowController.value * 0.08),
                            borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3 + _glowController.value * 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 11, color: AppColors.accent),
                              const SizedBox(width: 5),
                              Text(
                                _formatCountdown(countdown),
                                style: AppTextStyles.monoSmall.copyWith(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.elasticOut);
  }
}

class _TeamSection extends StatelessWidget {
  final String name;
  final bool isHome;

  const _TeamSection({required this.name, required this.isHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Crest placeholder
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceElevated,
            border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
          ),
          child: Center(
            child: Text(
              name.substring(0, 2).toUpperCase(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium,
        ),
        if (isHome)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('HOME', style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
          ),
      ],
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final int home;
  final int away;
  final bool isLive;
  final AnimationController glowAnim;

  const _ScoreDisplay({
    required this.home,
    required this.away,
    required this.isLive,
    required this.glowAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, __) => Column(
        children: [
          Text(
            '$home - $away',
            textAlign: TextAlign.center,
            style: AppTextStyles.monoLarge.copyWith(
              color: isLive
                  ? Color.lerp(AppColors.live, AppColors.accentEnd, glowAnim.value)!
                  : AppColors.textPrimary,
            ),
          ),
          if (isLive)
            Text('LIVE', style: AppTextStyles.caption.copyWith(
              color: AppColors.live,
              letterSpacing: 2,
            )),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.8;

    for (int i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1.0 - phase) * 0.06;
      final paint = Paint()
        ..color = AppColors.accent.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
