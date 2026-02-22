import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/player_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlayerXIBottomSheet extends StatelessWidget {
  final PlayerModel player;
  final String? aiRationale;

  const PlayerXIBottomSheet(
      {super.key, required this.player, this.aiRationale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: player.photoUrl == null
                        ? AppColors.gradientForRisk(player.riskBand)
                        : null,
                  ),
                  child: ClipOval(
                    child: player.photoUrl != null
                        ? Image.network(
                            player.photoUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                player.jerseyNumber?.toString() ?? '?',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              player.jerseyNumber?.toString() ?? '?',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: AppTextStyles.headlineSmall),
                      Text(player.position,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.surfaceBorder),
            const SizedBox(height: 16),

            // Why Selected Section
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 8),
                Text('AI Selection Rationale',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              aiRationale ??
                  "Based on past form, ${player.name} is heavily recommended to start. Their readiness is at ${player.readinessScore.toInt()}%, and despite recent ${player.topDrivers.isNotEmpty ? player.topDrivers.first.toLowerCase() : 'workloads'}, their injury risk logic dictates they are cleared for the ${player.riskBand} band.",
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),

            _buildRationaleRow(
              'Match Readiness',
              '${player.readinessScore.toInt()}%',
              AppColors.readinessPink,
              player.readinessScore >= 80
                  ? AppColors.readinessGreen
                  : (player.readinessScore >= 50
                      ? AppColors.readinessAmber
                      : AppColors.readinessPink),
            ),
            const SizedBox(height: 12),
            _buildRationaleRow(
              'Form & Fatigue',
              player.topDrivers.isNotEmpty
                  ? player.topDrivers.first
                  : 'Stable load metrics',
              AppColors.textSecondary,
              AppColors.textPrimary,
            ),
            const SizedBox(height: 12),
            _buildRationaleRow(
              'Injury Risk',
              '${player.riskBand} (${player.riskScore.toInt()})',
              AppColors.surfaceBorder,
              AppColors.colorForRisk(player.riskBand),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Close',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Action to swap out
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Swap Player',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(
        begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildRationaleRow(
      String title, String value, Color iconColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        Text(value,
            style: AppTextStyles.labelMedium.copyWith(color: valueColor)),
      ],
    );
  }
}
