import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/player_model.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/gradient_badge.dart';
import '../../widgets/common/pulse_loader.dart';
import '../../widgets/common/shimmer_loader.dart';

class PlayerDetailScreen extends StatefulWidget {
  final PlayerModel player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _gaugeCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _gaugeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<PlayerProvider>();
      if (pp.currentDetail == null ||
          pp.currentDetail!.player.id != widget.player.id) {
        pp.loadPlayerDetail(widget.player);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gaugeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PlayerProvider>();
    final detail = pp.currentDetail;
    final isLoading = pp.detailState == PlayerLoadState.loading;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _PlayerHeader(
                player: widget.player,
                gaugeCtrl: _gaugeCtrl,
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: isLoading
                  ? _LoadingPlaceholder()
                  : detail != null
                      ? _PlayerContent(detail: detail, player: widget.player)
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Player Header ─────────────────────────────────────────────────────────────
class _PlayerHeader extends StatelessWidget {
  final PlayerModel player;
  final AnimationController gaugeCtrl;

  const _PlayerHeader({required this.player, required this.gaugeCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bg,
            AppColors.colorForRisk(player.riskBand).withValues(alpha: 0.08),
            AppColors.bg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar + jersey
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientForRisk(player.riskBand),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.colorForRisk(player.riskBand)
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    player.name.split(' ').map((w) => w[0]).take(2).join(),
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (player.jerseyNumber != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.colorForRisk(player.riskBand),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${player.jerseyNumber}',
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(width: 20),

          // Name + position + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(player.name, style: AppTextStyles.displaySmall)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideX(begin: 0.1),
                const SizedBox(height: 4),
                Row(children: [
                  Text(player.position, style: AppTextStyles.bodySmall),
                  if (player.nationality != null) ...[
                    const SizedBox(width: 8),
                    Text('· ${player.nationality}',
                        style: AppTextStyles.bodySmall),
                  ],
                ]).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ReadinessBadge(score: player.readinessScore),
                    RiskBadge(
                        band: player.riskBand,
                        score: player.riskScore,
                        pulse: player.riskBand == 'HIGH'),
                  ],
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),

          // Gauge
          _ReadinessGauge(
            score: player.readinessScore,
            controller: gaugeCtrl,
          )
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(duration: 500.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

class _ReadinessGauge extends StatelessWidget {
  final double score;
  final AnimationController controller;

  const _ReadinessGauge({required this.score, required this.controller});

  Color _getColor(double v) {
    if (v >= 80) return AppColors.readinessGreen;
    if (v >= 50) return AppColors.readinessAmber;
    return AppColors.readinessPink;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final animated = score * controller.value;
        final color = _getColor(score);
        return SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: PulseLoader(color: color, size: 60),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${animated.toInt()}%',
                    style: AppTextStyles.monoMedium.copyWith(
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Content Sections ──────────────────────────────────────────────────────────

class _PlayerContent extends StatelessWidget {
  final PlayerDetailModel detail;
  final PlayerModel player;

  const _PlayerContent({required this.detail, required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts & Why Flagged Group
        _SectionHeader(
            title: 'Risk Trend & Drivers', icon: Icons.show_chart_rounded),
        const SizedBox(height: 10),
        _RiskChart(data: detail.weeklyLoad),
        const SizedBox(height: AppConstants.spacingM),
        _WhyFlaggedCard(drivers: detail.riskDrivers),

        const SizedBox(height: AppConstants.spacingL),

        _SectionHeader(
            title: 'Load: Acute vs Chronic', icon: Icons.bar_chart_rounded),
        const SizedBox(height: 10),
        _LoadChart(data: detail.weeklyLoad),

        const SizedBox(height: AppConstants.spacingL),

        // Similar cases
        _SectionHeader(
            title: 'Similar Cases (Vector Search)',
            icon: Icons.manage_search_rounded,
            color: AppColors.textPrimary),
        const SizedBox(height: 4),
        Text('Powered by Actian VectorAI DB · RAG retrieval',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        _SimilarCasesSection(player: player),

        const SizedBox(height: AppConstants.spacingL),

        // Action plan
        _SectionHeader(
            title: 'Coach Action Plan',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.riskLow),
        const SizedBox(height: 4),
        Text('Generated by Gemini · Evidence-backed',
            style: AppTextStyles.caption.copyWith(color: AppColors.riskLow)),
        const SizedBox(height: 10),
        _ActionPlanSection(player: player),

        const SizedBox(height: AppConstants.spacingXXL),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader(
      {required this.title,
      required this.icon,
      this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headlineSmall.copyWith(color: color)),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }
}

// ── Risk Chart ────────────────────────────────────────────────────────────────
class _RiskChart extends StatelessWidget {
  final List<WeeklyLoadPoint> data;
  const _RiskChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.riskScore))
        .toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.chartGrid, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) =>
                    Text(v.toInt().toString(), style: AppTextStyles.caption),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i >= 0 && i < data.length) {
                    return Text(data[i].weekLabel,
                        style: AppTextStyles.caption);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0, maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.colorForRisk('LOW'),
                  AppColors.colorForRisk('HIGH')
                ],
              ),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.colorForRisk(
                    spot.y >= 66
                        ? 'HIGH'
                        : spot.y >= 36
                            ? 'MED'
                            : 'LOW',
                  ),
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.chartLine1.withValues(alpha: 0.2),
                    AppColors.chartLine1.withValues(alpha: 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          // Risk band lines
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                  y: 36,
                  color: AppColors.riskMed.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [4, 4]),
              HorizontalLine(
                  y: 66,
                  color: AppColors.riskHigh.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [4, 4]),
            ],
          ),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }
}

// ── Load Chart ────────────────────────────────────────────────────────────────
class _LoadChart extends StatelessWidget {
  final List<WeeklyLoadPoint> data;
  const _LoadChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final acuteSpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.acuteLoad))
        .toList();
    final chronicSpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.chronicLoad))
        .toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _LegendDot(color: AppColors.chartLine1, label: 'Acute'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.chartLine2, label: 'Chronic'),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.chartGrid, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                          style: AppTextStyles.caption),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= 0 && i < data.length)
                          return Text(data[i].weekLabel,
                              style: AppTextStyles.caption);
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: acuteSpots,
                    isCurved: true,
                    color: AppColors.chartLine1,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.chartLine1.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: chronicSpots,
                    isCurved: true,
                    color: AppColors.chartLine2,
                    barWidth: 2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Why Flagged ───────────────────────────────────────────────────────────────
class _WhyFlaggedCard extends StatelessWidget {
  final List<RiskDriver> drivers;
  const _WhyFlaggedCard({required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: drivers.asMap().entries.map((entry) {
          final i = entry.key;
          final driver = entry.value;
          final color = AppColors.colorForRisk(driver.severity);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: i < drivers.length - 1
                  ? const Border(
                      bottom: BorderSide(color: AppColors.surfaceBorder))
                  : null,
            ),
            child: Row(
              children: [
                // Rank pill
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.label, style: AppTextStyles.labelMedium),
                      const SizedBox(height: 2),
                      Text(driver.value,
                          style:
                              AppTextStyles.monoSmall.copyWith(color: color)),
                      Text(driver.threshold, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                // Trend arrow
                Icon(
                  driver.trend == 'UP'
                      ? Icons.trending_up_rounded
                      : driver.trend == 'DOWN'
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                  color: driver.trend == 'UP'
                      ? AppColors.riskHigh
                      : driver.trend == 'DOWN'
                          ? AppColors.riskLow
                          : AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

// ── Similar Cases ─────────────────────────────────────────────────────────────
class _SimilarCasesSection extends StatefulWidget {
  final PlayerModel player;
  const _SimilarCasesSection({required this.player});

  @override
  State<_SimilarCasesSection> createState() => _SimilarCasesSectionState();
}

class _SimilarCasesSectionState extends State<_SimilarCasesSection> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PlayerProvider>();

    if (!_loaded) {
      return GestureDetector(
        onTap: () {
          setState(() => _loaded = true);
          context.read<PlayerProvider>().loadSimilarCases(widget.player.id);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border:
                Border.all(color: AppColors.textPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.manage_search_rounded,
                  color: AppColors.textPrimary, size: 18),
              const SizedBox(width: 10),
              Text('Find Similar Cases',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
    }

    if (pp.similarState == PlayerLoadState.loading) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
                width: 20,
                height: 20,
                child: PulseLoader(color: AppColors.textPrimary, size: 20)),
            const SizedBox(width: 10),
            Text('Searching vector database...',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ]),
        ],
      );
    }

    if (pp.similarState == PlayerLoadState.error) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text('Failed to search Vector AI database.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      ).animate().fadeIn();
    }

    final cases = pp.currentSimilar ?? [];
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = cases[i];
          final simPct = (c.similarityScore * 100).toInt();

          return Container(
            width: 280,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.playerName, style: AppTextStyles.labelMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusCircle),
                      ),
                      child: Text('$simPct% match',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c.weekLabel, style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(c.summary,
                      style: AppTextStyles.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.riskLow.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.riskLow.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.riskLow, size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(c.outcome,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.riskLow),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: i * 100))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

// ── Action Plan ───────────────────────────────────────────────────────────────
class _ActionPlanSection extends StatefulWidget {
  final PlayerModel player;
  const _ActionPlanSection({required this.player});

  @override
  State<_ActionPlanSection> createState() => _ActionPlanSectionState();
}

class _ActionPlanSectionState extends State<_ActionPlanSection> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PlayerProvider>();

    if (pp.planState == PlayerLoadState.idle && !_generating) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() => _generating = true);
          context.read<PlayerProvider>().generateActionPlan(widget.player);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.riskLow.withValues(alpha: 0.1),
                AppColors.accent.withValues(alpha: 0.1)
              ],
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(color: AppColors.riskLow.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.riskLow, size: 18),
              const SizedBox(width: 10),
              Text('Generate Coach Action Plan',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.riskLow)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.riskLow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Gemini + RAG',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.riskLow)),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
    }

    if (pp.planState == PlayerLoadState.loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            PulseLoader(color: AppColors.riskLow),
            const SizedBox(height: 14),
            Text('Generating plan with Gemini...',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.riskLow)),
            const SizedBox(height: 4),
            Text('Retrieving similar cases from VectorAI DB...',
                style: AppTextStyles.caption),
          ],
        ),
      );
    }

    if (pp.planState == PlayerLoadState.error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.riskHigh.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.riskHigh, size: 28),
            const SizedBox(height: 12),
            Text('Action Plan Unavailable',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.riskHigh)),
            const SizedBox(height: 4),
            Text(pp.error ?? 'The Gemini backend returned an error.',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ).animate().fadeIn();
    }

    final plan = pp.currentPlan;
    if (plan == null) return const SizedBox.shrink();

    return _ActionPlanCard(plan: plan);
  }
}

class _ActionPlanCard extends StatelessWidget {
  final ActionPlan plan;
  const _ActionPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.riskLow.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.riskLow.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.riskLow.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusL)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.riskLow, size: 16),
                const SizedBox(width: 8),
                Text('Coach Action Plan',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.riskLow)),
                const Spacer(),
                Text('Gemini + RAG',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.riskLow)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Text(plan.summary,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary, height: 1.6)),

                const SizedBox(height: 16),

                // Why
                _PlanSection(
                  label: 'Why',
                  icon: Icons.psychology_outlined,
                  color: AppColors.riskMed,
                  items: plan.why,
                ),

                const SizedBox(height: 14),

                // Recommendations
                _PlanSection(
                  label: 'Recommendations',
                  icon: Icons.tips_and_updates_outlined,
                  color: AppColors.riskLow,
                  items: plan.recommendations,
                ),

                const SizedBox(height: 14),

                // Caution
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.riskHigh.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.riskHigh.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.riskHigh, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(plan.caution,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.riskMed)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _PlanSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _PlanSection(
      {required this.label,
      required this.icon,
      required this.color,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: color, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(item,
                        style: AppTextStyles.bodySmall.copyWith(height: 1.5))),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerBox(width: double.infinity, height: 160, radius: 16),
        const SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 160, radius: 16),
        const SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 120, radius: 16),
      ],
    );
  }
}
