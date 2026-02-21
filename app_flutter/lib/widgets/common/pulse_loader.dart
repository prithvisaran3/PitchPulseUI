import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';

/// A stunning, branded loader that pulses like a heartbeat.
/// Replace generic CircularProgressIndicators with this across the app.
class PulseLoader extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const PulseLoader({
    super.key,
    this.message,
    this.color,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.accent;

    final Widget pulse = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: activeColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.5),
                blurRadius: size * 0.25,
                spreadRadius: size * 0.05,
              )
            ],
          ),
          child: Icon(
            Icons.monitor_heart_rounded,
            color: Colors.white,
            size: size * 0.2,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.8, 0.8),
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          color: activeColor.withValues(alpha: 0.5),
          duration: 1600.ms,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 1600.ms,
          curve: Curves.easeInOutSine,
        );

    if (message == null) {
      return Center(child: pulse);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pulse,
          const SizedBox(height: 24),
          Text(
            message!,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(
                duration: 800.ms,
                curve: Curves.easeIn,
              )
              .then()
              .fadeOut(
                duration: 800.ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}
