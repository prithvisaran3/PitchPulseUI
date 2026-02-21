import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/home/player_risk_tile.dart';
import 'player_check_in_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    final squad = workspace.squad;
    final isLoading = workspace.homeState == LoadState.loading;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            expandedHeight: 60,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Row(
                children: [
                  Text(
                    'Check-In',
                    style: AppTextStyles.headlineLarge,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select a player',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          isLoading
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const ShimmerPlayerTile(),
                      childCount: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingM,
                    20,
                    AppConstants.spacingM,
                    AppConstants.spacingXXL,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final player = squad[i];
                        return PlayerRiskTile(
                          player: player,
                          animationIndex: i,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              ctx,
                              PageRouteBuilder(
                                pageBuilder: (_, anim, __) =>
                                    PlayerCheckInScreen(player: player),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0.05, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ),
                                transitionDuration:
                                    const Duration(milliseconds: 350),
                              ),
                            );
                          },
                        );
                      },
                      childCount: squad.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
