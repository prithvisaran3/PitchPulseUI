import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/player_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/home/next_match_card.dart';
import '../../widgets/home/player_risk_tile.dart';
import '../../widgets/common/gradient_badge.dart';
import '../player/player_detail_screen.dart';
import 'suggested_xi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sortBy = 'risk'; // risk | readiness | name
  String _filterBand = 'ALL'; // ALL | HIGH | MED | LOW

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<WorkspaceProvider>().activeWorkspace;
      if (ws != null) context.read<WorkspaceProvider>().loadHome(ws.id);
    });
  }

  List<PlayerModel> _filteredSquad(List<PlayerModel> squad) {
    var filtered = _filterBand == 'ALL'
        ? squad
        : squad.where((p) => p.riskBand == _filterBand).toList();

    switch (_sortBy) {
      case 'risk':
        filtered.sort((a, b) => b.riskScore.compareTo(a.riskScore));
        break;
      case 'readiness':
        filtered.sort((a, b) => a.readinessScore.compareTo(b.readinessScore));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return filtered;
  }

  Future<void> _simulateFT() async {
    HapticFeedback.mediumImpact();
    final provider = context.read<WorkspaceProvider>();
    await provider.simulateMatchFinished();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match simulation complete! Squad risk updated.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.riskLow,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    final auth = context.watch<AuthProvider>();
    final squad = _filteredSquad(workspace.squad);
    final isLoading = workspace.homeState == LoadState.loading;

    return SafeArea(
        bottom: false,
        child: Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bg,
                expandedHeight: 60,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace.activeWorkspace?.clubName ?? 'PitchPulse',
                            style: AppTextStyles.headlineLarge,
                          ),
                          Text(
                            'Coach Dashboard',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppConstants.spacingM),

                    // Upcoming Matches List
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingM),
                        child: SizedBox(
                          height: 230,
                          child: ShimmerNextMatch(),
                        ),
                      )
                    else if (workspace.upcomingFixtures.isNotEmpty)
                      SizedBox(
                        height:
                            260, // Enough height for the card with its shadows
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: workspace.upcomingFixtures.length,
                          itemBuilder: (context, index) {
                            final f = workspace.upcomingFixtures[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? AppConstants.spacingM : 0,
                                right: AppConstants.spacingM,
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.85,
                                child: NextMatchCard(
                                  fixture: f,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SuggestedXIScreen(fixture: f),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: AppConstants.spacingL),

                    // Hero: Squad Avg Readiness
                    if (!isLoading && workspace.squad.isNotEmpty)
                      _SquadReadinessHero(squad: workspace.squad),

                    if (!isLoading && workspace.squad.isNotEmpty)
                      _TopRiskPlayers(squad: workspace.squad),

                    // Dev Simulate button (visible when demo mode on)
                    if (auth.demoMode)
                      _SimulateButton(
                        loading: workspace.simulating,
                        onTap: _simulateFT,
                      ),

                    // Squad section header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Squad Risk Overview',
                                  style: AppTextStyles.headlineMedium)
                              .animate()
                              .fadeIn(duration: 400.ms),
                          _SortMenu(
                            sortBy: _sortBy,
                            onSort: (v) => setState(() => _sortBy = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter chips
                    _FilterChips(
                      selected: _filterBand,
                      squad: workspace.squad,
                      onSelect: (v) => setState(() => _filterBand = v),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Player Grid
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
                        0,
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
                                context
                                    .read<PlayerProvider>()
                                    .loadPlayerDetail(player);
                                Navigator.push(
                                  ctx,
                                  PageRouteBuilder(
                                    pageBuilder: (_, anim, __) =>
                                        PlayerDetailScreen(player: player),
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
        ));
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final List<PlayerModel> squad;
  final ValueChanged<String> onSelect;

  const _FilterChips(
      {required this.selected, required this.squad, required this.onSelect});

  int _count(String band) {
    if (band == 'ALL') return squad.length;
    return squad.where((p) => p.riskBand == band).length;
  }

  @override
  Widget build(BuildContext context) {
    final chips = ['ALL', 'HIGH', 'MED', 'LOW'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
        children: chips.map((band) {
          final isSelected = selected == band;
          Color chipColor = AppColors.textMuted;
          if (band == 'HIGH') chipColor = AppColors.riskHigh;
          if (band == 'MED') chipColor = AppColors.riskMed;
          if (band == 'LOW') chipColor = AppColors.riskLow;
          if (band == 'ALL') chipColor = AppColors.textPrimary;

          return GestureDetector(
            onTap: () => onSelect(band),
            child: AnimatedContainer(
              duration: AppConstants.animFast,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
                border: Border.all(
                  color: isSelected ? chipColor : AppColors.surfaceBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                '$band (${_count(band)})',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? chipColor : AppColors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSort;

  const _SortMenu({required this.sortBy, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSort,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort_rounded,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              sortBy == 'risk'
                  ? 'Risk'
                  : sortBy == 'readiness'
                      ? 'Readiness'
                      : 'Name',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        _menuItem('risk', 'Sort by Risk'),
        _menuItem('readiness', 'Sort by Readiness'),
        _menuItem('name', 'Sort by Name'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) => PopupMenuItem(
        value: value,
        child: Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary)),
      );
}

class _SimulateButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SimulateButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingL,
        0,
        AppConstants.spacingL,
        AppConstants.spacingL,
      ),
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: loading
                ? AppColors.surfaceElevated
                : AppColors.riskMed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: loading
                  ? AppColors.surfaceBorder
                  : AppColors.riskMed.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.riskMed, strokeWidth: 2),
                )
              else
                const Icon(Icons.play_circle_outline,
                    color: AppColors.riskMed, size: 18),
              const SizedBox(width: 10),
              Text(
                loading
                    ? 'Simulating Match Finished...'
                    : '⚡ Simulate FT Update (Demo)',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.riskMed),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _SquadReadinessHero extends StatelessWidget {
  final List<PlayerModel> squad;
  const _SquadReadinessHero({required this.squad});

  @override
  Widget build(BuildContext context) {
    if (squad.isEmpty) return const SizedBox.shrink();

    final avgReadiness =
        squad.map((e) => e.readinessScore).reduce((a, b) => a + b) /
            squad.length;
    final String band = avgReadiness >= 80
        ? 'LOW'
        : avgReadiness >= 50
            ? 'MED'
            : 'HIGH';

    // Reverse risk colors for readiness (High readiness = good = LOW risk color config)
    final color = band == 'LOW'
        ? AppColors.riskLow
        : band == 'MED'
            ? AppColors.riskMed
            : AppColors.riskHigh;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Text('Squad Avg Readiness', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppConstants.spacingL),
            SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 55,
                      startDegreeOffset: 270,
                      sections: [
                        PieChartSectionData(
                          color: color,
                          value: avgReadiness,
                          radius: 12,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: AppColors.surfaceBorder,
                          value: 100 - avgReadiness,
                          radius: 12,
                          showTitle: false,
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutBack,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${avgReadiness.toInt()}%',
                          style: AppTextStyles.displayMedium
                              .copyWith(color: color)),
                      Text('Target: >85%',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }
}

class _TopRiskPlayers extends StatelessWidget {
  final List<PlayerModel> squad;
  const _TopRiskPlayers({required this.squad});

  @override
  Widget build(BuildContext context) {
    var highRiskPlayers = squad.where((p) => p.riskBand == 'HIGH').toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    if (highRiskPlayers.isEmpty) return const SizedBox.shrink();
    final top3 = highRiskPlayers.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.spacingL,
          AppConstants.spacingL, AppConstants.spacingL, AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.riskHigh, size: 20),
              const SizedBox(width: 8),
              Text('Injury Alerts', style: AppTextStyles.headlineMedium),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          ...top3.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<PlayerProvider>().loadPlayerDetail(p);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlayerDetailScreen(player: p)),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.riskHigh.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                          color: AppColors.riskHigh.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.gradientForRisk('HIGH'),
                          ),
                          child: Center(
                            child: Text(
                              p.name.split(' ').map((w) => w[0]).take(2).join(),
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: AppTextStyles.labelMedium),
                              if (p.topDrivers.isNotEmpty)
                                Text(p.topDrivers.first,
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        RiskBadge(
                            band: 'HIGH', score: p.riskScore, pulse: true),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),
    );
  }
}
