import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fixture_model.dart';
import '../../providers/workspace_provider.dart';
import 'match_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<WorkspaceProvider>().activeWorkspace;
      if (ws != null) context.read<WorkspaceProvider>().loadReports(ws.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<WorkspaceProvider>().reports;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingL, AppConstants.spacingL,
                AppConstants.spacingL, AppConstants.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Match Reports', style: AppTextStyles.displayMedium)
                      .animate().fadeIn(duration: 400.ms),
                  Text('Post-match readiness & load analysis', style: AppTextStyles.bodyMedium)
                      .animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            Expanded(
              child: reports.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
                      itemCount: reports.length,
                      itemBuilder: (ctx, i) => _ReportCard(
                        report: reports[i],
                        index: i,
                        onTap: () => Navigator.push(
                          ctx,
                          PageRouteBuilder(
                            pageBuilder: (_, anim, __) => MatchDetailScreen(report: reports[i]),
                            transitionsBuilder: (_, anim, __, child) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final MatchReportModel report;
  final int index;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.index, required this.onTap});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final dateStr = DateFormat('MMM d, yyyy').format(r.matchDate);
    final resultColor = r.resultColor;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: 1.0 - _ctrl.value * 0.02, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(color: resultColor.withOpacity(0.25), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Result badge
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: resultColor.withOpacity(0.4), width: 1.5),
                    ),
                    child: Center(
                      child: Text(r.result,
                          style: AppTextStyles.headlineMedium.copyWith(color: resultColor)),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('vs ${r.opponent}', style: AppTextStyles.headlineMedium),
                        Text('$dateStr · ${r.competition}', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),

                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Text(
                      '${r.goalsFor} – ${r.goalsAgainst}',
                      style: AppTextStyles.monoMedium,
                    ),
                  ),
                ],
              ),

              if (r.headline != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.insights_rounded, size: 13, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(r.headline!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],

              if (r.avgPlayerLoad != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  _StatPill(label: 'Avg Load', value: '${r.avgPlayerLoad!.toInt()} AU', color: AppColors.accent),
                ]),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(width: 6),
          Text(value, style: AppTextStyles.monoSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
