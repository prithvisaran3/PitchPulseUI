import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fixture_model.dart';
class MatchDetailScreen extends StatelessWidget {
  final MatchReportModel report;

  const MatchDetailScreen({super.key, required this.report});

  // Demo player stats for this match
  List<Map<String, dynamic>> get _playerStats => [
        {'name': 'J. Bellingham', 'pos': 'AM', 'mins': 90, 'rating': 8.2, 'impact': 'HIGH', 'delta': '+12'},
        {'name': 'D. Carvajal', 'pos': 'RB', 'mins': 90, 'rating': 6.8, 'impact': 'HIGH', 'delta': '+18'},
        {'name': 'Vinícius Jr.', 'pos': 'LW', 'mins': 83, 'rating': 7.9, 'impact': 'LOW', 'delta': '+5'},
        {'name': 'K. Mbappé', 'pos': 'ST', 'mins': 90, 'rating': 7.4, 'impact': 'MED', 'delta': '+8'},
        {'name': 'F. Valverde', 'pos': 'CM', 'mins': 77, 'rating': 7.1, 'impact': 'MED', 'delta': '+6'},
        {'name': 'L. Modrić', 'pos': 'CM', 'mins': 65, 'rating': 6.9, 'impact': 'MED', 'delta': '+9'},
        {'name': 'A. Tchouameni', 'pos': 'CDM', 'mins': 90, 'rating': 7.0, 'impact': 'LOW', 'delta': '+3'},
        {'name': 'É. Militão', 'pos': 'CB', 'mins': 90, 'rating': 7.3, 'impact': 'MED', 'delta': '+6'},
        {'name': 'D. Alaba', 'pos': 'CB', 'mins': 90, 'rating': 7.1, 'impact': 'LOW', 'delta': '+2'},
        {'name': 'F. Mendy', 'pos': 'LB', 'mins': 90, 'rating': 6.5, 'impact': 'MED', 'delta': '+7'},
        {'name': 'T. Courtois', 'pos': 'GK', 'mins': 90, 'rating': 7.8, 'impact': 'LOW', 'delta': '+1'},
      ];

  @override
  Widget build(BuildContext context) {
    final resultColor = report.resultColor;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(report.matchDate);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            expandedHeight: 220,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.bg, resultColor.withOpacity(0.06), AppColors.bg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('vs ${report.opponent}',
                        style: AppTextStyles.displayMedium)
                        .animate().fadeIn().slideY(begin: -0.1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(report.competition, style: AppTextStyles.bodySmall),
                        const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                        Text(dateStr, style: AppTextStyles.bodySmall),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    // Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${report.goalsFor}', style: AppTextStyles.monoLarge.copyWith(
                          color: resultColor, fontSize: 36,
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('–', style: AppTextStyles.monoLarge.copyWith(color: AppColors.textMuted, fontSize: 24)),
                        ),
                        Text('${report.goalsAgainst}', style: AppTextStyles.monoLarge.copyWith(
                          color: AppColors.textSecondary, fontSize: 36,
                        )),
                      ],
                    ).animate().scale(duration: 500.ms, delay: 200.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: resultColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
                        border: Border.all(color: resultColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        report.result == 'W' ? 'VICTORY' : report.result == 'D' ? 'DRAW' : 'DEFEAT',
                        style: AppTextStyles.labelMedium.copyWith(color: resultColor),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Load impact summary
                  _SummaryCard(report: report),
                  const SizedBox(height: AppConstants.spacingL),

                  // Impact headline
                  if (report.headline != null) ...[
                    Row(children: [
                      const Icon(Icons.insights_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('Readiness Impact', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.accent)),
                    ]).animate().fadeIn(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppConstants.radiusL),
                        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                      ),
                      child: Text(report.headline!, style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary, height: 1.5,
                      )),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: AppConstants.spacingL),
                  ],

                  // Player minutes
                  Row(children: [
                    const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Player Minutes & Risk Impact', style: AppTextStyles.headlineSmall),
                  ]).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 10),

                  ..._playerStats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final stat = entry.value;
                    return _PlayerStatRow(stat: stat, index: i);
                  }),

                  const SizedBox(height: AppConstants.spacingXXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MatchReportModel report;
  const _SummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _StatBlock(label: 'Avg Load', value: '${report.avgPlayerLoad?.toInt() ?? '—'} AU', color: AppColors.accent),
          _Divider(),
          _StatBlock(label: 'Players Tracked', value: '11', color: AppColors.textSecondary),
          _Divider(),
          _StatBlock(label: 'HIGH Risk', value: '2', color: AppColors.riskHigh),
          _Divider(),
          _StatBlock(label: 'MED Risk', value: '4', color: AppColors.riskMed),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: AppTextStyles.monoMedium.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32, color: AppColors.surfaceBorder,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _PlayerStatRow extends StatelessWidget {
  final Map<String, dynamic> stat;
  final int index;
  const _PlayerStatRow({required this.stat, required this.index});

  @override
  Widget build(BuildContext context) {
    final impactColor = AppColors.colorForRisk(stat['impact'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: impactColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(stat['pos'] as String,
                style: AppTextStyles.caption.copyWith(color: impactColor))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(stat['name'] as String, style: AppTextStyles.labelMedium),
          ),
          Text('${stat['mins']}\'', style: AppTextStyles.monoSmall),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: impactColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              Icon(Icons.arrow_upward_rounded, size: 10, color: impactColor),
              const SizedBox(width: 2),
              Text(stat['delta'] as String,
                  style: AppTextStyles.caption.copyWith(color: impactColor)),
            ]),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
